import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'utils/geofencing_utils.dart';
import 'services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  String _attendanceStatus = 'Checked Out';
  Map<String, dynamic>? _currentAttendance;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _facility;
  double? _distanceToFacility;

  // Constants for validation
  static const double FACILITY_RADIUS_METERS = 100.0; // 100 meters

  @override
  void initState() {
    super.initState();
    _startClock();
    _initializeScreen();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  Future<void> _initializeScreen() async {
    await _loadUserProfile();
    await _loadFacilityInfo();
    await _checkCurrentAttendanceStatus();
    await _getCurrentLocation();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('user_profiles')
            .select('*')
            .eq('id', user.id)
            .single();
        setState(() {
          _userProfile = response;
        });
      }
    } catch (e) {
      _showError('Failed to load user profile: $e');
    }
  }

  Future<void> _loadFacilityInfo() async {
    try {
      if (_userProfile?['facility_id'] != null) {
        final response = await Supabase.instance.client
            .from('facilities')
            .select('*, councils(name, regions(name))')
            .eq('id', _userProfile!['facility_id'])
            .single();
        setState(() {
          _facility = response;
        });
      }
    } catch (e) {
      _showError('Failed to load facility info: $e');
    }
  }

  Future<void> _checkCurrentAttendanceStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Check for any active attendance (checked in but not checked out)
        final response = await Supabase.instance.client
            .from('attendance')
            .select('*')
            .eq('user_id', user.id)
            .eq('status', 'checked_in')
            .order('check_in_time', ascending: false)
            .limit(1);

        if (response.isNotEmpty) {
          setState(() {
            _currentAttendance = response.first;
            _attendanceStatus = 'Checked In';
          });
        } else {
          setState(() {
            _currentAttendance = null;
            _attendanceStatus = 'Checked Out';
          });
        }
      }
    } catch (e) {
      _showError('Failed to check attendance status: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Calculate distance to facility if facility coordinates are available
      if (_facility != null &&
          _facility!['latitude'] != null &&
          _facility!['longitude'] != null &&
          _facility!['latitude'] != 0 &&
          _facility!['longitude'] != 0) {
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _facility!['latitude'].toDouble(),
          _facility!['longitude'].toDouble(),
        );

        setState(() {
          _distanceToFacility = distance;
        });
      } else {
        setState(() {
          _distanceToFacility = null;
        });
        if (_facility != null) {
          _showError(
              'Facility coordinates not set. Distance validation disabled.');
        }
      }
    } catch (e) {
      _showError('Failed to get location: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _checkIn() async {
    if (_currentPosition == null) {
      _showError('Location not available. Please try again.');
      return;
    }

    // Validate distance to facility (only if facility coordinates are available)
    if (_distanceToFacility != null &&
        _distanceToFacility! > FACILITY_RADIUS_METERS) {
      _showError(
          'You are too far from the facility (${_distanceToFacility!.toStringAsFixed(0)}m). Please get closer to check in.');
      return;
    }

    if (_facility != null &&
        (_facility!['latitude'] == null ||
            _facility!['longitude'] == null ||
            _facility!['latitude'] == 0 ||
            _facility!['longitude'] == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Warning: Facility coordinates not set. Location validation is disabled.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isCheckingIn = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('attendance').insert({
          'user_id': user.id,
          'facility_id': _userProfile!['facility_id'],
          'check_in_time': DateTime.now().toIso8601String(),
          'check_in_latitude': _currentPosition!.latitude,
          'check_in_longitude': _currentPosition!.longitude,
          'status': 'checked_in',
        });

        await _checkCurrentAttendanceStatus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully checked in!'),
            backgroundColor: AppColors.deloitteGreen,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to check in: $e');
    } finally {
      setState(() {
        _isCheckingIn = false;
      });
    }
  }

  Future<void> _checkOut() async {
    if (_currentPosition == null) {
      _showError('Location not available. Please try again.');
      return;
    }

    if (_currentAttendance == null) {
      _showError('No active check-in found.');
      return;
    }

    // Validate distance to facility (only if facility coordinates are available)
    if (_distanceToFacility != null &&
        _distanceToFacility! > FACILITY_RADIUS_METERS) {
      _showError(
          'You are too far from the facility (${_distanceToFacility!.toStringAsFixed(0)}m). Please get closer to check out.');
      return;
    }

    if (_facility != null &&
        (_facility!['latitude'] == null ||
            _facility!['longitude'] == null ||
            _facility!['latitude'] == 0 ||
            _facility!['longitude'] == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Warning: Facility coordinates not set. Location validation is disabled.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isCheckingOut = true;
    });

    try {
      final checkInTime = DateTime.parse(_currentAttendance!['check_in_time']);
      final checkOutTime = DateTime.now();
      final hoursWorked = checkOutTime.difference(checkInTime).inMinutes / 60.0;

      await Supabase.instance.client.from('attendance').update({
        'check_out_time': checkOutTime.toIso8601String(),
        'check_out_latitude': _currentPosition!.latitude,
        'check_out_longitude': _currentPosition!.longitude,
        'hours_worked': hoursWorked,
        'status': 'completed',
      }).eq('id', _currentAttendance!['id']);

      await _checkCurrentAttendanceStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully checked out! Hours worked: ${hoursWorked.toStringAsFixed(2)}'),
          backgroundColor: AppColors.deloitteGreen,
        ),
      );
    } catch (e) {
      _showError('Failed to check out: $e');
    } finally {
      setState(() {
        _isCheckingOut = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  String _calculateCurrentHours() {
    if (_currentAttendance == null) return '0.00';
    try {
      final checkInTime = DateTime.parse(_currentAttendance!['check_in_time']);
      final now = DateTime.now();
      final hours = now.difference(checkInTime).inMinutes / 60.0;
      return hours >= 0 ? hours.toStringAsFixed(2) : '0.00';
    } catch (e) {
      return '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final isWide = media.size.width > 700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('WoTi Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initializeScreen,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity,
              ),
              child: Column(
                children: [
                  // Real-time clock and date
                  Card(
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_currentTime),
                            style: TextStyle(
                              color: AppColors.deloitteGreen,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(_currentTime),
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color ??
                                  Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status card
                  _StatusCard(
                    attendanceStatus: _attendanceStatus,
                    currentAttendance: _currentAttendance,
                    calculateCurrentHours: _calculateCurrentHours,
                  ),
                  const SizedBox(height: 16),

                  // Location card
                  _LocationCard(
                    currentPosition: _currentPosition,
                    isLoadingLocation: _isLoadingLocation,
                    getCurrentLocation: _getCurrentLocation,
                    distanceToFacility: _distanceToFacility,
                    facility: _facility,
                  ),
                  const SizedBox(height: 16),

                  // Facility card
                  _FacilityCard(facility: _facility),
                  const SizedBox(height: 24),

                  // Check-in/Check-out buttons
                  if (_attendanceStatus == 'Checked Out') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (_currentPosition != null && !_isCheckingIn)
                            ? _checkIn
                            : null,
                        icon: _isCheckingIn
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          _isCheckingIn ? 'Checking In...' : 'Check In',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (_currentPosition != null && !_isCheckingOut)
                            ? _checkOut
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        icon: _isCheckingOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : const Icon(Icons.logout),
                        label: Text(
                          _isCheckingOut ? 'Checking Out...' : 'Check Out',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Additional info
                  if (_currentPosition == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location is required for check-in/out. Please enable location services.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Stateless Widgets for modularity and clarity ---

class _StatusCard extends StatelessWidget {
  final String attendanceStatus;
  final Map<String, dynamic>? currentAttendance;
  final String Function() calculateCurrentHours;

  const _StatusCard({
    required this.attendanceStatus,
    required this.currentAttendance,
    required this.calculateCurrentHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCheckedIn = attendanceStatus == 'Checked In';

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isCheckedIn ? AppColors.deloitteGreen : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    attendanceStatus,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isCheckedIn && currentAttendance != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checked in at:',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                  Text(
                    DateFormat('HH:mm').format(
                      DateTime.parse(currentAttendance!['check_in_time']),
                    ),
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hours worked:',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                  Text(
                    calculateCurrentHours(),
                    style: const TextStyle(
                      color: AppColors.deloitteGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Position? currentPosition;
  final bool isLoadingLocation;
  final VoidCallback getCurrentLocation;
  final double? distanceToFacility;
  final Map<String, dynamic>? facility;

  const _LocationCard({
    required this.currentPosition,
    required this.isLoadingLocation,
    required this.getCurrentLocation,
    required this.distanceToFacility,
    required this.facility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.deloitteGreen),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLoadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.deloitteGreen),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: AppColors.deloitteGreen),
                    onPressed: getCurrentLocation,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (currentPosition != null) ...[
              Text(
                'Latitude: ${currentPosition!.latitude.toStringAsFixed(6)}',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              Text(
                'Longitude: ${currentPosition!.longitude.toStringAsFixed(6)}',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              if (distanceToFacility != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      distanceToFacility! <=
                              _AttendanceScreenState.FACILITY_RADIUS_METERS
                          ? Icons.check_circle
                          : Icons.warning,
                      color: distanceToFacility! <=
                              _AttendanceScreenState.FACILITY_RADIUS_METERS
                          ? AppColors.deloitteGreen
                          : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Distance to facility: ${distanceToFacility!.toStringAsFixed(0)}m',
                      style: TextStyle(
                        color: distanceToFacility! <=
                                _AttendanceScreenState.FACILITY_RADIUS_METERS
                            ? AppColors.deloitteGreen
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ] else if (facility != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Facility coordinates not set - location validation disabled',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else
              const Text(
                'Location not available',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Map<String, dynamic>? facility;
  const _FacilityCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (facility == null) return const SizedBox.shrink();

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: AppColors.deloitteGreen),
                const SizedBox(width: 8),
                Text(
                  'Facility',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              facility!['name'] ?? 'Unknown Facility',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (facility!['councils'] != null) ...[
              const SizedBox(height: 4),
              Text(
                facility!['councils']['name'] ?? '',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              if (facility!['councils']['regions'] != null)
                Text(
                  facility!['councils']['regions']['name'] ?? '',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
