// Basic smoke test for SIAKAD app
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siakad_app/main_web.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SiakadWebApp()),
    );
    // Verify the app renders
    expect(find.byType(SiakadWebApp), findsOneWidget);
  });
}
