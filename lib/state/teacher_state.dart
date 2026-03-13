import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/data/models/teacher_model.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';

@immutable
class TeacherState {
  final Teacher? profile;
  final String? department;
  final List<Subject> subjects;
  final bool isLoading;
  final String? errorMessage;

  const TeacherState({
    this.profile,
    this.department,
    this.subjects = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TeacherState copyWith({
    Teacher? profile,
    String? department,
    List<Subject>? subjects,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TeacherState(
      profile: profile ?? this.profile,
      department: department ?? this.department,
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'TeacherState(profile: ${profile?.firstName}, department: $department, subjects: ${subjects.length}, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

class TeacherStore extends StateNotifier<TeacherState> {
  final TeacherRepository _teacherRepo;

  TeacherStore(this._teacherRepo) : super(const TeacherState());

  Future<Map<String, dynamic>> loadProfile() async {
    try {
      AppLogger.info("Loading Teacher Profile");
      state = state.copyWith(isLoading: true);

      final result = await _teacherRepo.fetchProfile();

      if (result['success'] == true) {
        final data = result['data'];
        final teacher = Teacher.fromJson(data);

        state = state.copyWith(
          profile: teacher,
          department: teacher.department,
          subjects: teacher.subjects,
          isLoading: false,
          errorMessage: null,
        );

        return {"success": true, "message": "Profile fetched"};
      }

      state = state.copyWith(isLoading: false, errorMessage: result['error']);

      return {"success": false, "message": result['error']};
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());

      return {"success": false, "message": "Error: $e"};
    }
  }

  Future<Map<String, dynamic>> updateProfile(FormData data) async {
    try {
      AppLogger.info("Updating Teacher Profile");
      state = state.copyWith(isLoading: true);

      final result = await _teacherRepo.updateProfile(data);

      if (result['success'] == true) {
        // Reload profile to get fresh data
        await loadProfile();
        return result;
      }

      state = state.copyWith(isLoading: false, errorMessage: result['message']);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return {"success": false, "message": "Error: $e"};
    }
  }

  void clearState() {
    state = const TeacherState();
  }
}

final teacherStoreProvider = StateNotifierProvider<TeacherStore, TeacherState>((
  ref,
) {
  final repo = ref.watch(teacherRepositoryProvider);
  return TeacherStore(repo);
});
