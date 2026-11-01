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
    // pump once more to settle the initial frame of the router's first route.
    await tester.pump();

    expect(find.byType(SanloApp), findsOneWidget);
  });
}
