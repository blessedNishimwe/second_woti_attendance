import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/attendance_service.dart';
import '../utils/timesheet_pdf_utils.dart';
import 'package:printing/printing.dart';
import '../app_theme.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({Key? key}) : super(key: key);

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  DateTime _weekStart = _getStartOfWeek(DateTime.now());
  DateTime _weekEnd = _getEndOfWeek(DateTime.now());
  List<Map<String, String>> _summaryRows = [];
  double _totalHours = 0.0;
  bool _loading = false;

  static DateTime _getStartOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));
  static DateTime _getEndOfWeek(DateTime date) =>
      date.add(Duration(days: 7 - date.weekday));

  @override
  void initState() {
    super.initState();
    _loadAttendanceSummary();
  }

  Future<void> _loadAttendanceSummary() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await prepareTimesheetDataForPdf(
        userId: user.id,
        startDate: _weekStart,
        endDate: _weekEnd,
      );

      setState(() {
        _summaryRows = List<Map<String, String>>.from(data['rows']);
        _totalHours = data['totalHours'] as double;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading timesheet: $e')),
        );
      }
    }
  }

  Future<void> _pickWeek() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _weekStart, end: _weekEnd),
    );
    if (picked != null) {
      setState(() {
        _weekStart = picked.start;
        _weekEnd = picked.end;
      });
      await _loadAttendanceSummary();
    }
  }

  Future<void> _exportAndSharePdf() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await prepareTimesheetDataForPdf(
        userId: user.id,
        startDate: _weekStart,
        endDate: _weekEnd,
      );

      final pdf = await TimesheetPdfUtils.generateTimesheetPdf(
        employeeName: user.userMetadata?['name'] ?? user.email ?? 'User',
        startDate: _weekStart,
        endDate: _weekEnd,
        rows: List<Map<String, String>>.from(data['rows']),
        totalHours: data['totalHours'] as double,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Timesheet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export PDF",
            onPressed: _exportAndSharePdf,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendanceSummary,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: theme.cardColor,
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${DateFormat('dd-MMM').format(_weekStart)} to ${DateFormat('dd-MMM').format(_weekEnd)}",
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.date_range),
                          tooltip: "Pick date range",
                          onPressed: _pickWeek,
                          color: AppColors.deloitteGreen,
                        ),
                      ],
                    ),
                    const Divider(),
                    _loading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _summaryRows.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.event_busy,
                                        size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No attendance records for this period',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _summaryRows.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (context, i) {
                                      final row = _summaryRows[i];
                                      return ListTile(
                                        title: Text(
                                          "${row['day']} (${row['date']})",
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        subtitle: Text(
                                          row['activities'] ?? '',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        trailing: Text(
                                          row['hoursWorked'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.deloitteGreen,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(thickness: 2),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            "Total Hours Worked:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _totalHours.toStringAsFixed(2),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppColors.deloitteGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Export/Share PDF"),
                        onPressed: _loading ? null : _exportAndSharePdf,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
