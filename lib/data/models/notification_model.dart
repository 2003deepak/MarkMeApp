import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 0)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  bool isRead;

  @HiveField(5)
  final String? type;

  @HiveField(6)
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type,
    this.data,
  });
}

class AppNotification {
  final String user;
  final String title;
  final String message;
  final List<String>? targetIds;
  final List<NotificationFilter>? filters;

  AppNotification({
    required this.user,
    required this.title,
    required this.message,
    this.targetIds,
    this.filters,
  });
}

class NotificationFilter {
  final String? dept;
  final String? program;
  final int? semester;
  final int? batchYear;

  NotificationFilter({this.dept, this.program, this.semester, this.batchYear});
}
