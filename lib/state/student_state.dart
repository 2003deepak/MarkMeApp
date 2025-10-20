import 'package:flutter/foundation.dart';

@immutable
class StudentState {
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String? errorMessage;

  const StudentState({this.profile, this.isLoading = false, this.errorMessage});

  StudentState copyWith({
    Map<String, dynamic>? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StudentState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'StudentState(profile: $profile, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}
