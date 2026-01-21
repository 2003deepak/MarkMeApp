// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clerk_analytics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClerkTeacherPerformanceModel _$ClerkTeacherPerformanceModelFromJson(
        Map<String, dynamic> json) =>
    ClerkTeacherPerformanceModel(
      success: json['success'] as bool,
      kpis: TeacherKPIs.fromJson(json['kpis'] as Map<String, dynamic>),
      subjects: (json['subjects'] as List<dynamic>)
          .map((e) => TeacherSubject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ClerkTeacherPerformanceModelToJson(
        ClerkTeacherPerformanceModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'kpis': instance.kpis,
      'subjects': instance.subjects,
    };

TeacherKPIs _$TeacherKPIsFromJson(Map<String, dynamic> json) => TeacherKPIs(
      subjectsCount: (json['subjects_count'] as num).toInt(),
      averageAttendance: (json['average_attendance'] as num).toDouble(),
      totalSessions: (json['total_sessions'] as num).toInt(),
      riskStudents: (json['risk_students'] as num).toInt(),
    );

Map<String, dynamic> _$TeacherKPIsToJson(TeacherKPIs instance) =>
    <String, dynamic>{
      'subjects_count': instance.subjectsCount,
      'average_attendance': instance.averageAttendance,
      'total_sessions': instance.totalSessions,
      'risk_students': instance.riskStudents,
    };

TeacherSubject _$TeacherSubjectFromJson(Map<String, dynamic> json) =>
    TeacherSubject(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      component: json['component'] as String,
      averageAttendance: (json['average_attendance'] as num).toDouble(),
      totalSessions: (json['total_sessions'] as num).toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$TeacherSubjectToJson(TeacherSubject instance) =>
    <String, dynamic>{
      'subject_id': instance.subjectId,
      'subject_name': instance.subjectName,
      'component': instance.component,
      'average_attendance': instance.averageAttendance,
      'total_sessions': instance.totalSessions,
      'status': instance.status,
    };

ClerkSubjectDetailModel _$ClerkSubjectDetailModelFromJson(
        Map<String, dynamic> json) =>
    ClerkSubjectDetailModel(
      success: json['success'] as bool,
      subjectInfo:
          SubjectInfo.fromJson(json['subject_info'] as Map<String, dynamic>),
      kpis: SubjectDetailKPIs.fromJson(json['kpis'] as Map<String, dynamic>),
      attendanceTrend: (json['attendance_trend'] as List<dynamic>)
          .map((e) => AttendanceTrendData.fromJson(e as Map<String, dynamic>))
          .toList(),
      sessionHealth: SessionHealth.fromJson(
          json['session_health'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClerkSubjectDetailModelToJson(
        ClerkSubjectDetailModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'subject_info': instance.subjectInfo,
      'kpis': instance.kpis,
      'attendance_trend': instance.attendanceTrend,
      'session_health': instance.sessionHealth,
    };

SubjectInfo _$SubjectInfoFromJson(Map<String, dynamic> json) => SubjectInfo(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      component: json['component'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$SubjectInfoToJson(SubjectInfo instance) =>
    <String, dynamic>{
      'subject_id': instance.subjectId,
      'subject_name': instance.subjectName,
      'component': instance.component,
      'status': instance.status,
    };

SubjectDetailKPIs _$SubjectDetailKPIsFromJson(Map<String, dynamic> json) =>
    SubjectDetailKPIs(
      averageAttendance: (json['average_attendance'] as num).toDouble(),
      totalSessions: (json['total_sessions'] as num).toInt(),
      riskStudents: (json['risk_students'] as num).toInt(),
    );

Map<String, dynamic> _$SubjectDetailKPIsToJson(SubjectDetailKPIs instance) =>
    <String, dynamic>{
      'average_attendance': instance.averageAttendance,
      'total_sessions': instance.totalSessions,
      'risk_students': instance.riskStudents,
    };

AttendanceTrendData _$AttendanceTrendDataFromJson(Map<String, dynamic> json) =>
    AttendanceTrendData(
      date: json['date'] as String,
      attendance: (json['attendance'] as num).toDouble(),
    );

Map<String, dynamic> _$AttendanceTrendDataToJson(
        AttendanceTrendData instance) =>
    <String, dynamic>{
      'date': instance.date,
      'attendance': instance.attendance,
    };

SessionHealth _$SessionHealthFromJson(Map<String, dynamic> json) =>
    SessionHealth(
      weeklySlots: (json['weekly_slots'] as num).toInt(),
      conductedSessions: (json['conducted_sessions'] as num).toInt(),
      cancelledSessions: (json['cancelled_sessions'] as num).toInt(),
      rescheduledSessions: (json['rescheduled_sessions'] as num).toInt(),
      additionalSessions: (json['additional_sessions'] as num).toInt(),
    );

Map<String, dynamic> _$SessionHealthToJson(SessionHealth instance) =>
    <String, dynamic>{
      'weekly_slots': instance.weeklySlots,
      'conducted_sessions': instance.conductedSessions,
      'cancelled_sessions': instance.cancelledSessions,
      'rescheduled_sessions': instance.rescheduledSessions,
      'additional_sessions': instance.additionalSessions,
    };

ClerkSubjectInsightsModel _$ClerkSubjectInsightsModelFromJson(
        Map<String, dynamic> json) =>
    ClerkSubjectInsightsModel(
      success: json['success'] as bool,
      insights: (json['insights'] as List<dynamic>)
          .map((e) => AnalysisInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      metrics: json['metrics'] == null
          ? null
          : InsightMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClerkSubjectInsightsModelToJson(
        ClerkSubjectInsightsModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'insights': instance.insights,
      'metrics': instance.metrics,
    };

AnalysisInsight _$AnalysisInsightFromJson(Map<String, dynamic> json) =>
    AnalysisInsight(
      text: json['text'] as String,
      severity: json['severity'] as String,
    );

Map<String, dynamic> _$AnalysisInsightToJson(AnalysisInsight instance) =>
    <String, dynamic>{
      'text': instance.text,
      'severity': instance.severity,
    };

InsightMetrics _$InsightMetricsFromJson(Map<String, dynamic> json) =>
    InsightMetrics(
      minAttendance: (json['min_attendance'] as num?)?.toDouble(),
      maxAttendance: (json['max_attendance'] as num?)?.toDouble(),
      volatility: (json['volatility'] as num?)?.toDouble(),
      last5Avg: (json['last_5_avg'] as num?)?.toDouble(),
      previous5Avg: (json['previous_5_avg'] as num?)?.toDouble(),
      trendDelta: (json['trend_delta'] as num?)?.toDouble(),
      lowAttendanceSessions: (json['low_attendance_sessions'] as num?)?.toInt(),
    );

Map<String, dynamic> _$InsightMetricsToJson(InsightMetrics instance) =>
    <String, dynamic>{
      'min_attendance': instance.minAttendance,
      'max_attendance': instance.maxAttendance,
      'volatility': instance.volatility,
      'last_5_avg': instance.last5Avg,
      'previous_5_avg': instance.previous5Avg,
      'trend_delta': instance.trendDelta,
      'low_attendance_sessions': instance.lowAttendanceSessions,
    };
