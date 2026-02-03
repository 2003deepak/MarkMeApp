import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/models/admin_model.dart';
import 'package:markmeapp/data/repositories/admin_repository.dart';

@immutable
class AdminState {
  final Admin? profile;
  final bool isLoading;
  final String? errorMessage;

  const AdminState({this.profile, this.isLoading = false, this.errorMessage});

  AdminState copyWith({
    Admin? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AdminState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'AdminState(profile: $profile, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

class AdminStore extends StateNotifier<AdminState> {
  final AdminRepository _adminRepo;

  AdminStore(this._adminRepo) : super(const AdminState());

  Future<Map<String, dynamic>> loadProfile() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await _adminRepo.fetchProfile();

      if (result['success'] == true) {
        final adminProfile = Admin.fromJson(result['data']);
        state = state.copyWith(
          profile: adminProfile,
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

  Future<Map<String, dynamic>> updateProfile(FormData adminProfile) async {
    try {
      state = state.copyWith(errorMessage: null);

      final result = await _adminRepo.updateProfile(adminProfile);

      if (result['success'] == true) {
        // Refresh profile from server
        await loadProfile();
        
        return {"success": true, "message": result['message'] ?? "Profile updated"};
      }

      state = state.copyWith(errorMessage: result['error']);
      return {"success": false, "message": result['error']};
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return {"success": false, "message": "Error: $e"};
    }
  }
}

final adminStoreProvider = StateNotifierProvider<AdminStore, AdminState>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminStore(repo);
});
