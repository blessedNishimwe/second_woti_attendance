// DISABLED: This file is kept for reference but not used when using Supabase
// To re-enable custom backend, uncomment this file and add dio/shared_preferences to pubspec.yaml

/*
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
*/

class ApiService {
  // Placeholder class - all functionality commented out for Supabase mode
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  /*
  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  ApiService._internal_OLD() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add access token to requests
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors by refreshing token
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            await _refreshAccessToken();
            // Retry the original request
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $_accessToken';
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          } catch (e) {
            // Refresh failed, logout user
            await clearTokens();
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));

    // Load tokens from storage
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  Future<void> _refreshAccessToken() async {
    final response = await _dio.post(
      ApiConfig.refreshToken,
      data: {'refreshToken': _refreshToken},
    );
    _accessToken = response.data['accessToken'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', _accessToken!);
  }

  bool get isAuthenticated => _accessToken != null;

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );
      await _saveTokens(
        response.data['accessToken'],
        response.data['refreshToken'],
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? employeeId,
    String? department,
    String? role,
    String? facilityId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          'employeeId': employeeId,
          'department': department,
          'role': role,
          'facilityId': facilityId,
        },
      );
      await _saveTokens(
        response.data['accessToken'],
        response.data['refreshToken'],
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(
        ApiConfig.logout,
        data: {'refreshToken': _refreshToken},
      );
    } finally {
      await clearTokens();
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(ApiConfig.profile);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? department,
  }) async {
    final response = await _dio.put(
      ApiConfig.profile,
      data: {'name': name, 'department': department},
    );
    return response.data;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiConfig.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  // Attendance endpoints
  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiConfig.checkIn,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiConfig.checkOut,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAttendanceStatus() async {
    final response = await _dio.get(ApiConfig.attendanceStatus);
    return response.data;
  }

  Future<Map<String, dynamic>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      ApiConfig.attendanceHistory,
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        'limit': limit,
        'offset': offset,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAttendanceSummary({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      ApiConfig.attendanceSummary,
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
      },
    );
    return response.data;
  }

  // Timesheet endpoints
  Future<Map<String, dynamic>> generateTimesheet({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.post(
      ApiConfig.generateTimesheet,
      data: {
        'startDate': startDate,
        'endDate': endDate,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getTimesheets() async {
    final response = await _dio.get(ApiConfig.timesheets);
    return response.data;
  }

  String getTimesheetDownloadUrl(String timesheetId) {
    return '${ApiConfig.baseUrl}${ApiConfig.timesheets}/$timesheetId/download';
  }

  // Admin endpoints
  Future<Map<String, dynamic>> getAllUsers({
    String? role,
    String? facilityId,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      ApiConfig.adminUsers,
      queryParameters: {
        if (role != null) 'role': role,
        if (facilityId != null) 'facilityId': facilityId,
        'limit': limit,
        'offset': offset,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAllAttendance({
    String? userId,
    String? facilityId,
    String? startDate,
    String? endDate,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      ApiConfig.adminAttendance,
      queryParameters: {
        if (userId != null) 'userId': userId,
        if (facilityId != null) 'facilityId': facilityId,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAttendanceStats({
    String? startDate,
    String? endDate,
    String? facilityId,
  }) async {
    final response = await _dio.get(
      ApiConfig.adminStats,
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (facilityId != null) 'facilityId': facilityId,
      },
    );
    return response.data;
  }
  */
  // END OF COMMENTED CODE - Uncomment above to use custom backend API
}
