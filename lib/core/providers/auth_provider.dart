// File: lib/core/providers/auth_provider.dart
// ===========================================
// AUTH STATE PROVIDER (Riverpod)
// Global auth state management
// ===========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../utils/mock_users.dart' as mock;

/// Notifier that manages authentication state
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return await mock.getCurrentUser();
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    final user = mock.authenticateUser(email, password);
    if (user != null) {
      await mock.setCurrentUser(user);
      state = AsyncValue.data(user);
      return true;
    }
    state = const AsyncValue.data(null);
    return false;
  }

  /// Login with a specific user (e.g., Google SSO simulation)
  Future<void> loginAsUser(User user) async {
    await mock.setCurrentUser(user);
    state = AsyncValue.data(user);
  }

  /// Logout
  Future<void> logout() async {
    await mock.clearCurrentUser();
    state = const AsyncValue.data(null);
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
