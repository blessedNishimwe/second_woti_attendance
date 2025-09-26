import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';

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
  static const double FACILITY_RADIUS_METERS = 100.0; // 100 meters radius

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
        // Check for any active attendance (checked in but not checked out)
        final response = await Supabase.instance.client
            .from('attendance')
            .select('*')
            .eq('user_id', user.id)
            .is_('check_out_time', null)
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
        // If facility coordinates are not set, show warning
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



  Future<void> _checkIn() async {
    if (_currentPosition == null) {
      _showError('Location not available. Please try again.');
      return;
    }

    // Validate distance to facility (only if facility coordinates are available)
    if (_distanceToFacility != null && _distanceToFacility! > FACILITY_RADIUS_METERS) {
      _showError('You are too far from the facility (${_distanceToFacility!.toStringAsFixed(0)}m). Please get closer to check in.');
      return;
    }

    // If facility coordinates are not set, show a warning but allow check-in
    if (_facility != null && 
        (_facility!['latitude'] == null || 
         _facility!['longitude'] == null || 
         _facility!['latitude'] == 0 || 
         _facility!['longitude'] == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: Facility coordinates not set. Location validation is disabled.'),
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
          SnackBar(
            content: Text('Successfully checked in!'),
            backgroundColor: kDeloitteGreen,
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
    if (_distanceToFacility != null && _distanceToFacility! > FACILITY_RADIUS_METERS) {
      _showError('You are too far from the facility (${_distanceToFacility!.toStringAsFixed(0)}m). Please get closer to check out.');
      return;
    }

    // If facility coordinates are not set, show a warning but allow check-out
    if (_facility != null && 
        (_facility!['latitude'] == null || 
         _facility!['longitude'] == null || 
         _facility!['latitude'] == 0 || 
         _facility!['longitude'] == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: Facility coordinates not set. Location validation is disabled.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isCheckingOut = true;
    });

    try {
      // Calculate hours worked
      final checkInTime = DateTime.parse(_currentAttendance!['check_in_time']);
      final checkOutTime = DateTime.now();
      final hoursWorked = checkOutTime.difference(checkInTime).inMinutes / 60.0;

      await Supabase.instance.client
          .from('attendance')
          .update({
            'check_out_time': checkOutTime.toIso8601String(),
            'check_out_latitude': _currentPosition!.latitude,
            'check_out_longitude': _currentPosition!.longitude,
            'hours_worked': hoursWorked,
            'status': 'completed',
          })
          .eq('id', _currentAttendance!['id']);

      await _checkCurrentAttendanceStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully checked out! Hours worked: ${hoursWorked.toStringAsFixed(2)}'),
          backgroundColor: kDeloitteGreen,
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

  Widget _buildStatusCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _attendanceStatus == 'Checked In' 
                        ? kDeloitteGreen 
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
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    DateFormat('HH:mm').format(
                      DateTime.parse(_currentAttendance!['check_in_time']),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
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
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    _calculateCurrentHours(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: kDeloitteGreen,
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

  Widget _buildLocationCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: kDeloitteGreen),
                SizedBox(width: 8),
                Text(
                  'Location',
                  style: theme.textTheme.bodyMedium?.copyWith(
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
                      valueColor: AlwaysStoppedAnimation<Color>(kDeloitteGreen),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, color: kDeloitteGreen),
                    onPressed: _getCurrentLocation,
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (_currentPosition != null) ...[
              Text(
                'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                style: theme.textTheme.bodySmall,
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
                          ? kDeloitteGreen
                          : Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Distance to facility: ${_distanceToFacility!.toStringAsFixed(0)}m',
                      style: TextStyle(
                        color: _distanceToFacility! <= FACILITY_RADIUS_METERS
                            ? kDeloitteGreen
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
    if (_facility == null) {
      return SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: kDeloitteGreen),
                SizedBox(width: 8),
                Text(
                  'Facility',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              _facility!['name'] ?? 'Unknown Facility',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_facility!['councils'] != null) ...[
              SizedBox(height: 4),
              Text(
                _facility!['councils']['name'] ?? '',
                style: theme.textTheme.bodySmall,
              ),
              if (_facility!['councils']['regions'] != null)
                Text(
                  _facility!['councils']['regions']['name'] ?? '',
                  style: theme.textTheme.bodySmall,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

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
      body: RefreshIndicator(
        onRefresh: _initializeScreen,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWideScreen ? 800 : double.infinity,
              ),
              child: Column(
                children: [
                  // Real-time clock and date
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isWideScreen ? 24 : 20),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_currentTime),
                            style: TextStyle(
                              color: kDeloitteGreen,
                              fontSize: isWideScreen ? 42 : 36,
                              fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatDate(_currentTime),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Status card
                  _buildStatusCard(),
                  SizedBox(height: 16),

                  // Location card
                  _buildLocationCard(),
                  SizedBox(height: 16),

                  // Facility card
                  _buildFacilityCard(),
                  SizedBox(height: 24),

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
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.black,
                                  ),
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
                      foregroundColor: Colors.white,
                    ),
                    icon: _isCheckingOut
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              
              // Additional info
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
    );
  }
}