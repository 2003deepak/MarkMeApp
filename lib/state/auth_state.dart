import 'package:flutter/foundation.dart';

@immutable
class AuthState {
  final bool isLoggedIn;
  final String? role;
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.role,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  String? get token => user?['access_token'];

  AuthState copyWith({
    bool? isLoggedIn,
    String? role,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: role ?? this.role,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'AuthState(isLoggedIn: $isLoggedIn, role: $role, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}
