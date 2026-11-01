import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/core/theme/app_colors.dart';
import 'package:sanlo/core/widgets/primary_button.dart';
import 'package:sanlo/core/widgets/status_badge.dart';
import 'package:sanlo/core/widgets/step_indicator.dart';
import 'package:sanlo/features/orders/domain/entities/order_status.dart';

/// Pumps [child] wrapped in a minimal MaterialApp/Scaffold harness.
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('PrimaryButton', () {
    testWidgets('renders label and fires onPressed', (WidgetTester tester) async {
      var tapped = false;
      await _pump(
        tester,
        PrimaryButton(label: 'Order now', onPressed: () => tapped = true),
      );

      expect(find.text('Order now'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      expect(tapped, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (WidgetTester tester) async {
      await _pump(tester, const PrimaryButton(label: 'Disabled', onPressed: null));

      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows a spinner and disables while loading', (WidgetTester tester) async {
      await _pump(
        tester,
        PrimaryButton(label: 'Saving', onPressed: () {}, loading: true),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saving'), findsNothing);
      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('renders a leading icon when provided', (WidgetTester tester) async {
      await _pump(
        tester,
        PrimaryButton(label: 'Call the shop', onPressed: () {}, icon: Icons.call),
      );

      expect(find.byIcon(Icons.call), findsOneWidget);
      expect(find.text('Call the shop'), findsOneWidget);
    });
  });

  group('StatusBadge', () {
    testWidgets('maps each OrderStatus to its label', (WidgetTester tester) async {
      await _pump(
        tester,
        const Column(
          children: <Widget>[
            StatusBadge(status: OrderStatus.placed),
            StatusBadge(status: OrderStatus.inProgress),
            StatusBadge(status: OrderStatus.ready),
            StatusBadge(status: OrderStatus.completed),
          ],
        ),
      );

      expect(find.text('Ordered'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('uses the status palette for its background', (WidgetTester tester) async {
      await _pump(tester, const StatusBadge(status: OrderStatus.ready));

      final Container container = tester.widget(find.byType(Container));
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.statusReadyBg);
    });

    testWidgets('text constructor renders arbitrary labels', (WidgetTester tester) async {
      await _pump(tester, const StatusBadge.text('Stitching started'));

      expect(find.text('Stitching started'), findsOneWidget);
    });
  });

  group('StepIndicator', () {
    testWidgets('renders the step caption', (WidgetTester tester) async {
      await _pump(
        tester,
        const StepIndicator(currentStep: 1, label: 'Your details'),
      );

      expect(find.text('Step 1 of 3 · Your details'), findsOneWidget);
    });

    testWidgets('renders one segment per step', (WidgetTester tester) async {
      await _pump(
        tester,
        const StepIndicator(currentStep: 2, totalSteps: 4, label: 'Measurements'),
      );

      expect(find.text('Step 2 of 4 · Measurements'), findsOneWidget);
      // One Expanded per segment.
      expect(find.byType(Expanded), findsNWidgets(4));
    });
  });
}
