class TeacherLeaderboardResponse {
  final bool success;
  final String period;
  final String? startDate;
  final String? endDate;
  final List<LeaderboardEntry> data;

  TeacherLeaderboardResponse({
    required this.success,
    required this.period,
    this.startDate,
    this.endDate,
    required this.data,
  });

  factory TeacherLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return TeacherLeaderboardResponse(
      success: json['success'] ?? false,
      period: json['period'] ?? '',
      startDate: json['start_date'],
      endDate: json['end_date'],
      data: (json['data'] as List? ?? [])
          .map((item) => LeaderboardEntry.fromJson(item))
          .toList(),
    );
  }
}

class LeaderboardEntry {
  final String teacherId;
  final String name;
  final String department;
  final String? profilePicture;
  final double score;
  final double attendanceRate;
  final int rank;
  final String? badge;

  LeaderboardEntry({
    required this.teacherId,
    required this.name,
    required this.department,
    this.profilePicture,
    required this.score,
    required this.attendanceRate,
    required this.rank,
    this.badge,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      teacherId: json['teacher_id'] ?? '',
      name: json['name'] ?? '',
      department: json['department'] ?? '',
      profilePicture: json['profile_picture'],
      score: (json['score'] ?? 0.0).toDouble(),
      attendanceRate: (json['attendance_rate'] ?? 0.0).toDouble(),
      rank: json['rank'] ?? 0,
      badge: json['badge'],
    );
  }
}
