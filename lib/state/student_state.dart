import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';

/// StudentState - Simple state container
@immutable
class StudentState {
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isUpdating;

  const StudentState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isUpdating = false,
  });

  StudentState copyWith({
    Map<String, dynamic>? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isUpdating,
  }) {
    return StudentState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  String toString() {
    return 'StudentState(profile: $profile, isLoading: $isLoading, isUpdating: $isUpdating, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StudentState &&
        mapEquals(other.profile, profile) &&
        other.isLoading == isLoading &&
        other.isUpdating == isUpdating &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      profile?.hashCode ?? 0,
      isLoading,
      isUpdating,
      errorMessage,
    );
  }
}

/// StudentStore - Combined state management and repository interactions
class StudentStore extends StateNotifier<StudentState> {
  final StudentRepository _studentRepo;

  StudentStore(this._studentRepo) : super(const StudentState());

  // Getters for convenient access to state properties
  Map<String, dynamic>? get profile => state.profile;
  bool get isLoading => state.isLoading;
  bool get isUpdating => state.isUpdating;
  String? get errorMessage => state.errorMessage;

  /// Load student profile from API
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _studentRepo.fetchProfile();

      if (result['success'] == true) {
        state = state.copyWith(
          profile: result['data'],
          isLoading: false,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          errorMessage: result['error'] ?? 'Failed to load profile',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Network error: Failed to load profile',
        isLoading: false,
      );
    }
  }

  /// Update student profile
  // Future<void> updateProfile(Map<String, dynamic> profileData) async {
  //   state = state.copyWith(isUpdating: true, errorMessage: null);

  //   try {
  //     final result = await _studentRepo.updateProfile(profileData);

  //     if (result['success'] == true) {
  //       state = state.copyWith(
  //         profile: result['data'],
  //         isUpdating: false,
  //         errorMessage: null,
  //       );
  //     } else {
  //       state = state.copyWith(
  //         errorMessage: result['error'] ?? 'Failed to update profile',
  //         isUpdating: false,
  //       );
  //     }
  //   } catch (e) {
  //     state = state.copyWith(
  //       errorMessage: 'Network error: Failed to update profile',
  //       isUpdating: false,
  //     );
  //   }
  // }

  /// Clear any error messages
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Reset the entire state
  void reset() {
    state = const StudentState();
  }

  /// Refresh profile data
  Future<void> refreshProfile() async {
    await loadProfile();
  }

  /// Update specific profile field
  // Future<void> updateProfileField(String key, dynamic value) async {
  //   final currentProfile = state.profile ?? {};
  //   final updatedProfile = Map<String, dynamic>.from(currentProfile);
  //   updatedProfile[key] = value;

  //   // await updateProfile(updatedProfile);
  // }
}

// Provider for StudentStore
final studentStoreProvider = StateNotifierProvider<StudentStore, StudentState>((
  ref,
) {
  final studentRepository = ref.watch(studentRepositoryProvider);
  return StudentStore(studentRepository);
});
