class AttendanceModel {
  final String id;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double? latitude;
  final double? longitude;
  final String? checkInPhotoUrl;
  final String? checkOutPhotoUrl;
  final String? activityDescription;
  final double? totalHoursWorked;
  final String status; // 'checked_in', 'checked_out'
  final DateTime date;
  final String dayOfWeek;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    this.latitude,
    this.longitude,
    this.checkInPhotoUrl,
    this.checkOutPhotoUrl,
    this.activityDescription,
    this.totalHoursWorked,
    required this.status,
    required this.date,
    required this.dayOfWeek,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time'] as String)
          : null,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      checkInPhotoUrl: json['check_in_photo_url'] as String?,
      checkOutPhotoUrl: json['check_out_photo_url'] as String?,
      activityDescription: json['activity_description'] as String?,
      totalHoursWorked: json['total_hours_worked'] as double?,
      status: json['status'] as String,
      date: DateTime.parse(json['date'] as String),
      dayOfWeek: json['day_of_week'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'check_in_photo_url': checkInPhotoUrl,
      'check_out_photo_url': checkOutPhotoUrl,
      'activity_description': activityDescription,
      'total_hours_worked': totalHoursWorked,
      'status': status,
      'date': date.toIso8601String(),
      'day_of_week': dayOfWeek,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? userId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? latitude,
    double? longitude,
    String? checkInPhotoUrl,
    String? checkOutPhotoUrl,
    String? activityDescription,
    double? totalHoursWorked,
    String? status,
    DateTime? date,
    String? dayOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      checkInPhotoUrl: checkInPhotoUrl ?? this.checkInPhotoUrl,
      checkOutPhotoUrl: checkOutPhotoUrl ?? this.checkOutPhotoUrl,
      activityDescription: activityDescription ?? this.activityDescription,
      totalHoursWorked: totalHoursWorked ?? this.totalHoursWorked,
      status: status ?? this.status,
      date: date ?? this.date,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCheckedIn => status == 'checked_in';
  bool get isCheckedOut => status == 'checked_out';
  
  Duration? get workDuration {
    if (checkOutTime != null) {
      return checkOutTime!.difference(checkInTime);
    }
    return null;
  }
}
