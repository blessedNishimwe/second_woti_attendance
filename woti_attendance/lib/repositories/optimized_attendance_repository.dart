import '../models/attendance_model.dart';
import '../exceptions/app_exceptions.dart';
import '../services/cache_service.dart';

/// Optimized attendance repository with caching, pagination, and performance improvements
class OptimizedAttendanceRepository {
  final CacheService _cacheService = CacheService();
  
  /// Get current attendance status with caching
  Future<AttendanceModel?> getCurrentAttendanceStatus(String userId) async {
    final cacheKey = '${CacheKeys.attendanceStatus}_$userId';
    
    // Try cache first
    final cachedData = _cacheService.getCache<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      return AttendanceModel.fromJson(cachedData);
    }

    try {
      final response = await Supabase.instance.client
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('status', 'checked_in')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) return null;
      
      final attendance = AttendanceModel.fromJson(response);
      
      // Cache the attendance status
      await _cacheService.setCache(
        cacheKey, 
        response,
        ttl: const Duration(minutes: 5),
      );
      
      return attendance;
    } catch (e) {
      throw DatabaseException('Failed to get current attendance status: ${e.toString()}');
    }
  }

  /// Check in with cache invalidation
  Future<AttendanceModel> checkIn({
    required String userId,
    required double latitude,
    required double longitude,
    String? photoUrl,
    String? activityDescription,
  }) async {
    try {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day);
      
      final attendanceData = {
        'user_id': userId,
        'check_in_time': now.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'check_in_photo_url': photoUrl,
        'activity_description': activityDescription,
        'status': 'checked_in',
        'date': date.toIso8601String(),
        'day_of_week': _getDayOfWeek(now),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await Supabase.instance.client
          .from('attendance')
          .insert(attendanceData)
          .select()
          .single();
      
      final attendance = AttendanceModel.fromJson(response);
      
      // Invalidate related caches
      await _invalidateUserAttendanceCache(userId);
      
      return attendance;
    } catch (e) {
      throw CheckInException('Failed to check in: ${e.toString()}');
    }
  }

  /// Check out with cache invalidation
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    String? photoUrl,
    String? activityDescription,
  }) async {
    try {
      // First get the check-in time to calculate hours worked
      final attendance = await Supabase.instance.client
          .from('attendance')
          .select('check_in_time, user_id')
          .eq('id', attendanceId)
          .single();
      
      final checkInTime = DateTime.parse(attendance['check_in_time'] as String);
      final userId = attendance['user_id'] as String;
      final checkOutTime = DateTime.now();
      final hoursWorked = checkOutTime.difference(checkInTime).inMinutes / 60.0;

      final updateData = {
        'check_out_time': checkOutTime.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'check_out_photo_url': photoUrl,
        'activity_description': activityDescription,
        'total_hours_worked': hoursWorked,
        'status': 'checked_out',
        'updated_at': checkOutTime.toIso8601String(),
      };

      final response = await Supabase.instance.client
          .from('attendance')
          .update(updateData)
          .eq('id', attendanceId)
          .select()
          .single();
      
      final updatedAttendance = AttendanceModel.fromJson(response);
      
      // Invalidate related caches
      await _invalidateUserAttendanceCache(userId);
      
      return updatedAttendance;
    } catch (e) {
      throw CheckOutException('Failed to check out: ${e.toString()}');
    }
  }

  /// Get attendance history with pagination and caching
  Future<List<AttendanceModel>> getAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    final cacheKey = '${CacheKeys.attendanceHistory}_${userId}_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}_${limit}_$offset';
    
    // Try cache first for paginated results
    final cachedData = _cacheService.getCache<List<dynamic>>(cacheKey);
    if (cachedData != null) {
      return cachedData.map((json) => AttendanceModel.fromJson(json)).toList();
    }

    try {
      var query = Supabase.instance.client
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      final response = await query;
      
      final attendanceList = (response as List)
          .map((json) => AttendanceModel.fromJson(json))
          .toList();
      
      // Cache the paginated results
      await _cacheService.setCache(
        cacheKey, 
        response,
        ttl: const Duration(minutes: 10),
      );
      
      return attendanceList;
    } catch (e) {
      throw DatabaseException('Failed to get attendance history: ${e.toString()}');
    }
  }

  /// Get attendance summary with caching
  Future<Map<String, dynamic>> getAttendanceSummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final cacheKey = '${CacheKeys.timesheetData}_${userId}_${startDate.toIso8601String()}_${endDate.toIso8601String()}';
    
    // Try cache first
    final cachedData = _cacheService.getCache<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final response = await Supabase.instance.client
          .from('attendance')
          .select('total_hours_worked, status, date')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      double totalHours = 0.0;
      int totalDays = 0;
      int checkedInDays = 0;

      for (var record in response) {
        if (record['total_hours_worked'] != null) {
          totalHours += (record['total_hours_worked'] as num).toDouble();
        }
        if (record['status'] == 'checked_out') {
          checkedInDays++;
        }
        totalDays++;
      }

      final summary = {
        'totalHours': totalHours,
        'totalDays': totalDays,
        'checkedInDays': checkedInDays,
        'averageHoursPerDay': checkedInDays > 0 ? totalHours / checkedInDays : 0.0,
      };
      
      // Cache the summary
      await _cacheService.setCache(
        cacheKey, 
        summary,
        ttl: const Duration(minutes: 15),
      );
      
      return summary;
    } catch (e) {
      throw DatabaseException('Failed to get attendance summary: ${e.toString()}');
    }
  }

  /// Invalidate user-specific attendance cache
  Future<void> _invalidateUserAttendanceCache(String userId) async {
    final keys = [
      '${CacheKeys.attendanceStatus}_$userId',
      '${CacheKeys.attendanceHistory}_$userId',
      '${CacheKeys.timesheetData}_$userId',
    ];
    
    for (final key in keys) {
      await _cacheService.removeCache(key);
    }
  }

  /// Clear all attendance cache
  Future<void> clearAttendanceCache() async {
    await _cacheService.removeCache(CacheKeys.attendanceStatus);
    await _cacheService.removeCache(CacheKeys.attendanceHistory);
    await _cacheService.removeCache(CacheKeys.timesheetData);
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }
}
