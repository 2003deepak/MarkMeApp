class NotificationFilter {
  final String? dept;
  final String? program;
  final int? semester;
  final int? batchYear;

  NotificationFilter({this.dept, this.program, this.semester, this.batchYear});

  Map<String, dynamic> toJson() {
    return {
      if (dept != null && dept!.isNotEmpty) 'dept': dept,
      if (program != null && program!.isNotEmpty) 'program': program,
      if (semester != null) 'semester': semester,
      if (batchYear != null) 'batch_year': batchYear,
    };
  }

  factory NotificationFilter.fromJson(Map<String, dynamic> json) {
    return NotificationFilter(
      dept: json['dept'],
      program: json['program'],
      semester: json['semester'],
      batchYear: json['batch_year'],
    );
  }
}

class AppNotification {
  final String user;
  final List<String>? targetIds;
  final List<NotificationFilter>? filters;
  final String title;
  final String message;

  AppNotification({
    required this.user,
    this.targetIds,
    this.filters,
    required this.title,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user': user,
      'title': title,
      'message': message,
    };

    // Add target_ids only if provided and not empty
    if (targetIds != null && targetIds!.isNotEmpty) {
      data['target_ids'] = targetIds;
    }

    // Add filters only if provided and not empty
    if (filters != null && filters!.isNotEmpty) {
      data['filters'] = filters!.map((filter) => filter.toJson()).toList();
    }

    return data;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      user: json['user'] ?? '',
      targetIds: json['target_ids'] != null
          ? List<String>.from(json['target_ids'])
          : null,
      filters: json['filters'] != null
          ? (json['filters'] as List)
                .map((filter) => NotificationFilter.fromJson(filter))
                .toList()
          : null,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
