import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:markmeapp/data/repositories/auth_repository.dart';
import 'package:markmeapp/data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  String? get token => _userData?['access_token'];
  bool get isLoggedIn => token != null;
  String? get userRole => _userData?['role'];

  void clearError() {
    print('🔵 [AuthProvider] clearError called');
    _errorMessage = null;
    notifyListeners();
  }

  /// Save user data - FIXED TYPE CASTING
  Future<void> _saveUserData(dynamic data) async {
    print('🔵 [AuthProvider] _saveUserData called with data: $data');
    print('🔵 [AuthProvider] Data type: ${data.runtimeType}');
    
    try {
      // Convert to Map<String, dynamic>
      Map<String, dynamic> userData;
      if (data is Map<String, dynamic>) {
        userData = data;
      } else if (data is Map) {
        userData = data.cast<String, dynamic>();
      } else {
        throw Exception('Invalid data type for user data: ${data.runtimeType}');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(userData));
      _userData = userData;
      print('🟢 [AuthProvider] User data saved successfully: $_userData');
      notifyListeners();
    } catch (e) {
      print('🔴 [AuthProvider] Error saving user data: $e');
      rethrow;
    }
  }

  /// Load on app start
  Future<void> loadUserData() async {
    print('🔵 [AuthProvider] loadUserData called');
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('userData');
    if (stored != null) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          _userData = decoded;
        } else if (decoded is Map) {
          _userData = decoded.cast<String, dynamic>();
        }
        print('🟢 [AuthProvider] Loaded user data from storage: $_userData');
        notifyListeners();
      } catch (e) {
        print('🔴 [AuthProvider] Failed to decode stored user data: $e');
        await clearUserData();
      }
    } else {
      print('🔵 [AuthProvider] No stored user data found');
    }
  }

  /// Clear on logout
  Future<void> clearUserData() async {
    print('🔵 [AuthProvider] clearUserData called');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    _userData = null;
    notifyListeners();
  }

  /// Login - FIXED NAVIGATION
  Future<void> loginUser(User user, String role, BuildContext context) async {
    print('🔵 [AuthProvider] loginUser called with email: ${user.email}, role: $role');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.loginUser(user, role);
      print('🔵 [AuthProvider] Login result: $result');

      if (result['success'] == true) {
        final data = result['data'];
        print('🟢 [AuthProvider] Login successful, saving user data');
        await _saveUserData(data);

        if (context.mounted) {
          print('🔵 [AuthProvider] Navigating to dashboard based on role: $role');
          
          // Add small delay to ensure UI updates
          await Future.delayed(const Duration(milliseconds: 50));
          
          if (role == 'teacher') {
            print('🔵 [AuthProvider] Navigating to /teacher');
            context.go('/teacher');
          } else if (role == 'admin') {
            print('🔵 [AuthProvider] Navigating to /admin-dashboard');
            context.go('/admin-dashboard');
          } else {
            print('🔵 [AuthProvider] Navigating to /student');
            context.go('/student');
          }
        }
      } else {
        _errorMessage = result['error'] ?? 'Login failed';
        print('🔴 [AuthProvider] Login failed: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Login error: $e';
      print('🔴 [AuthProvider] Login exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register
  Future<void> registerUser(User user, BuildContext context) async {
    print('🔵 [AuthProvider] registerUser called with email: ${user.email}');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.registerUser(user);
      print('🔵 [AuthProvider] Registration result: $result');
      
      if (result['success'] == true) {
        print('🟢 [AuthProvider] Registration successful');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login.')),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          context.go('/login');
        }
      } else {
        _errorMessage = result['error'] ?? 'Registration failed';
        print('🔴 [AuthProvider] Registration failed: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Registration error: $e';
      print('🔴 [AuthProvider] Registration exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}