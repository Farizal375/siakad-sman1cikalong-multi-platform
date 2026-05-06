// File: lib/core/providers/auth_provider.dart
// ===========================================
// AUTH STATE PROVIDER (Riverpod)
// Connected to real backend API
// ===========================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../config/supabase_config.dart';
import '../models/user.dart';
import '../network/api_client.dart';
import '../network/api_service.dart';

/// Notifier that manages authentication state
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    if (!SupabaseConfig.isConfigured) {
      return _restoreLegacySession();
    }

    final subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final session = data.session;
        if (session == null) {
          await _clearSession();
          state = const AsyncValue.data(null);
          return;
        }

        state = const AsyncValue.loading();
        try {
          final user = await _loadUserFromBackend(session);
          state = AsyncValue.data(user);
        } catch (error, stackTrace) {
          await _clearSession();
          state = AsyncValue.error(error, stackTrace);
        }
      },
    );
    ref.onDispose(() => subscription.cancel());

    return _restoreSupabaseSession();
  }

  Future<User?> _restoreLegacySession() async {
    final token = await ApiClient.getToken();
    if (token == null) {
      await _clearSession();
      return null;
    }

    try {
      final response = await ApiService.getMe();
      final userData = response['data'];
      final user = User.fromJson(userData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user.toJson()));

      return user;
    } catch (_) {
      await _clearSession();
      return null;
    }
  }

  Future<User?> _restoreSupabaseSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      await _clearSession();
      return null;
    }

    try {
      return await _loadUserFromBackend(session);
    } catch (_) {
      await _clearSession();
      return null;
    }
  }

  Future<User> _loadUserFromBackend(Session session) async {
    final response = await ApiService.getMe();
    final userData = response['data'];
    final user = User.fromJson(userData);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', jsonEncode(user.toJson()));

    return user;
  }

  Future<User?> refreshSession() async {
    state = const AsyncValue.loading();
    final user = await _restoreSupabaseSession();
    state = AsyncValue.data(user);
    return user;
  }

  /// Login with school SSO through Supabase Auth.
  Future<bool> loginWithSso() async {
    if (!SupabaseConfig.isConfigured) {
      state = const AsyncValue.data(null);
      return false;
    }

    state = const AsyncValue.loading();
    try {
      await _clearSession();
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      await Supabase.instance.client.auth.signInWithOAuth(
        SupabaseConfig.provider,
        redirectTo: SupabaseConfig.effectiveRedirectUrl,
        queryParams: const {'prompt': 'select_account', 'max_age': '0'},
      );

      state = AsyncValue.data(state.valueOrNull);
      return true;
    } catch (_) {
      state = const AsyncValue.data(null);
      return false;
    }
  }

  /// Dev/local password login through the backend fallback endpoint.
  Future<bool> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiService.login(identifier, password);

      final token = response['token'] as String;
      await ApiClient.saveToken(token);

      final userData = response['user'];
      final user = User.fromJson(userData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user.toJson()));

      state = AsyncValue.data(user);
      return true;
    } catch (_) {
      state = const AsyncValue.data(null);
      return false;
    }
  }

  /// Logout — clear token and user data
  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      // Logout must still clear the local Supabase/client session.
    }

    try {
      if (SupabaseConfig.isConfigured) {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
      }
    } catch (_) {
      // Keep logout resilient when Supabase is not initialized in tests.
    }

    await _clearSession();
    state = const AsyncValue.data(null);
  }

  /// Update nama user setelah edit profil — sinkronisasi state + SharedPreferences
  Future<void> updateUserName(String newName) async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;

    // Buat user baru dengan nama yang diperbarui
    final updatedUser = User(
      id: currentUser.id,
      email: currentUser.email,
      password: currentUser.password,
      name: newName,
      role: currentUser.role,
      avatar: currentUser.avatar,
    );

    // Simpan ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', jsonEncode(updatedUser.toJson()));

    // Update state Riverpod
    state = AsyncValue.data(updatedUser);
  }

  Future<void> updateUserAvatar(String? avatarUrl) async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;

    final updatedUser = User(
      id: currentUser.id,
      email: currentUser.email,
      password: currentUser.password,
      name: currentUser.name,
      role: currentUser.role,
      avatar: avatarUrl,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', jsonEncode(updatedUser.toJson()));

    state = AsyncValue.data(updatedUser);
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

String getDashboardRouteByRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return '/dashboard';
    case UserRole.curriculum:
      return '/curriculum/dashboard';
    case UserRole.teacher:
      return '/guru/dashboard';
    case UserRole.student:
      return '/siswa/dashboard';
  }
}
