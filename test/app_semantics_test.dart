import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/app.dart';
import 'package:sanlo/core/di/service_locator.dart';
import 'package:sanlo/features/auth/data/repositories/mock_auth_repository.dart';

void main() {
  testWidgets(
      'SanloApp compiles semantics without parentData dirty errors on startup and tab switches',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    // Inject mock auth so 'Skip' (guest sign-in) runs without a live Firebase.
    await tester.pumpWidget(
      SanloApp(locator: ServiceLocator(authRepository: MockAuthRepository())),
    );
    // The app opens on the 2s splash screen; advance past it to reach Sign in.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Tap 'Skip' to continue as guest to Home screen
    final skipFinder = find.text('Skip');
    if (skipFinder.evaluate().isNotEmpty) {
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();
    }

    // Home tab active
    expect(find.text('What shall we stitch?'), findsOneWidget);

    // Tap My Orders tab
    await tester.tap(find.text('My orders'));
    await tester.pumpAndSettle();

    // Tap Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Tap Home tab again
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    handle.dispose();
  });
}
