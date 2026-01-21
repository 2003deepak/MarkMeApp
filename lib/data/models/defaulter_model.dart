class DefaulterSubject {
  final String id;
  final String name;
  final double percentage;
  final String code;

  DefaulterSubject({
    required this.id,
    required this.name,
    required this.percentage,
    required this.code,
  });

  factory DefaulterSubject.fromJson(Map<String, dynamic> json) {
    return DefaulterSubject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      code: json['code'] ?? '',
    );
  }
}

class DefaulterStudent {
  final String name;
  final int roll;
  final String program;
  final int semester;
  final String risk;
  final String studentId;
  final double overallPercentage;
  final String? profilePicture;
  final List<DefaulterSubject> defaulterSubjects;

  DefaulterStudent({
    required this.name,
    required this.roll,
    required this.program,
    required this.semester,
    required this.risk,
    required this.studentId,
    required this.overallPercentage,
    this.profilePicture,
    required this.defaulterSubjects,
  });

  factory DefaulterStudent.fromJson(Map<String, dynamic> json) {
    return DefaulterStudent(
      name: json['name'] ?? '',
      roll: json['roll'] ?? 0,
      program: json['program'] ?? '',
      semester: json['semester'] ?? 1,
      risk: json['risk'] ?? 'LOW',
      studentId: json['student_id'] ?? '',
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble() ?? 0.0,
      profilePicture: json['profile_picture'],
      defaulterSubjects: (json['defaulter_subjects'] as List<dynamic>?)
              ?.map((e) => DefaulterSubject.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DefaulterResponse {
  final bool success;
  final int page;
  final int limit;
  final int total;
  final List<DefaulterStudent> students;

  DefaulterResponse({
    required this.success,
    required this.page,
    required this.limit,
    required this.total,
    required this.students,
  });

  factory DefaulterResponse.fromJson(Map<String, dynamic> json) {
    return DefaulterResponse(
      success: json['success'] ?? false,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      students: (json['students'] as List<dynamic>?)
              ?.map((e) => DefaulterStudent.fromJson(e))
              .toList() ??
          [],
    );
  }
}
