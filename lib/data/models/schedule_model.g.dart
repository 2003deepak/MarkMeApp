// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) =>
    ScheduleModel(
      id: json['id'] as String,
      subjectName: json['subject_name'] as String,
      subjectCode: json['subject_code'] as String,
      classType: $enumDecode(_$ClassTypeEnumMap, json['class_type']),
      instructorName: json['instructor_name'] as String,
      roomNumber: json['room_number'] as String,
      building: json['building'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      status: $enumDecode(_$ScheduleStatusEnumMap, json['status']),
      attendanceMarked: json['attendance_marked'] as bool? ?? false,
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble(),
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ScheduleModelToJson(ScheduleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subject_name': instance.subjectName,
      'subject_code': instance.subjectCode,
      'class_type': _$ClassTypeEnumMap[instance.classType]!,
      'instructor_name': instance.instructorName,
      'room_number': instance.roomNumber,
      'building': instance.building,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'status': _$ScheduleStatusEnumMap[instance.status]!,
      'attendance_marked': instance.attendanceMarked,
      'attendance_percentage': instance.attendancePercentage,
      'description': instance.description,
      'metadata': instance.metadata,
    };

const _$ClassTypeEnumMap = {
  ClassType.lecture: 'lecture',
  ClassType.practical: 'practical',
  ClassType.tutorial: 'tutorial',
  ClassType.exam: 'exam',
  ClassType.assignment: 'assignment',
};

const _$ScheduleStatusEnumMap = {
  ScheduleStatus.scheduled: 'scheduled',
  ScheduleStatus.ongoing: 'ongoing',
  ScheduleStatus.completed: 'completed',
  ScheduleStatus.cancelled: 'cancelled',
  ScheduleStatus.rescheduled: 'rescheduled',
};

ScheduleResponse _$ScheduleResponseFromJson(Map<String, dynamic> json) =>
    ScheduleResponse(
      schedules: (json['schedules'] as List<dynamic>)
          .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ScheduleResponseToJson(ScheduleResponse instance) =>
    <String, dynamic>{
      'schedules': instance.schedules,
      'pagination': instance.pagination,
      'success': instance.success,
      'message': instance.message,
    };

GetSchedulesRequest _$GetSchedulesRequestFromJson(Map<String, dynamic> json) =>
    GetSchedulesRequest(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      classType: $enumDecodeNullable(_$ClassTypeEnumMap, json['class_type']),
      subjectCode: json['subject_code'] as String?,
      status: $enumDecodeNullable(_$ScheduleStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$GetSchedulesRequestToJson(
  GetSchedulesRequest instance,
) => <String, dynamic>{
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'class_type': _$ClassTypeEnumMap[instance.classType],
  'subject_code': instance.subjectCode,
  'status': _$ScheduleStatusEnumMap[instance.status],
};

MarkAttendanceRequest _$MarkAttendanceRequestFromJson(
  Map<String, dynamic> json,
) => MarkAttendanceRequest(
  scheduleId: json['schedule_id'] as String,
  isPresent: json['is_present'] as bool,
  markedAt: DateTime.parse(json['marked_at'] as String),
  location: (json['location'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$MarkAttendanceRequestToJson(
  MarkAttendanceRequest instance,
) => <String, dynamic>{
  'schedule_id': instance.scheduleId,
  'is_present': instance.isPresent,
  'marked_at': instance.markedAt.toIso8601String(),
  'location': instance.location,
  'notes': instance.notes,
};
