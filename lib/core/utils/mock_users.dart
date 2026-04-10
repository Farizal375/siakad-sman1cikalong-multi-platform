// File: lib/core/utils/mock_users.dart
// ===========================================
// MOCK USERS - Development Authentication
// Translated from src/app/data/mockUsers.ts
// ===========================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

final List<User> mockUsers = const [
  User(
    id: '1',
    email: 'admin@sman1cikalong.sch.id',
    password: 'admin123',
    name: 'Administrator',
    role: UserRole.admin,
  ),
  User(
    id: '2',
    email: 'kurikulum@sman1cikalong.sch.id',
    password: 'kurikulum123',
    name: 'Curriculum Manager',
    role: UserRole.curriculum,
  ),
  User(
    id: '3',
    email: 'guru@sman1cikalong.sch.id',
    password: 'guru123',
    name: 'Dra. Siti Aminah',
    role: UserRole.teacher,
  ),
  User(
    id: '4',
    email: 'siswa@sman1cikalong.sch.id',
    password: 'siswa123',
    name: 'Ahmad Fauzi',
    role: UserRole.student,
  ),
];

/// Authenticate user with email and password
User? authenticateUser(String email, String password) {
  try {
    return mockUsers.firstWhere(
      (u) => u.email == email && u.password == password,
    );
  } catch (_) {
    return null;
  }
}

/// Get currently logged-in user from SharedPreferences
Future<User?> getCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userStr = prefs.getString('currentUser');
  if (userStr != null) {
    return User.fromJson(jsonDecode(userStr));
  }
  return null;
}

/// Save current user to SharedPreferences
Future<void> setCurrentUser(User user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('currentUser', jsonEncode(user.toJson()));
}

/// Clear current user from SharedPreferences (logout)
Future<void> clearCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('currentUser');
}
