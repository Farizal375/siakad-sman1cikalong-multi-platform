import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siakad_app/main_web.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SIAKAD E2E Tests', () {
    testWidgets('Login, navigasi ke Dashboard, dan tes Form utama', (tester) async {
      // Build the app
      app.main();
      await tester.pumpAndSettle();

      // Ensure we are on the login page (check for 'Masuk ke Akun')
      expect(find.text('Masuk ke Akun'), findsOneWidget);

      // Find email and password fields
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.text('Masuk');

      // Enter credentials
      await tester.enterText(emailField, 'admin@siakad.sch.id');
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Tap login
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // After login, we should see Dashboard Admin or similar dashboard text
      // We expect 'Beranda' or 'Dashboard' depending on the layout
      expect(find.text('Beranda'), findsWidgets);

      // Open a form/menu if applicable (e.g., Data Master)
      // We search for a generic icon or text representing a major menu
      final menuMaster = find.text('Data Master');
      if (menuMaster.evaluate().isNotEmpty) {
        await tester.tap(menuMaster.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        // Find "Tambah" button to simulate form interaction
        final tambahButton = find.text('Tambah');
        if (tambahButton.evaluate().isNotEmpty) {
          await tester.tap(tambahButton.first);
          await tester.pumpAndSettle();
          
          // Verify a form dialog or page opened
          expect(find.text('Simpan'), findsWidgets);
        }
      }
    });
  });
}
