class ExtremeSession {
  final String date;
  final String subject;
  final double attendance;

  ExtremeSession({
    required this.date,
    required this.subject,
    required this.attendance,
  });

  factory ExtremeSession.fromJson(Map<String, dynamic> json) {
    return ExtremeSession(
      date: json['date'] ?? '',
      subject: json['subject'] ?? '',
      attendance: (json['attendance'] as num).toDouble(),
    );
  }
}

class AttendanceExtremesResponse {
  final bool success;
  final String period;
  final String startDate;
  final String endDate;
  final ExtremeSession highest;
  final ExtremeSession lowest;

  AttendanceExtremesResponse({
    required this.success,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.highest,
    required this.lowest,
  });

  factory AttendanceExtremesResponse.fromJson(Map<String, dynamic> json) {
    final extremes = json['weekly_extremes'] ?? json['monthly_extremes'] ?? json['extremes'] ?? {};
    
    return AttendanceExtremesResponse(
      success: json['success'] ?? false,
      period: json['period'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      highest: ExtremeSession.fromJson(extremes['highest'] ?? {}),
      lowest: ExtremeSession.fromJson(extremes['lowest'] ?? {}),
    );
  }
}
