class TeacherScope {
  final String program;
  final String department;

  TeacherScope({required this.program, required this.department});

  factory TeacherScope.fromJson(Map<String, dynamic> json) {
    return TeacherScope(
      program: json['program'] ?? '',
      department: json['department'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'program': program,
      'department': department,
    };
  }
}

class Teacher {
  final String id;
  final String teacherId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final int mobileNumber;
  final String? department;
  final String? profilePicture;
  final String? profilePictureId;
  final List<Subject> subjects;
  final List<TeacherScope> scope;
  final String? createdAt;

  Teacher({
    required this.id,
    required this.teacherId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.department,
    this.profilePicture,
    this.profilePictureId,
    required this.subjects,
    this.scope = const [],
    this.createdAt,
    this.totalSessions,
    this.cancellationRate,
    this.exceptionRate,
    this.lowAttendanceRate,
    this.swapRate,
    this.score,
    this.name,
  });

  final int? totalSessions;
  final double? cancellationRate;
  final double? exceptionRate;
  final double? lowAttendanceRate;
  final double? swapRate;
  final double? score;
  final String? name; // For defaulter response which provides a single name string

  factory Teacher.fromJson(Map<String, dynamic> json) {
    // If only 'name' is provided (defaulter response), try to split it
    String fName = json['first_name'] ?? '';
    String lName = json['last_name'] ?? '';
    if (fName.isEmpty && json['name'] != null) {
      final parts = (json['name'] as String).split(' ');
      fName = parts.isNotEmpty ? parts[0] : '';
      lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return Teacher(
      id: json['_id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      firstName: fName,
      middleName: json['middle_name'],
      lastName: lName,
      email: json['email'] ?? '',
      mobileNumber: json['mobile_number'] ?? 0,
      department: json['department'],
      profilePicture: json['profile_picture'],
      profilePictureId: json['profile_picture_id'],
      subjects:
          (json['subjects'] as List<dynamic>?)
              ?.map((subject) => Subject.fromJson(subject))
              .toList() ??
          (json['subjects_assigned'] as List<dynamic>?)
              ?.map((subject) => Subject.fromJson(subject))
              .toList() ??
          [],
      scope:
          (json['scope'] as List<dynamic>?)
              ?.map((s) => TeacherScope.fromJson(s))
              .toList() ??
          [],
      createdAt: json['created_at'],
      totalSessions: json['total_sessions'],
      cancellationRate: json['cancellation_rate']?.toDouble(),
      exceptionRate: json['exception_rate']?.toDouble(),
      lowAttendanceRate: json['low_attendance_rate']?.toDouble(),
      swapRate: json['swap_rate']?.toDouble(),
      score: json['score']?.toDouble(),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teacher_id': teacherId,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'mobile_number': mobileNumber,
      'department': department,
      'profile_picture': profilePicture,
      'profile_picture_id': profilePictureId,
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'scope': scope.map((s) => s.toJson()).toList(),
      'created_at': createdAt,
      'total_sessions': totalSessions,
      'cancellation_rate': cancellationRate,
      'exception_rate': exceptionRate,
      'low_attendance_rate': lowAttendanceRate,
      'swap_rate': swapRate,
      'score': score,
      'name': name,
    };
  }
}

class Subject {
  final String? subjectId;
  final String subjectCode;
  final String subjectName;
  final String component;
  final String? program;
  final String? department;
  final int? semester;

  Subject({
    this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.component,
    this.program,
    this.department,
    this.semester,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'],
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      component: json['component'] ?? '',
      program: json['program'],
      department: json['department'],
      semester: json['semester'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'component': component,
      'program': program,
      'department': department,
      'semester': semester,
    };
  }
}
