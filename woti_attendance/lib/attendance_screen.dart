import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'utils/geofencing_utils.dart'; // <--- NEW IMPORT

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

  static const double FACILITY_RADIUS_METERS = 100.0;
  final TextEditingController _activityController = TextEditingController(); // <--- NEW CONTROLLER

  @override
  void initState() {
    super.initState();
    _startClock();
    _initializeScreen();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _activityController.dispose(); // Dispose controller
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
        final response = await Supabase.instance.client
            .from('attendance')
            .select('*')
            .eq('user_id', user.id)
            .filter('check_out_time', 'is', null)
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      if (_facility != null &&
          _facility!['latitude'] != null &&
          _facility!['longitude'] != null &&
          _facility!['latitude'] != 0 &&
          _facility!['longitude'] != 0) {
        // Use geofencing utility for distance calculation
        double distance = GeofencingUtils.calculateDistanceMeters(
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
          _showError('Facility coordinates not set. Distance validation disabled.');
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

  // --- Supabase Check-In Logic ---
  Future<void> _checkIn() async {
    if (_currentPosition == null) {
      _showError('Location not available. Please try again.');
      return;
    }
    if (_distanceToFacility != null && _distanceToFacility! > FACILITY_RADIUS_METERS) {
      _showError('You are too far from the facility (${_distanceToFacility!.toStringAsFixed(0)}m). Please get closer to check in.');
      return;
    }
    setState(() {
      _isCheckingIn = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final now = DateTime.now();
      if (user != null) {
        await Supabase.instance.client.from('attendance').insert({
          'user_id': user.id,
          'facility_id': _userProfile!['facility_id'],
          'check_in_time': now.toIso8601String(),
          'check_in_latitude': _currentPosition!.latitude,
          'check_in_longitude': _currentPosition!.longitude,
          'day_of_week': DateFormat('EEEE').format(now),
          'date': DateFormat('yyyy-MM-dd').format(now),
          'activity_description': '', // blank at check-in
          'status': 'checked_in',
        });

        await _checkCurrentAttendanceStatus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully checked in!'),
            backgroundColor: Theme.of(context).primaryColor,
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

  // --- Supabase Check-Out Logic ---
  Future<void> _checkOut() async {
    if (_currentPosition == null) {
      _showError('Location not available. Please try again.');
      return;
    }
    if (_currentAttendance == null) {
      _showError('No active check-in found.');
      return;
    }
    if (_distanceToFacility != null && _distanceToFacility! > FACILITY_RADIUS_METERS) {
      _showError('You are too far from the facility (${_distanceToFacility!.toStringAsFixed(0)}m). Please get closer to check out.');
      return;
    }
    setState(() {
      _isCheckingOut = true;
    });

    try {
      final checkInTime = DateTime.parse(_currentAttendance!['check_in_time']);
      final checkOutTime = DateTime.now();
      final hoursWorked = checkOutTime.difference(checkInTime).inMinutes / 60.0;

      await Supabase.instance.client
          .from('attendance')
          .update({
            'check_out_time': checkOutTime.toIso8601String(),
            'check_out_latitude': _currentPosition!.latitude,
            'check_out_longitude': _currentPosition!.longitude,
            'activity_description': _activityController.text,
            'total_hours_worked': hoursWorked.toStringAsFixed(2),
            'status': 'checked_out',
          })
          .eq('id', _currentAttendance!['id']);

      await _checkCurrentAttendanceStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully checked out! Hours worked: ${hoursWorked.toStringAsFixed(2)}'),
          backgroundColor: Theme.of(context).primaryColor,
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

  String _formatTime(DateTime time) => DateFormat('HH:mm:ss').format(time);
  String _formatDate(DateTime date) => DateFormat('EEEE, MMMM d, yyyy').format(date);

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

  Widget _buildStatusCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _attendanceStatus == 'Checked In'
                        ? theme.primaryColor
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _attendanceStatus,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_currentAttendance != null && _attendanceStatus == 'Checked In') ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checked in at:',
                    style: TextStyle(color: theme.hintColor),
                  ),
                  Text(
                    DateFormat('HH:mm').format(
                      DateTime.parse(_currentAttendance!['check_in_time']),
                    ),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hours worked:',
                    style: TextStyle(color: theme.hintColor),
                  ),
                  Text(
                    _calculateCurrentHours(),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // <--- NEW: Activity Description Field, show only when checked in
              SizedBox(height: 16),
              TextField(
                controller: _activityController,
                decoration: InputDecoration(
                  labelText: 'Description of activities',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Location',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if (_isLoadingLocation)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, color: theme.primaryColor),
                    onPressed: _getCurrentLocation,
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (_currentPosition != null) ...[
              Text(
                'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                style: TextStyle(color: theme.hintColor),
              ),
              Text(
                'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                style: TextStyle(color: theme.hintColor),
              ),
              if (_distanceToFacility != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _distanceToFacility! <= FACILITY_RADIUS_METERS
                          ? Icons.check_circle
                          : Icons.warning,
                      color: _distanceToFacility! <= FACILITY_RADIUS_METERS
                          ? theme.primaryColor
                          : Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Distance to facility: ${_distanceToFacility!.toStringAsFixed(0)}m',
                      style: TextStyle(
                        color: _distanceToFacility! <= FACILITY_RADIUS_METERS
                            ? theme.primaryColor
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ] else if (_facility != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Facility coordinates not set - location validation disabled',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else
              Text(
                'Location not available',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityCard() {
    final theme = Theme.of(context);
    if (_facility == null) {
      return SizedBox.shrink();
    }

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: theme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Facility',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              _facility!['name'] ?? 'Unknown Facility',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_facility!['councils'] != null) ...[
              SizedBox(height: 4),
              Text(
                _facility!['councils']['name'] ?? '',
                style: TextStyle(color: theme.hintColor),
              ),
              if (_facility!['councils']['regions'] != null)
                Text(
                  _facility!['councils']['regions']['name'] ?? '',
                  style: TextStyle(color: theme.hintColor),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('WoTi Attendance'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  color: theme.cardColor,
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          _formatTime(_currentTime),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatDate(_currentTime),
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildStatusCard(),
                SizedBox(height: 16),
                _buildLocationCard(),
                SizedBox(height: 16),
                _buildFacilityCard(),
                SizedBox(height: 24),
                if (_attendanceStatus == 'Checked Out') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: (_currentPosition != null && !_isCheckingIn)
                          ? _checkIn
                          : null,
                      icon: _isCheckingIn
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : Icon(Icons.login),
                      label: Text(
                        _isCheckingIn ? 'Checking In...' : 'Check In',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : Icon(Icons.logout),
                      label: Text(
                        _isCheckingOut ? 'Checking Out...' : 'Check Out',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 16),
                if (_currentPosition == null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
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
    );
  }
}