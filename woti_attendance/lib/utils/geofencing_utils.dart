import 'dart:math';

class GeofencingUtils {
  /// Returns the distance in meters between two GPS coordinates (Haversine formula).
  static double calculateDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Returns true if (lat1, lon1) is within [radiusMeters] of (lat2, lon2)
  static bool isWithinRadius(
      double lat1, double lon1, double lat2, double lon2, double radiusMeters) {
    return calculateDistanceMeters(lat1, lon1, lat2, lon2) <= radiusMeters;
  }

  static double _degToRad(double deg) => deg * (pi / 180);
}