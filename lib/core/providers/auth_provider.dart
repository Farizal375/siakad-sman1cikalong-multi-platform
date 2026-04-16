// File: lib/core/providers/auth_provider.dart
// ===========================================
// AUTH STATE PROVIDER (Riverpod)
// Connected to real backend API
// ===========================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../network/api_client.dart';
import '../network/api_service.dart';

/// Notifier that manages authentication state
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Try to restore session from saved user + token
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('currentUser');
    final token = await ApiClient.getToken();

    if (userStr != null && token != null) {
      try {
        // Verify token is still valid by calling /auth/me
        final response = await ApiService.getMe();
        final userData = response['data'];
        final user = User.fromJson(userData);
        // Update stored user with fresh data
        await prefs.setString('currentUser', jsonEncode(user.toJson()));
        return user;
      } catch (_) {
        // Token expired or invalid — clear session
        await _clearSession();
        return null;
      }
    }
    return null;
  }

  /// Login with email and password via backend API
  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiService.login(email, password);

      // Save JWT token
      final token = response['token'] as String;
      await ApiClient.saveToken(token);

      // Parse user from response
      final userData = response['user'];
      final user = User.fromJson(userData);

      // Save user to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user.toJson()));

      state = AsyncValue.data(user);
      return true;
    } catch (e) {
      state = const AsyncValue.data(null);
      return false;
    }
  }

  /// Logout — clear token and user data
  Future<void> logout() async {
    await _clearSession();
    state = const AsyncValue.data(null);
  }

  Future<void> _clearSession() async {
    await ApiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
  }
}

/// The global auth provider
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

/// Convenience provider for checking if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.valueOrNull != null;
});

/// Convenience provider for the current user's role
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.valueOrNull?.role;
});

/// Convenience provider for the current user's ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.valueOrNull?.id;
});
