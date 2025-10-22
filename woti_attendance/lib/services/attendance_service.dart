import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AttendanceDaySummary {
  final String day;
  final String date;
  final double hoursWorked;
  final List<String> activities;

  AttendanceDaySummary({
    required this.day,
    required this.date,
    required this.hoursWorked,
    required this.activities,
  });
}

/// Fetches and aggregates attendance logs for a user for a given period.
/// Returns a map of date (yyyy-MM-dd) to AttendanceDaySummary.
Future<Map<String, AttendanceDaySummary>> fetchAttendanceSummary({
  required String userId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final response = await Supabase.instance.client
      .from('attendance')
      .select('check_in_time, check_out_time, total_hours_worked, activity_description, day_of_week, date')
      .eq('user_id', userId)
      .gte('date', DateFormat('yyyy-MM-dd').format(startDate))
      .lte('date', DateFormat('yyyy-MM-dd').format(endDate))
      .order('date', ascending: true);

  // Aggregate logs by date
  Map<String, AttendanceDaySummary> summary = {};
  for (var log in response) {
    final dateStr = log['date'] as String? ?? DateFormat('yyyy-MM-dd').format(DateTime.parse(log['check_in_time'] as String));
    final day = log['day_of_week'] as String? ?? DateFormat('EEEE').format(DateTime.parse(dateStr));
    
    // Get hours worked
    double hoursWorked = 0.0;
    if (log['total_hours_worked'] != null) {
      hoursWorked = (log['total_hours_worked'] as num).toDouble();
    } else if (log['check_out_time'] != null) {
      // Calculate from check-in and check-out times if total_hours_worked is null
      final checkInTime = DateTime.parse(log['check_in_time'] as String).toUtc(); // parsed as UTC
      final checkOutTime = DateTime.parse(log['check_out_time'] as String).toUtc(); // parsed as UTC
      final duration = checkOutTime.difference(checkInTime);
      hoursWorked = duration.inMinutes / 60.0;
    }
    
    final activity = log['activity_description'] as String? ?? '';

    if (!summary.containsKey(dateStr)) {
      summary[dateStr] = AttendanceDaySummary(
        day: day,
        date: dateStr,
        hoursWorked: hoursWorked,
        activities: activity.isNotEmpty ? [activity] : [],
      );
    } else {
      // Sum hours and append activity
      summary[dateStr] = AttendanceDaySummary(
        day: day,
        date: dateStr,
        hoursWorked: summary[dateStr]!.hoursWorked + hoursWorked,
        activities: [
          ...summary[dateStr]!.activities,
          if (activity.isNotEmpty) activity,
        ],
      );
    }
  }

  return summary;
}

/// Prepares data for PDF export for the given week/month.
/// Returns a list of rows (day, date, hours, activities), and total hours.
Future<Map<String, dynamic>> prepareTimesheetDataForPdf({
  required String userId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final attendanceSummary = await fetchAttendanceSummary(
    userId: userId,
    startDate: startDate,
    endDate: endDate,
  );

  List<Map<String, String>> rows = [];
  double totalHours = 0.0;

  DateTime curDate = startDate;
  while (curDate.isBefore(endDate.add(Duration(days: 1)))) {
    final dateStr = DateFormat('yyyy-MM-dd').format(curDate);
    final displayDate = DateFormat('dd-MMM-yy').format(curDate);
    final dayOfWeek = DateFormat('EEEE').format(curDate);

    final summary = attendanceSummary[dateStr];
    final hoursWorked = summary?.hoursWorked ?? 0.0;
    final activities = summary?.activities.join('; ') ?? '';

    rows.add({
      "day": dayOfWeek,
      "date": displayDate,
      "hoursWorked": hoursWorked > 0 ? hoursWorked.toStringAsFixed(2) : '',
      "activities": activities,
    });

    totalHours += hoursWorked;
    curDate = curDate.add(Duration(days: 1));
  }

  return {
    "rows": rows,
    "totalHours": totalHours,
  };
}
