import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:siakad_app/core/providers/auth_provider.dart';
import 'package:siakad_app/core/models/user.dart';

void main() {
  group('AuthNotifier Sync Test (Guru Role)', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('updateUserName should update state and SharedPreferences correctly', () async {
      // 1. Initial State Setup (Mock Login for Guru)
      final initialUser = User(
        id: 'user-guru-123',
        email: 'guru@siakad.com',
        password: '',
        name: 'Dra. Siti Aminah',
        role: UserRole.teacher,
      );

      // We need to bypass the build() method or let it finish.
      // Since it's an AsyncNotifier, we can manually set the state for testing.
      final notifier = container.read(authProvider.notifier);
      
      // Inject initial data
      notifier.state = AsyncValue.data(initialUser);

      // 2. Perform Update
      const newName = 'Dra. Siti Aminah, M.Pd.';
      await notifier.updateUserName(newName);

      // 3. Verify State
      final updatedState = container.read(authProvider);
      expect(updatedState.value?.name, equals(newName));
      expect(updatedState.value?.role, equals(UserRole.teacher));

      // 4. Verify SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedUserJson = prefs.getString('currentUser');
      expect(storedUserJson, isNotNull);
      
      final storedUserData = jsonDecode(storedUserJson!);
      expect(storedUserData['name'], equals(newName));
    });
  });
}
