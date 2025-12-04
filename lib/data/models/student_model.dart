class Student {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? dob;
  final String email;
  final String phone;
  final String department;
  final String program;
  final int semester;
  final int batchYear;
  final int rollNumber;
  final String? profilePicture;
  final bool isVerified;
  final bool isEmbeddings;

  Student({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.dob,
    required this.email,
    required this.phone,
    required this.department,
    required this.program,
    required this.semester,
    required this.batchYear,
    required this.rollNumber,
    this.profilePicture,
    required this.isVerified,
    required this.isEmbeddings,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? '',
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'] ?? '',
      dob: json['dob'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      department: json['department'] ?? '',
      program: json['program'] ?? '',
      semester: json['semester'] ?? 0,
      batchYear: json['batch_year'] ?? 0,
      rollNumber: json['roll_number'] ?? 0,
      profilePicture: json['profile_picture'],
      isVerified: json['is_verified'] ?? false,
      isEmbeddings: json['is_embeddings'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'dob': dob,
      'email': email,
      'phone': phone,
      'department': department,
      'program': program,
      'semester': semester,
      'batch_year': batchYear,
      'roll_number': rollNumber,
      'profile_picture': profilePicture,
      'is_verified': isVerified,
      'is_embeddings': isEmbeddings,
    };
  }
}
