import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/core/theme/app_colors.dart';
import 'package:sanlo/core/widgets/image_placeholder.dart';
import 'package:sanlo/core/widgets/primary_button.dart';
import 'package:sanlo/core/widgets/product_card.dart';
import 'package:sanlo/core/widgets/status_badge.dart';
import 'package:sanlo/core/widgets/step_indicator.dart';
import 'package:sanlo/features/catalog/domain/entities/category.dart';
import 'package:sanlo/features/catalog/domain/entities/product.dart';
import 'package:sanlo/features/orders/domain/entities/order_status.dart';

/// Pumps [child] wrapped in a minimal MaterialApp/Scaffold harness.
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('PrimaryButton', () {
    testWidgets('renders label and fires onPressed', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      await _pump(
        tester,
        PrimaryButton(label: 'Order now', onPressed: () => tapped = true),
      );

      expect(find.text('Order now'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      expect(tapped, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const PrimaryButton(label: 'Disabled', onPressed: null),
      );

      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows a spinner and disables while loading', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        PrimaryButton(label: 'Saving', onPressed: () {}, loading: true),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saving'), findsNothing);
      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('renders a leading icon when provided', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        PrimaryButton(
          label: 'Call the shop',
          onPressed: () {},
          icon: Icons.call,
        ),
      );

      expect(find.byIcon(Icons.call), findsOneWidget);
      expect(find.text('Call the shop'), findsOneWidget);
    });
  });

  group('StatusBadge', () {
    testWidgets('maps each OrderStatus to its label', (
      WidgetTester tester,
    ) async {
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

    testWidgets('uses the status palette for its background', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const StatusBadge(status: OrderStatus.ready));

      final Container container = tester.widget(find.byType(Container));
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.statusReadyBg);
    });

    testWidgets('text constructor renders arbitrary labels', (
      WidgetTester tester,
    ) async {
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
        const StepIndicator(
          currentStep: 2,
          totalSteps: 4,
          label: 'Measurements',
        ),
      );

      expect(find.text('Step 2 of 4 · Measurements'), findsOneWidget);
      // One Expanded per segment.
      expect(find.byType(Expanded), findsNWidgets(4));
    });
  });

  group('ImagePlaceholder', () {
    testWidgets('renders fallback icon and caption when imageUrl is null', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const ImagePlaceholder(
          caption: '[Photo 1 of 4]',
          icon: Icons.checkroom,
        ),
      );

      expect(find.byIcon(Icons.checkroom), findsOneWidget);
      expect(find.text('[Photo 1 of 4]'), findsOneWidget);
    });

    testWidgets('renders Image.network when imageUrl is provided', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const ImagePlaceholder(imageUrl: 'https://example.com/image.jpg'),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('ProductCard', () {
    testWidgets('renders product details and triggers onTap when clicked', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      const product = Product(
        id: 'p_1',
        category: CategoryKind.women,
        name: 'Designer Blouse',
        typeLabel: 'Blouse',
        rating: 4.8,
        readyInDays: 5,
        priceInr: 650,
        imageCount: 1,
        imageUrls: ['https://example.com/blouse.jpg'],
      );

      await _pump(
        tester,
        ProductCard(product: product, onTap: () => tapped = true),
      );

      expect(find.text('Designer Blouse'), findsOneWidget);
      expect(find.text('₹650'), findsOneWidget);
      expect(find.byType(ImagePlaceholder), findsOneWidget);

      await tester.tap(find.byType(ProductCard));
      expect(tapped, isTrue);
    });
  });
}
