import '../models/attendance_model.dart';
import '../exceptions/app_exceptions.dart';

/// Abstract repository interface for attendance data operations
abstract class AttendanceRepository {
  Future<AttendanceModel?> getCurrentAttendanceStatus(String userId);
  Future<AttendanceModel> checkIn({
    required String userId,
    required double latitude,
    required double longitude,
    String? photoUrl,
    String? activityDescription,
  });
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    String? photoUrl,
    String? activityDescription,
  });
  Future<List<AttendanceModel>> getAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  });
  Future<Map<String, dynamic>> getAttendanceSummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// Supabase implementation of AttendanceRepository
class SupabaseAttendanceRepository implements AttendanceRepository {
  @override
  Future<AttendanceModel?> getCurrentAttendanceStatus(String userId) async {
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
      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw DatabaseException('Failed to get current attendance status: ${e.toString()}');
    }
  }

  @override
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
      
      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw CheckInException('Failed to check in: ${e.toString()}');
    }
  }

  @override
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
          .select('check_in_time')
          .eq('id', attendanceId)
          .single();
      
      final checkInTime = DateTime.parse(attendance['check_in_time'] as String);
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
      
      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw CheckOutException('Failed to check out: ${e.toString()}');
    }
  }

  @override
  Future<List<AttendanceModel>> getAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = Supabase.instance.client
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      final response = await query;
      
      return (response as List)
          .map((json) => AttendanceModel.fromJson(json))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get attendance history: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendanceSummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
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

      return {
        'totalHours': totalHours,
        'totalDays': totalDays,
        'checkedInDays': checkedInDays,
        'averageHoursPerDay': checkedInDays > 0 ? totalHours / checkedInDays : 0.0,
      };
    } catch (e) {
      throw DatabaseException('Failed to get attendance summary: ${e.toString()}');
    }
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }
}
