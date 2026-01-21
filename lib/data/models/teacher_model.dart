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
  final List<Subject> subjectsAssigned;

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
    required this.subjectsAssigned,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['_id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobile_number'] ?? 0,
      department: json['department'],
      profilePicture: json['profile_picture'],
      profilePictureId: json['profile_picture_id'],
      subjectsAssigned:
          (json['subjects_assigned'] as List<dynamic>?)
              ?.map((subject) => Subject.fromJson(subject))
              .toList() ??
          [],
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
      'subjects_assigned': subjectsAssigned.map((s) => s.toJson()).toList(),
    };
  }
}

class Subject {
  final String subjectCode;
  final String subjectName;
  final String component;

  Subject({
    required this.subjectCode,
    required this.subjectName,
    required this.component,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      component: json['component'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'component': component,
    };
  }
}
