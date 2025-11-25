class User {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? fcmToken;
  final String? deviceType;
  final String? deviceInfo;

  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.fcmToken,
    this.deviceType,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson(String role) {
    return {
      "email": email,
      "password": password,
      "role": role,
      "fcm_token": fcmToken,
      "device_type": deviceType,
      "device_info": deviceInfo,
    };
  }
}
