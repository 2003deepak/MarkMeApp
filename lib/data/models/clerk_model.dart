class Clerk {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String phone;
  final String department;
  final String program;
  final String? profilePicture;
  final String? profilePictureId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Clerk({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.department,
    required this.program,
    this.profilePicture,
    this.profilePictureId,
    this.createdAt,
    this.updatedAt,
  });

  factory Clerk.fromJson(Map<String, dynamic> json) {
    return Clerk(
      id: json['clerk_id'] ?? '',
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: (json['phone'] ?? '').toString(),
      department: json['department'] ?? '',
      program: json['program'] ?? '',
      profilePicture: json['profile_picture'],
      profilePictureId: json['profile_picture_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clerk_id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'department': department,
      'program': program,
      'profile_picture': profilePicture,
      'profile_picture_id': profilePictureId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
