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
      .select('date, day_of_week, total_hours_worked, activity_description')
      .eq('user_id', userId)
      .gte('date', DateFormat('yyyy-MM-dd').format(startDate))
      .lte('date', DateFormat('yyyy-MM-dd').format(endDate))
      .order('date', ascending: true);

  // Aggregate logs by date
  Map<String, AttendanceDaySummary> summary = {};
  for (var log in response) {
    final date = log['date'] as String;
    final day = log['day_of_week'] as String? ??
        DateFormat('EEEE').format(DateTime.parse(date));
    final hoursWorked =
        double.tryParse(log['total_hours_worked'] ?? '0') ?? 0.0;
    final activity = log['activity_description'] as String? ?? '';

    if (!summary.containsKey(date)) {
      summary[date] = AttendanceDaySummary(
        day: day,
        date: date,
        hoursWorked: hoursWorked,
        activities: activity.isNotEmpty ? [activity] : [],
      );
    } else {
      // Sum hours and append activity
      summary[date] = AttendanceDaySummary(
        day: day,
        date: date,
        hoursWorked: summary[date]!.hoursWorked + hoursWorked,
        activities: [
          ...summary[date]!.activities,
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
