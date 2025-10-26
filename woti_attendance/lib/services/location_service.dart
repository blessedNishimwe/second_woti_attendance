import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../exceptions/app_exceptions.dart';
import 'cache_service.dart';

/// High-performance location service with caching and throttling
class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  LocationModel? _currentLocation;
  bool _isLocationPermissionGranted = false;
  bool _isLoading = false;
  String? _error;
  
  // Throttling
  DateTime? _lastLocationUpdate;
  static const Duration _locationUpdateThrottle = Duration(seconds: 5);
  
  // Stream subscription for location updates
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Cache service
  final CacheService _cacheService = CacheService();

  LocationModel? get currentLocation => _currentLocation;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize location service
  Future<void> initialize() async {
    await _checkLocationPermission();
    await _loadCachedLocation();
    
    if (_isLocationPermissionGranted) {
      await _getCurrentLocation();
    }
  }

  /// Check location permission
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

  /// Request location permission
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

  /// Get current location with throttling and caching
  Future<void> _getCurrentLocation() async {
    if (!_isLocationPermissionGranted) return;

    // Throttle location updates
    if (_lastLocationUpdate != null && 
        DateTime.now().difference(_lastLocationUpdate!) < _locationUpdateThrottle) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final location = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now(),
      );

      _currentLocation = location;
      _lastLocationUpdate = DateTime.now();
      
      // Cache the location
      await _cacheService.setCache(
        CacheKeys.locationData, 
        location.toJson(),
        ttl: const Duration(minutes: 5),
      );
      
      notifyListeners();
    } on LocationServiceDisabledException {
      _setError('Location services are disabled. Please enable them in settings.');
    } on TimeoutException {
      _setError('Location request timed out. Please try again.');
    } catch (e) {
      _setError('Failed to get current location: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load cached location
  Future<void> _loadCachedLocation() async {
    try {
      final cachedData = _cacheService.getCache<Map<String, dynamic>>(CacheKeys.locationData);
      if (cachedData != null) {
        _currentLocation = LocationModel.fromJson(cachedData);
        notifyListeners();
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Start location updates stream
  void startLocationUpdates() {
    if (!_isLocationPermissionGranted) return;
    
    _positionStreamSubscription?.cancel();
    
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Only update if moved 10 meters
      ),
    ).listen(
      (Position position) {
        final location = LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          timestamp: DateTime.now(),
        );

        _currentLocation = location;
        _lastLocationUpdate = DateTime.now();
        
        // Cache the location
        _cacheService.setCache(
          CacheKeys.locationData, 
          location.toJson(),
          ttl: const Duration(minutes: 5),
        );
        
        notifyListeners();
      },
      onError: (error) {
        _setError('Location stream error: ${error.toString()}');
      },
    );
  }

  /// Stop location updates stream
  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if location is within radius
  bool isWithinRadius(double lat1, double lon1, double lat2, double lon2, double radiusMeters) {
    final distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= radiusMeters;
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
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
