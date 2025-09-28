import 'package:flutter/foundation.dart';

@immutable
class ClerkState {
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> teachers;
  final bool isLoading;
  final String? errorMessage;

  const ClerkState({
    this.profile,
    this.students = const [],
    this.teachers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ClerkState copyWith({
    Map<String, dynamic>? profile,
    List<Map<String, dynamic>>? students,
    List<Map<String, dynamic>>? teachers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClerkState(
      profile: profile ?? this.profile,
      students: students ?? this.students,
      teachers: teachers ?? this.teachers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'ClerkState(profile: $profile, students: ${students.length}, teachers: ${teachers.length}, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}
