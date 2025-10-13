import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';
import 'package:markmeapp/state/clerk_state.dart';

class ClerkStore extends StateNotifier<ClerkState> {
  final ClerkRepository _repository;

  ClerkStore(this._repository) : super(const ClerkState());

  Future<void> loadProfile(String clerkId) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.fetchProfile(clerkId);
    if (result['success']) {
      state = state.copyWith(profile: result['data'], isLoading: false);
    } else {
      state = state.copyWith(errorMessage: result['error'], isLoading: false);
    }
  }

  Future<void> loadStudents() async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.getStudents();
    if (result['success']) {
      state = state.copyWith(
        students: List<Map<String, dynamic>>.from(result['data']),
        isLoading: false,
      );
    } else {
      state = state.copyWith(errorMessage: result['error'], isLoading: false);
    }
  }

  Future<void> loadTeachers() async {
    // state = state.copyWith(isLoading: true);
    // final result = await _repository.getTeachers();
    // if (result['success']) {
    //   state = state.copyWith(teachers: List<Map<String, dynamic>>.from(result['data']), isLoading: false);
    // } else {
    //   state = state.copyWith(errorMessage: result['error'], isLoading: false);
    // }
  }

  Future<void> addTeacher(Map<String, dynamic> teacher) async {
    // state = state.copyWith(isLoading: true);
    // final result = await _repository.createTeacher(teacher);
    // if (result['success']) {
    //   final updated = [...state.teachers, result['data']];
    //   state = state.copyWith(teachers: updated, isLoading: false);
    // } else {
    //   state = state.copyWith(errorMessage: result['error'], isLoading: false);
    // }
  }
}

// Providers
final clerkRepositoryProvider = Provider<ClerkRepository>((ref) {
  return ClerkRepository();
});

final clerkStoreProvider = StateNotifierProvider<ClerkStore, ClerkState>((ref) {
  final repo = ref.read(clerkRepositoryProvider);
  return ClerkStore(repo);
});

final clerkProfileProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(clerkStoreProvider).profile;
});

final clerkStudentsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(clerkStoreProvider).students;
});

final clerkTeachersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(clerkStoreProvider).teachers;
});

final clerkLoadingProvider = Provider<bool>((ref) {
  return ref.watch(clerkStoreProvider).isLoading;
});

final clerkErrorProvider = Provider<String?>((ref) {
  return ref.watch(clerkStoreProvider).errorMessage;
});
