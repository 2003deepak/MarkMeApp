class HeatmapSessionData {
  final String date;
  final double averageAttendance;
  final int totalSessions;

  HeatmapSessionData({
    required this.date,
    required this.averageAttendance,
    required this.totalSessions,
  });

  factory HeatmapSessionData.fromJson(Map<String, dynamic> json) {
    return HeatmapSessionData(
      date: json['date'] as String? ?? '',
      averageAttendance: (json['average_attendance'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceHeatmapResponse {
  final bool success;
  final String message;
  final List<HeatmapSessionData> data;

  AttendanceHeatmapResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AttendanceHeatmapResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceHeatmapResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => HeatmapSessionData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
