// Smoke test for the Sanlo app root widget.
//
// Pumps [SanloApp] and confirms it builds without throwing. The default
// counter app this file used to test was removed when `main.dart` was wired to
// run the real app.

import 'package:flutter_test/flutter_test.dart';

import 'package:sanlo/app.dart';
import 'package:sanlo/core/di/service_locator.dart';
import 'package:sanlo/features/auth/data/repositories/mock_auth_repository.dart';

void main() {
  testWidgets('SanloApp builds without error', (WidgetTester tester) async {
    // Inject mock auth so the test runs without a live Firebase.
    await tester.pumpWidget(
      SanloApp(locator: ServiceLocator(authRepository: MockAuthRepository())),
    );
    // The app opens on the splash screen, which schedules a 2s timer before
    // navigating. Advance past it and settle so no timer is left pending.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(SanloApp), findsOneWidget);
  });
}
