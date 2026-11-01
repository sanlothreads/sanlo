import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/app.dart';

void main() {
  testWidgets('SanloApp compiles semantics without parentData dirty errors on startup and tab switches',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(const SanloApp());
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
