class ApiConfig {
  // Change this to your backend URL
  // For local development: http://localhost:5000 or http://10.0.2.2:5000 (Android emulator)
  // For production: https://your-domain.com
  static const String baseUrl = 'http://localhost:5000/api/v1';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String attendanceStatus = '/attendance/status';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceSummary = '/attendance/summary';
  
  static const String generateTimesheet = '/timesheets/generate';
  static const String timesheets = '/timesheets';
  
  static const String adminUsers = '/admin/users';
  static const String adminAttendance = '/admin/attendance';
  static const String adminStats = '/admin/stats';
}
