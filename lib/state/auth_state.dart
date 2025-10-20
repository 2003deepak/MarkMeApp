import 'package:flutter/foundation.dart';

@immutable
class AuthState {
  final bool isLoggedIn;
  final String? role;
  final String? access_token; 
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? errorMessage;
  final bool hasLoaded; 

  const AuthState({
    this.isLoggedIn = false,
    this.role,
    this.access_token,
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.hasLoaded = false, 
  });

  String? get token => access_token;

  AuthState copyWith({
    bool? isLoggedIn,
    String? role,
    String? access_token,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? errorMessage,
    bool? hasLoaded, 
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: role ?? this.role,
      access_token: access_token ?? this.access_token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      hasLoaded: hasLoaded ?? this.hasLoaded, 
    );
  }

  @override
  String toString() {
    return 'AuthState(isLoggedIn: $isLoggedIn, role: $role, hasLoaded: $hasLoaded, isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}