import 'package:json_annotation/json_annotation.dart';

part 'clerk_analytics_model.g.dart';

// --- Teacher Overview Models ---

@JsonSerializable()
class ClerkTeacherPerformanceModel {
  final bool success;
  final TeacherKPIs kpis;
  final List<TeacherSubject> subjects;

  ClerkTeacherPerformanceModel({
    required this.success,
    required this.kpis,
    required this.subjects,
  });

  factory ClerkTeacherPerformanceModel.fromJson(Map<String, dynamic> json) =>
      _$ClerkTeacherPerformanceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ClerkTeacherPerformanceModelToJson(this);
}

@JsonSerializable()
class TeacherKPIs {
  @JsonKey(name: 'subjects_count')
  final int subjectsCount;
  @JsonKey(name: 'average_attendance')
  final double averageAttendance;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'risk_students')
  final int riskStudents;

  TeacherKPIs({
    required this.subjectsCount,
    required this.averageAttendance,
    required this.totalSessions,
    required this.riskStudents,
  });

  factory TeacherKPIs.fromJson(Map<String, dynamic> json) =>
      _$TeacherKPIsFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherKPIsToJson(this);
}

@JsonSerializable()
class TeacherSubject {
  @JsonKey(name: 'subject_id')
  final String subjectId;
  @JsonKey(name: 'subject_name')
  final String subjectName;
  final String component;
  @JsonKey(name: 'average_attendance')
  final double averageAttendance;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  final String status; // 'WARNING' | 'CRITICAL' | 'GOOD' etc.

  TeacherSubject({
    required this.subjectId,
    required this.subjectName,
    required this.component,
    required this.averageAttendance,
    required this.totalSessions,
    required this.status,
  });

  factory TeacherSubject.fromJson(Map<String, dynamic> json) =>
      _$TeacherSubjectFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherSubjectToJson(this);
}

// --- Subject Detail Models ---

@JsonSerializable()
class ClerkSubjectDetailModel {
  final bool success;
  @JsonKey(name: 'subject_info')
  final SubjectInfo subjectInfo;
  final SubjectDetailKPIs kpis;
  @JsonKey(name: 'attendance_trend')
  final List<AttendanceTrendData> attendanceTrend;
  @JsonKey(name: 'session_health')
  final SessionHealth sessionHealth;

  ClerkSubjectDetailModel({
    required this.success,
    required this.subjectInfo,
    required this.kpis,
    required this.attendanceTrend,
    required this.sessionHealth,
  });

  factory ClerkSubjectDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ClerkSubjectDetailModelFromJson(json);
  Map<String, dynamic> toJson() => _$ClerkSubjectDetailModelToJson(this);
}

@JsonSerializable()
class SubjectInfo {
  @JsonKey(name: 'subject_id')
  final String subjectId;
  @JsonKey(name: 'subject_name')
  final String subjectName;
  final String component;
  final String status;

  SubjectInfo({
    required this.subjectId,
    required this.subjectName,
    required this.component,
    required this.status,
  });

  factory SubjectInfo.fromJson(Map<String, dynamic> json) =>
      _$SubjectInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectInfoToJson(this);
}

@JsonSerializable()
class SubjectDetailKPIs {
  @JsonKey(name: 'average_attendance')
  final double averageAttendance;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'risk_students')
  final int riskStudents;

  SubjectDetailKPIs({
    required this.averageAttendance,
    required this.totalSessions,
    required this.riskStudents,
  });

  factory SubjectDetailKPIs.fromJson(Map<String, dynamic> json) =>
      _$SubjectDetailKPIsFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectDetailKPIsToJson(this);
}

@JsonSerializable()
class AttendanceTrendData {
  final String date;
  final double attendance;

  AttendanceTrendData({required this.date, required this.attendance});

  factory AttendanceTrendData.fromJson(Map<String, dynamic> json) =>
      _$AttendanceTrendDataFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceTrendDataToJson(this);
}

@JsonSerializable()
class SessionHealth {
  @JsonKey(name: 'weekly_slots')
  final int weeklySlots;
  @JsonKey(name: 'conducted_sessions')
  final int conductedSessions;
  @JsonKey(name: 'cancelled_sessions')
  final int cancelledSessions;
  @JsonKey(name: 'rescheduled_sessions')
  final int rescheduledSessions;
  @JsonKey(name: 'additional_sessions')
  final int additionalSessions;

  SessionHealth({
    required this.weeklySlots,
    required this.conductedSessions,
    required this.cancelledSessions,
    required this.rescheduledSessions,
    required this.additionalSessions,
  });

  factory SessionHealth.fromJson(Map<String, dynamic> json) =>
      _$SessionHealthFromJson(json);
  Map<String, dynamic> toJson() => _$SessionHealthToJson(this);
}

// --- Insights Models ---

@JsonSerializable()
class ClerkSubjectInsightsModel {
  final bool success;
  final List<AnalysisInsight> insights;
  final InsightMetrics? metrics;

  ClerkSubjectInsightsModel({
    required this.success,
    required this.insights,
    this.metrics,
  });

  factory ClerkSubjectInsightsModel.fromJson(Map<String, dynamic> json) =>
      _$ClerkSubjectInsightsModelFromJson(json);
  Map<String, dynamic> toJson() => _$ClerkSubjectInsightsModelToJson(this);
}

@JsonSerializable()
class AnalysisInsight {
  final String text;
  final String severity; // 'INFO', 'WARNING', 'CRITICAL'

  AnalysisInsight({required this.text, required this.severity});

  factory AnalysisInsight.fromJson(Map<String, dynamic> json) =>
      _$AnalysisInsightFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisInsightToJson(this);
}

@JsonSerializable()
class InsightMetrics {
  @JsonKey(name: 'min_attendance')
  final double? minAttendance;
  @JsonKey(name: 'max_attendance')
  final double? maxAttendance;
  final double? volatility;
  @JsonKey(name: 'last_5_avg')
  final double? last5Avg;
  @JsonKey(name: 'previous_5_avg')
  final double? previous5Avg;
  @JsonKey(name: 'trend_delta')
  final double? trendDelta;
  @JsonKey(name: 'low_attendance_sessions')
  final int? lowAttendanceSessions;

  InsightMetrics({
    this.minAttendance,
    this.maxAttendance,
    this.volatility,
    this.last5Avg,
    this.previous5Avg,
    this.trendDelta,
    this.lowAttendanceSessions,
  });

  factory InsightMetrics.fromJson(Map<String, dynamic> json) =>
      _$InsightMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$InsightMetricsToJson(this);
}
