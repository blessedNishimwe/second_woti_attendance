import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// High-performance caching service with TTL support
class CacheService {
  static const String _cachePrefix = 'woti_cache_';
  static const Duration _defaultTTL = Duration(hours: 1);
  
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, CacheEntry> _memoryCache = {};
  
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Cache data with TTL
  Future<void> setCache<T>(String key, T data, {Duration? ttl}) async {
    final cacheKey = '$_cachePrefix$key';
    final entry = CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl ?? _defaultTTL),
    );
    
    // Store in memory cache
    _memoryCache[cacheKey] = entry;
    
    // Store in persistent cache
    if (_prefs != null) {
      await _prefs!.setString(cacheKey, jsonEncode({
        'data': data,
        'expiresAt': entry.expiresAt.toIso8601String(),
      }));
    }
  }

  /// Get cached data
  T? getCache<T>(String key) {
    final cacheKey = '$_cachePrefix$key';
    
    // Check memory cache first
    final memoryEntry = _memoryCache[cacheKey];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return memoryEntry.data as T?;
    }
    
    // Check persistent cache
    if (_prefs != null) {
      final cachedString = _prefs!.getString(cacheKey);
      if (cachedString != null) {
        try {
          final cachedData = jsonDecode(cachedString);
          final expiresAt = DateTime.parse(cachedData['expiresAt']);
          
          if (expiresAt.isAfter(DateTime.now())) {
            final entry = CacheEntry(
              data: cachedData['data'],
              expiresAt: expiresAt,
            );
            _memoryCache[cacheKey] = entry;
            return cachedData['data'] as T?;
          } else {
            // Remove expired entry
            _prefs!.remove(cacheKey);
          }
        } catch (e) {
          // Remove corrupted cache
          _prefs!.remove(cacheKey);
        }
      }
    }
    
    return null;
  }

  /// Remove specific cache entry
  Future<void> removeCache(String key) async {
    final cacheKey = '$_cachePrefix$key';
    _memoryCache.remove(cacheKey);
    await _prefs?.remove(cacheKey);
  }

  /// Clear all cache
  Future<void> clearCache() async {
    _memoryCache.clear();
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((key) => key.startsWith(_cachePrefix));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    final now = DateTime.now();
    
    // Clear expired memory cache
    _memoryCache.removeWhere((key, entry) => entry.isExpired);
    
    // Clear expired persistent cache
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((key) => key.startsWith(_cachePrefix));
      for (final key in keys) {
        final cachedString = _prefs!.getString(key);
        if (cachedString != null) {
          try {
            final cachedData = jsonDecode(cachedString);
            final expiresAt = DateTime.parse(cachedData['expiresAt']);
            if (expiresAt.isBefore(now)) {
              await _prefs!.remove(key);
            }
          } catch (e) {
            await _prefs!.remove(key);
          }
        }
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int memoryEntries = 0;
    int expiredEntries = 0;
    
    for (final entry in _memoryCache.values) {
      memoryEntries++;
      if (entry.isExpired) expiredEntries++;
    }
    
    return {
      'memoryEntries': memoryEntries,
      'expiredEntries': expiredEntries,
      'persistentEntries': _prefs?.getKeys().where((key) => key.startsWith(_cachePrefix)).length ?? 0,
    };
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache keys for consistent usage
class CacheKeys {
  static const String userProfile = 'user_profile';
  static const String facilityInfo = 'facility_info';
  static const String attendanceStatus = 'attendance_status';
  static const String attendanceHistory = 'attendance_history';
  static const String timesheetData = 'timesheet_data';
  static const String locationData = 'location_data';
}
