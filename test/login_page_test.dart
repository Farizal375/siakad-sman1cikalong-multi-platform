import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siakad_app/features/auth/screens/login_page.dart';

void main() {
  testWidgets('login page exposes production local login', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    await tester.pumpAndSettle();

    expect(find.text('Login dengan Akun Sekolah'), findsNothing);
    expect(find.text('Email / Username / Nomor Induk'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Lupa password?'), findsNothing);
    expect(find.text('Lupa password? Hubungi admin sekolah.'), findsOneWidget);
    expect(find.textContaining('Akun Demo'), findsNothing);
    expect(find.textContaining('Daftar'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
