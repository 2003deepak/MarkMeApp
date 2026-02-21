class LiveSession {
  final String sessionId;
  final String subjectName;
  final String teacherName;
  final int presentStudents;
  final int totalStudents;
  final String sessionType;
  final String room; // Placeholder or derived

  LiveSession({
    required this.sessionId,
    required this.subjectName,
    required this.teacherName,
    required this.presentStudents,
    required this.totalStudents,
    required this.sessionType,
    this.room = "Classroom", // Default value
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      sessionId: json['session_id'] ?? '',
      subjectName: json['subject_name'] ?? 'Unknown Subject',
      teacherName: json['teacher_name'] ?? 'Unknown Teacher',
      presentStudents: json['present_students'] ?? 0,
      totalStudents: json['total_students'] ?? 0,
      sessionType: json['session_type'] ?? 'Lecture',
      room: json['room'] ?? "Room 304", // Use placeholder if not in API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'subject_name': subjectName,
      'teacher_name': teacherName,
      'present_students': presentStudents,
      'total_students': totalStudents,
      'session_type': sessionType,
      'room': room,
    };
  }

  bool get isLab => sessionType.toLowerCase() == 'lab';
}
