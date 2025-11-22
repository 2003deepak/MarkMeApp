class AppNotification {
  final String user;
  final String title;
  final String dept;
  final String program;
  final String message;

  AppNotification({
    required this.user,
    required this.title,
    required this.dept,
    required this.program,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      "user": user,
      "title": title,
      "dept": dept,
      "program": program,
      "message": message,
    };
  }
}
