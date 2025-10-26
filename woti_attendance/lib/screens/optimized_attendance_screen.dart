import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../providers/optimized_attendance_provider.dart';
import '../services/timer_service.dart';
import '../services/location_service.dart';
import '../services/error_handler.dart';

/// High-performance attendance screen with optimized rendering
class OptimizedAttendanceScreen extends StatefulWidget {
  const OptimizedAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<OptimizedAttendanceScreen> createState() => _OptimizedAttendanceScreenState();
}

class _OptimizedAttendanceScreenState extends State<OptimizedAttendanceScreen> {
  final TextEditingController _activityController = TextEditingController();
  final TimerService _timerService = TimerService();

  @override
  void initState() {
    super.initState();
    _timerService.start();
    
    // Initialize attendance provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OptimizedAttendanceProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _activityController.dispose();
    _timerService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final isWide = media.size.width > 700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('WoTi Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = Provider.of<OptimizedAttendanceProvider>(context, listen: false);
          await provider.refreshAttendanceStatus();
          await provider.refreshLocation();
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity,
              ),
              child: Column(
                children: [
                  // Optimized real-time clock
                  _OptimizedClockCard(),
                  const SizedBox(height: 16),

                  // Status card
                  Consumer<OptimizedAttendanceProvider>(
                    builder: (context, provider, child) {
                      return _StatusCard(
                        attendanceStatus: provider.isCheckedIn ? 'Checked In' : 'Checked Out',
                        currentAttendance: provider.currentAttendance,
                        currentWorkDuration: provider.currentWorkDuration,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location card
                  Consumer<OptimizedAttendanceProvider>(
                    builder: (context, provider, child) {
                      return _LocationCard(
                        currentLocation: provider.currentLocation,
                        isLoadingLocation: provider.isLoading,
                        onRefreshLocation: () => provider.refreshLocation(),
                        distanceToFacility: provider.distanceToFacility,
                        isWithinGeofence: provider.isWithinGeofence,
                        isLocationPermissionGranted: provider.isLocationPermissionGranted,
                        onRequestPermission: () => provider.requestLocationPermission(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Activity description field
                  _ActivityDescriptionCard(controller: _activityController),
                  const SizedBox(height: 16),

                  // Check-in/Check-out buttons
                  Consumer<OptimizedAttendanceProvider>(
                    builder: (context, provider, child) {
                      return _ActionButtons(
                        isCheckedIn: provider.isCheckedIn,
                        isLoading: provider.isLoading,
                        canPerformAction: provider.currentLocation != null,
                        onCheckIn: () => _performCheckIn(provider),
                        onCheckOut: () => _performCheckOut(provider),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performCheckIn(OptimizedAttendanceProvider provider) async {
    final success = await provider.checkIn(
      activityDescription: _activityController.text.trim().isEmpty 
          ? null 
          : _activityController.text.trim(),
    );

    if (success) {
      _activityController.clear();
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Successfully checked in!');
      }
    } else if (provider.error != null) {
      ErrorHandler.handleError(context, provider.error!);
    }
  }

  Future<void> _performCheckOut(OptimizedAttendanceProvider provider) async {
    final success = await provider.checkOut(
      activityDescription: _activityController.text.trim().isEmpty 
          ? null 
          : _activityController.text.trim(),
    );

    if (success) {
      _activityController.clear();
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Successfully checked out!');
      }
    } else if (provider.error != null) {
      ErrorHandler.handleError(context, provider.error!);
    }
  }
}

/// Optimized clock card with minimal rebuilds
class _OptimizedClockCard extends StatelessWidget {
  const _OptimizedClockCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Optimized clock that only rebuilds when time changes
            OptimizedClock(
              formatter: (time) => DateFormat('HH:mm:ss').format(time),
              style: TextStyle(
                color: AppColors.deloitteGreen,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            // Date that only rebuilds when date changes
            OptimizedClock(
              formatter: (time) => DateFormat('EEEE, MMMM d, yyyy').format(time),
              updateInterval: const Duration(hours: 1), // Only update hourly
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimized status card
class _StatusCard extends StatelessWidget {
  final String attendanceStatus;
  final dynamic currentAttendance;
  final Duration? currentWorkDuration;

  const _StatusCard({
    Key? key,
    required this.attendanceStatus,
    required this.currentAttendance,
    required this.currentWorkDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCheckedIn = attendanceStatus == 'Checked In';

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCheckedIn ? AppColors.deloitteGreen : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    attendanceStatus,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isCheckedIn && currentAttendance != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checked in at:',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                  Text(
                    DateFormat('HH:mm').format(
                      DateTime.parse(currentAttendance['check_in_time']),
                    ),
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hours worked:',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                  Text(
                    currentWorkDuration != null 
                        ? '${(currentWorkDuration!.inMinutes / 60.0).toStringAsFixed(2)}'
                        : '0.00',
                    style: const TextStyle(
                      color: AppColors.deloitteGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Optimized location card
class _LocationCard extends StatelessWidget {
  final dynamic currentLocation;
  final bool isLoadingLocation;
  final VoidCallback onRefreshLocation;
  final double? distanceToFacility;
  final bool isWithinGeofence;
  final bool isLocationPermissionGranted;
  final VoidCallback onRequestPermission;

  const _LocationCard({
    Key? key,
    required this.currentLocation,
    required this.isLoadingLocation,
    required this.onRefreshLocation,
    required this.distanceToFacility,
    required this.isWithinGeofence,
    required this.isLocationPermissionGranted,
    required this.onRequestPermission,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.deloitteGreen),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLoadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.deloitteGreen),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.deloitteGreen),
                    onPressed: onRefreshLocation,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isLocationPermissionGranted)
              ElevatedButton(
                onPressed: onRequestPermission,
                child: const Text('Enable Location'),
              )
            else if (currentLocation != null) ...[
              Text(
                'Latitude: ${currentLocation.latitude.toStringAsFixed(6)}',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              Text(
                'Longitude: ${currentLocation.longitude.toStringAsFixed(6)}',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              if (distanceToFacility != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isWithinGeofence ? Icons.check_circle : Icons.warning,
                      color: isWithinGeofence ? AppColors.deloitteGreen : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Distance to facility: ${distanceToFacility!.toStringAsFixed(0)}m',
                      style: TextStyle(
                        color: isWithinGeofence ? AppColors.deloitteGreen : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ] else
              const Text(
                'Location not available',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }
}

/// Activity description card
class _ActivityDescriptionCard extends StatelessWidget {
  final TextEditingController controller;

  const _ActivityDescriptionCard({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Activity Description (Optional)',
            hintText: 'What did you work on today?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.description, color: AppColors.deloitteGreen),
          ),
        ),
      ),
    );
  }
}

/// Action buttons
class _ActionButtons extends StatelessWidget {
  final bool isCheckedIn;
  final bool isLoading;
  final bool canPerformAction;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _ActionButtons({
    Key? key,
    required this.isCheckedIn,
    required this.isLoading,
    required this.canPerformAction,
    required this.onCheckIn,
    required this.onCheckOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCheckedIn) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: canPerformAction && !isLoading ? onCheckOut : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Icon(Icons.logout),
          label: Text(
            isLoading ? 'Checking Out...' : 'Check Out',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: canPerformAction && !isLoading ? onCheckIn : null,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Icon(Icons.login),
          label: Text(
            isLoading ? 'Checking In...' : 'Check In',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }
}
