import 'package:flutter/material.dart';
import 'app_exceptions.dart';

/// Centralized error handling service
class ErrorHandler {
  static void handleError(BuildContext context, dynamic error) {
    String message;
    String title = 'Error';
    IconData icon = Icons.error;

    if (error is AppException) {
      message = error.message;
      
      // Customize title and icon based on exception type
      if (error is AuthenticationException) {
        title = 'Authentication Error';
        icon = Icons.lock;
      } else if (error is LocationException) {
        title = 'Location Error';
        icon = Icons.location_off;
      } else if (error is AttendanceException) {
        title = 'Attendance Error';
        icon = Icons.access_time;
      } else if (error is NetworkException) {
        title = 'Network Error';
        icon = Icons.wifi_off;
      } else if (error is CameraException) {
        title = 'Camera Error';
        icon = Icons.camera_alt;
      }
    } else {
      message = 'An unexpected error occurred. Please try again.';
    }

    _showErrorDialog(context, title, message, icon);
  }

  static void _showErrorDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, color: Colors.red, size: 48),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showSnackBar(BuildContext context, String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }
}
