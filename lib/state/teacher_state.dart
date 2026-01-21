import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/core/utils/app_logger.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';

@immutable
class TeacherState {
  final Map<String, dynamic>? profile;
  final String? department;
  final List<dynamic> subjects;
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
    Map<String, dynamic>? profile,
    String? department,
    List<dynamic>? subjects,
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
    return 'TeacherState(profile: $profile, department: $department, subjects: ${subjects.length}, isLoading: $isLoading, errorMessage: $errorMessage)';
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

        state = state.copyWith(
          profile: data,
          department: data['department'],
          subjects: data['subjects_assigned'] ?? [],
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
