import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/clerk_repository.dart';

@immutable
class ClerkState {
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String? errorMessage;

  const ClerkState({this.profile, this.isLoading = false, this.errorMessage});

  ClerkState copyWith({
    Map<String, dynamic>? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClerkState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'ClerkState(profile: $profile, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

class ClerkStore extends StateNotifier<ClerkState> {
  final ClerkRepository _clerkRepo;

  ClerkStore(this._clerkRepo) : super(const ClerkState());

  Future<Map<String, dynamic>> loadProfile() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await _clerkRepo.fetchProfile();

      if (result['success'] == true) {
        state = state.copyWith(
          profile: result['data'],
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
}

final clerkStoreProvider = StateNotifierProvider<ClerkStore, ClerkState>((ref) {
  final repo = ref.watch(clerkRepositoryProvider);
  return ClerkStore(repo);
});
