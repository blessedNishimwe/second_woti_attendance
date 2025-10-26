import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';
import '../models/location_model.dart';
import '../repositories/attendance_repository.dart';
import '../exceptions/app_exceptions.dart';

/// Attendance state management using Provider
class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;
  
  AttendanceModel? _currentAttendance;
  LocationModel? _currentLocation;
  bool _isLoading = false;
  String? _error;
  bool _isLocationPermissionGranted = false;
  double? _distanceToFacility;
  bool _isWithinGeofence = false;

  AttendanceProvider(this._attendanceRepository);

  // Getters
  AttendanceModel? get currentAttendance => _currentAttendance;
  LocationModel? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  double? get distanceToFacility => _distanceToFacility;
  bool get isWithinGeofence => _isWithinGeofence;
  bool get isCheckedIn => _currentAttendance?.isCheckedIn ?? false;
  bool get isCheckedOut => _currentAttendance?.isCheckedOut ?? false;

  Future<void> initialize() async {
    await _checkLocationPermission();
    await _loadCurrentAttendanceStatus();
    if (_isLocationPermissionGranted) {
      await _getCurrentLocation();
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      _isLocationPermissionGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      notifyListeners();
    } catch (e) {
      _setError('Failed to check location permission: ${e.toString()}');
    }
  }

  Future<void> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException('Location permission denied');
      } else if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedException('Location permission permanently denied');
      }
      
      _isLocationPermissionGranted = true;
      await _getCurrentLocation();
      notifyListeners();
    } catch (e) {
      if (e is LocationPermissionDeniedException) {
        _setError(e.message);
      } else {
        _setError('Failed to request location permission: ${e.toString()}');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_isLocationPermissionGranted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now(),
      );

      // Calculate distance to facility (if facility coordinates are available)
      await _calculateDistanceToFacility();
      
      notifyListeners();
    } on LocationServiceDisabledException {
      _setError('Location services are disabled. Please enable them in settings.');
    } on TimeoutException {
      _setError('Location request timed out. Please try again.');
    } catch (e) {
      _setError('Failed to get current location: ${e.toString()}');
    }
  }

  Future<void> _calculateDistanceToFacility() async {
    if (_currentLocation == null) return;

    // TODO: Get facility coordinates from user profile or settings
    // For now, using a default facility location
    const facilityLatitude = 40.7128; // Example coordinates
    const facilityLongitude = -74.0060;
    const facilityRadiusMeters = 100.0;

    try {
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        facilityLatitude,
        facilityLongitude,
      );

      _distanceToFacility = distance;
      _isWithinGeofence = distance <= facilityRadiusMeters;
      notifyListeners();
    } catch (e) {
      _setError('Failed to calculate distance to facility: ${e.toString()}');
    }
  }

  Future<void> _loadCurrentAttendanceStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _currentAttendance = await _attendanceRepository.getCurrentAttendanceStatus(user.id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load attendance status: ${e.toString()}');
    }
  }

  Future<bool> checkIn({
    String? photoUrl,
    String? activityDescription,
  }) async {
    if (_currentLocation == null) {
      _setError('Location not available. Please enable location services.');
      return false;
    }

    if (!_isWithinGeofence) {
      _setError('You must be within 100 meters of the facility to check in.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      _currentAttendance = await _attendanceRepository.checkIn(
        userId: user.id,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        photoUrl: photoUrl,
        activityDescription: activityDescription,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      if (e is GeofenceViolationException) {
        _setError(e.message);
      } else {
        _setError('Failed to check in: ${e.toString()}');
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> checkOut({
    String? photoUrl,
    String? activityDescription,
  }) async {
    if (_currentAttendance == null) {
      _setError('No active check-in found');
      return false;
    }

    if (_currentLocation == null) {
      _setError('Location not available. Please enable location services.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _currentAttendance = await _attendanceRepository.checkOut(
        attendanceId: _currentAttendance!.id,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        photoUrl: photoUrl,
        activityDescription: activityDescription,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to check out: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> refreshLocation() async {
    await _getCurrentLocation();
  }

  Future<void> refreshAttendanceStatus() async {
    await _loadCurrentAttendanceStatus();
  }

  Duration? get currentWorkDuration {
    if (_currentAttendance?.checkInTime != null) {
      final checkOutTime = _currentAttendance?.checkOutTime ?? DateTime.now();
      return checkOutTime.difference(_currentAttendance!.checkInTime);
    }
    return null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
