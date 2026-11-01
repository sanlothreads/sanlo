import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/core/widgets/product_card.dart';
import 'package:sanlo/features/catalog/data/repositories/mock_product_repository.dart';
import 'package:sanlo/features/catalog/domain/entities/category.dart';
import 'package:sanlo/features/catalog/domain/entities/product.dart';
import 'package:sanlo/features/catalog/domain/repositories/product_repository.dart';
import 'package:sanlo/features/catalog/presentation/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen compiles semantics without parentData dirty errors',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      RepositoryProvider<ProductRepository>(
        create: (_) => MockProductRepository(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('What shall we stitch?'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('ProductCard renders without overflow in constrained grid card bounds',
      (WidgetTester tester) async {
    const Product sample = Product(
      id: 'p_test',
      category: CategoryKind.women,
      name: 'Designer Blouse with Extra Long Name',
      typeLabel: 'Blouse',
      rating: 4.8,
      readyInDays: 5,
      priceInr: 650,
      imageCount: 4,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 250,
              child: ProductCard(
                product: sample,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Designer Blouse with Extra Long Name'), findsOneWidget);
    expect(find.text('₹650'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
