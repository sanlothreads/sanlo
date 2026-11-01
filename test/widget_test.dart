// Smoke test for the Sanlo app root widget.
//
// Pumps [SanloApp] and confirms it builds without throwing. The default
// counter app this file used to test was removed when `main.dart` was wired to
// run the real app.

import 'package:flutter_test/flutter_test.dart';

import 'package:sanlo/app.dart';

void main() {
  testWidgets('SanloApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const SanloApp());
    // pump once more to settle the initial frame of the router's first route.
    await tester.pump();

    expect(find.byType(SanloApp), findsOneWidget);
  });
}
