class AttendanceTrendData {
  final String label;
  final double attendance;

  AttendanceTrendData({
    required this.label,
    required this.attendance,
  });

  factory AttendanceTrendData.fromJson(Map<String, dynamic> json) {
    return AttendanceTrendData(
      label: json['label'] as String? ?? '',
      attendance: (json['attendance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'attendance': attendance,
    };
  }
}

class AttendanceTrendsResponse {
  final bool success;
  final String message;
  final List<AttendanceTrendData> data;

  AttendanceTrendsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AttendanceTrendsResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceTrendsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => AttendanceTrendData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}
