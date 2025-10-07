import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class AttendanceLogsScreen extends StatefulWidget {
  static const routeName = '/logs';
  
  const AttendanceLogsScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceLogsScreen> createState() => _AttendanceLogsScreenState();
}

class _AttendanceLogsScreenState extends State<AttendanceLogsScreen> {
  final supabase = Supabase.instance.client;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _logs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _loading = true);
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      // TODO: Fetch attendance logs from Supabase
      // final response = await supabase
      //     .from('attendance')
      //     .select()
      //     .eq('user_id', user.id)
      //     .gte('date', DateFormat('yyyy-MM-dd').format(_startDate))
      //     .lte('date', DateFormat('yyyy-MM-dd').format(_endDate))
      //     .order('check_in_time', ascending: false);
      
      setState(() {
        // _logs = List<Map<String, dynamic>>.from(response);
        _logs = []; // Placeholder
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchLogs();
    }
  }

  Future<void> _exportCsv() async {
    // TODO: Implement CSV export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV export coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date filter
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.date_range, color: AppColors.deloitteGreen),
                    onPressed: _pickDateRange,
                  ),
                ],
              ),
            ),
          ),
          
          // Logs list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchLogs,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _logs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No attendance logs found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.deloitteGreen.withOpacity(0.1),
                                  child: Icon(Icons.check_circle, color: AppColors.deloitteGreen),
                                ),
                                title: Text(
                                  DateFormat('EEEE, dd MMM yyyy').format(
                                    DateTime.parse(log['check_in_time']),
                                  ),
                                ),
                                subtitle: Text(
                                  'In: ${DateFormat('HH:mm').format(DateTime.parse(log['check_in_time']))} | '
                                  'Out: ${log['check_out_time'] != null ? DateFormat('HH:mm').format(DateTime.parse(log['check_out_time'])) : '--'}',
                                ),
                                trailing: Text(
                                  log['total_hours_worked'] != null
                                      ? '${log['total_hours_worked']}h'
                                      : '--',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deloitteGreen,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
