class AttendanceHistoryResponse {
  final bool success;
  final String message;
  final List<AttendanceHistoryRecord> records;

  AttendanceHistoryResponse({
    required this.success,
    required this.message,
    required this.records,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      records:
          (json['records'] as List<dynamic>?)
              ?.map((e) => AttendanceHistoryRecord.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AttendanceHistoryRecord {
  final String attendanceId;
  final String date;
  final String day;
  final String subject;
  final String? startTime;
  final String? endTime;
  final bool present;
  final bool isExceptionSession;

  // Teacher specific fields
  final int? presentCount;
  final int? absentCount;
  final double? attendancePercentage;
  final String? componentType;

  AttendanceHistoryRecord({
    required this.attendanceId,
    required this.date,
    required this.day,
    required this.subject,
    this.startTime,
    this.endTime,
    this.present = false,
    this.isExceptionSession = false,
    this.presentCount,
    this.absentCount,
    this.attendancePercentage,
    this.componentType,
  });

  factory AttendanceHistoryRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryRecord(
      attendanceId: json['attendance_id'] ?? '',
      date: json['date'] ?? '',
      day: json['day'] ?? '',
      subject: json['subject'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      present: json['present'] ?? false,
      isExceptionSession: json['is_exception_session'] ?? false,
      presentCount: json['present_count'],
      absentCount: json['absent_count'],
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble(),
      componentType: json['component_type'],
    );
  }

  DateTime get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }
}
