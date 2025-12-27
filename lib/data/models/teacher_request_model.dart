class TeacherRequestSummary {
  final String requestId;
  final String requestType;
  final String status;
  final String subjectName;
  final DateTime dateRaised;
  final bool createdByMe;
  final bool receivedByMe;
  final bool canTakeAction;

  TeacherRequestSummary({
    required this.requestId,
    required this.requestType,
    required this.status,
    required this.subjectName,
    required this.dateRaised,
    required this.createdByMe,
    required this.receivedByMe,
    required this.canTakeAction,
  });

  factory TeacherRequestSummary.fromJson(Map<String, dynamic> json) {
    return TeacherRequestSummary(
      requestId: json['request_id'] ?? '',
      requestType: json['request_type'] ?? '',
      status: json['status'] ?? '',
      subjectName: json['subject_name'] ?? '',
      dateRaised: DateTime.parse(json['date_raised']),
      createdByMe: json['created_by_me'] ?? false,
      receivedByMe: json['received_by_me'] ?? false,
      canTakeAction: json['can_take_action'] ?? false,
    );
  }
}

class TeacherRequestDetail {
  final String requestId;
  final String requestType;
  final String status;
  final String reason;
  final DateTime date;
  final String startTime;
  final String endTime;
  final DateTime createdAt;
  final RequestUserInfo createdBy;
  final RequestSubjectInfo subject;
  final SwapDetailInfo? swap;
  final bool canTakeAction;

  TeacherRequestDetail({
    required this.requestId,
    required this.requestType,
    required this.status,
    required this.reason,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.createdBy,
    required this.subject,
    this.swap,
    required this.canTakeAction,
  });

  factory TeacherRequestDetail.fromJson(Map<String, dynamic> json) {
    return TeacherRequestDetail(
      requestId: json['request_id'] ?? '',
      requestType: json['request_type'] ?? '',
      status: json['status'] ?? '',
      reason: json['reason'] ?? '',
      date: DateTime.parse(json['date']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      createdBy: RequestUserInfo.fromJson(json['created_by'] ?? {}),
      subject: RequestSubjectInfo.fromJson(json['subject'] ?? {}),
      swap: json['swap'] != null ? SwapDetailInfo.fromJson(json['swap']) : null,
      canTakeAction: json['can_take_action'] ?? false,
    );
  }
}

class RequestUserInfo {
  final String teacherId;
  final String name;

  RequestUserInfo({required this.teacherId, required this.name});

  factory RequestUserInfo.fromJson(Map<String, dynamic> json) {
    return RequestUserInfo(
      teacherId: json['teacher_id'] ?? '',
      name: json['name'] ?? 'Unknown',
    );
  }
}

class RequestSubjectInfo {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String component;

  RequestSubjectInfo({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.component,
  });

  factory RequestSubjectInfo.fromJson(Map<String, dynamic> json) {
    return RequestSubjectInfo(
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject_name'] ?? 'Unknown',
      subjectCode: json['subject_code'] ?? '',
      component: json['component'] ?? '',
    );
  }
}

class SwapDetailInfo {
  final String swapId;
  final String status;
  final RequestUserInfo requestedBy;
  final RequestUserInfo? approvedBy;
  final DateTime? respondedAt;

  SwapDetailInfo({
    required this.swapId,
    required this.status,
    required this.requestedBy,
    this.approvedBy,
    this.respondedAt,
  });

  factory SwapDetailInfo.fromJson(Map<String, dynamic> json) {
    return SwapDetailInfo(
      swapId: json['swap_id'] ?? '',
      status: json['status'] ?? '',
      requestedBy: RequestUserInfo.fromJson(json['requested_by'] ?? {}),
      approvedBy: json['approved_by'] != null
          ? RequestUserInfo.fromJson(json['approved_by'])
          : null,
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'])
          : null,
    );
  }
}
