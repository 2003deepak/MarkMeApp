import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';

@immutable
class StudentState {
  final Map<String, dynamic>? profile;

  const StudentState({this.profile});

  StudentState copyWith({Map<String, dynamic>? profile}) {
    return StudentState(profile: profile ?? this.profile);
  }

  @override
  String toString() {
    return 'StudentState(profile: $profile)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StudentState && mapEquals(other.profile, profile);
  }

  @override
  int get hashCode {
    return profile?.hashCode ?? 0;
  }
}

/// StudentStore - Combined state management and repository interactions
class StudentStore extends StateNotifier<StudentState> {
  final StudentRepository _studentRepo;

  StudentStore(this._studentRepo) : super(const StudentState());

  // Getter for convenient access to state property
  Map<String, dynamic>? get profile => state.profile;

  /// Load student profile from API
  Future<Map<String, dynamic>> loadProfile() async {
    try {
      final result = await _studentRepo.fetchProfile();
      print("The result in state is $result");

      if (result['success'] == true) {
        state = state.copyWith(profile: result['data']);
        return {"success": true, "message": result["message"]};
      } else {
        // Handle API returning success: false
        return {
          "success": false,
          "message": result["message"] ?? "Failed to fetch profile",
        };
      }
    } catch (e) {
      print("Error loading profile: $e");
      return {"success": false, "message": "Error loading profile: $e"};
    }
  }

  /// Update student profile
  Future<Map<String, dynamic>> updateProfile(FormData profileData) async {
    try {
      final result = await _studentRepo.updateProfile(profileData);

      if (result['success'] == true) {
        state = state.copyWith(profile: result['data']);
      }

      return result;
    } catch (e) {
      // Handle error silently or rethrow if needed
      print("Error updating profile: $e");
      return {"success": false, "message": "Error in updating profile"};
    }
  }

  /// Reset the entire state
  void reset() {
    state = const StudentState();
  }
}

// Provider for StudentStore
final studentStoreProvider = StateNotifierProvider<StudentStore, StudentState>((
  ref,
) {
  final studentRepository = ref.watch(studentRepositoryProvider);
  return StudentStore(studentRepository);
});
