import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';
import 'package:markmeapp/state/student_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final studentStoreProvider = StateNotifierProvider<StudentStore, StudentState>(
  (ref) => StudentStore(StudentRepository()),
);

class StudentStore extends StateNotifier<StudentState> {
  final StudentRepository _studentRepo;

  StudentStore(this._studentRepo) : super(const StudentState());

  /// Load student profile from API
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _studentRepo.fetchProfile();

    if (result['success'] == true) {
      state = state.copyWith(profile: result['data'], isLoading: false);
      await _saveProfileLocally(result['data']);
    } else {
      state = state.copyWith(
        errorMessage: result['error'] ?? 'Failed to load profile',
        isLoading: false,
      );
    }
  }

  /// Save profile locally for persistence
  Future<void> _saveProfileLocally(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('studentProfile', jsonEncode(profile));
  }

  /// Load profile from local storage
  Future<void> loadProfileFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('studentProfile');

    if (stored != null) {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) {
        state = state.copyWith(profile: decoded);
      }
    }
  }

  /// Clear profile (logout)
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('studentProfile');
    state = const StudentState();
  }
}
