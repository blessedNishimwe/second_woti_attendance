import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/location_model.dart';
import '../repositories/optimized_attendance_repository.dart';
import '../services/location_service.dart';
import '../exceptions/app_exceptions.dart';

/// Optimized attendance provider with performance improvements
class OptimizedAttendanceProvider extends ChangeNotifier {
  final OptimizedAttendanceRepository _attendanceRepository;
  final LocationService _locationService;
  
  AttendanceModel? _currentAttendance;
  bool _isLoading = false;
  String? _error;
  double? _distanceToFacility;
  bool _isWithinGeofence = false;

  OptimizedAttendanceProvider(this._attendanceRepository, this._locationService) {
    _initializeLocationListener();
  }

  // Getters
  AttendanceModel? get currentAttendance => _currentAttendance;
  LocationModel? get currentLocation => _locationService.currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get distanceToFacility => _distanceToFacility;
  bool get isWithinGeofence => _isWithinGeofence;
  bool get isCheckedIn => _currentAttendance?.isCheckedIn ?? false;
  bool get isCheckedOut => _currentAttendance?.isCheckedOut ?? false;
  bool get isLocationPermissionGranted => _locationService.isLocationPermissionGranted;

  void _initializeLocationListener() {
    _locationService.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    notifyListeners();
    _calculateDistanceToFacility();
  }

  Future<void> initialize() async {
    await _locationService.initialize();
    await _loadCurrentAttendanceStatus();
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

  Future<void> requestLocationPermission() async {
    await _locationService.requestLocationPermission();
    if (_locationService.isLocationPermissionGranted) {
      _calculateDistanceToFacility();
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
      final distance = _locationService.calculateDistance(
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
    await _locationService._getCurrentLocation();
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

  @override
  void dispose() {
    _locationService.removeListener(_onLocationChanged);
    super.dispose();
  }
}
