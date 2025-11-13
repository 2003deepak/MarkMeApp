class User {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? fcmToken;
  final String? deviceType;

  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.fcmToken,
    this.deviceType,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
    };
  }
}
