import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';
import 'package:markmeapp/stores/auth_store.dart';
import 'package:markmeapp/state/auth_state.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Main AuthStore provider
final authStoreProvider = StateNotifierProvider<AuthStore, AuthState>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return AuthStore(authRepository);
});

// Convenience providers for specific state properties
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStoreProvider).isLoggedIn;
});

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(authStoreProvider).role;
});

final userDataProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authStoreProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStoreProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStoreProvider).errorMessage;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authStoreProvider).token;
});