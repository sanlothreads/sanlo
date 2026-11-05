import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/features/admin/data/repositories/mock_admin_repository.dart';
import 'package:sanlo/features/admin/domain/entities/admin_product.dart';
import 'package:sanlo/features/admin/domain/entities/order_stage.dart';
import 'package:sanlo/features/catalog/domain/entities/category.dart';
import 'package:sanlo/features/admin/presentation/cubit/admin_customers_cubit.dart';
import 'package:sanlo/features/admin/presentation/cubit/admin_orders_cubit.dart';
import 'package:sanlo/features/admin/presentation/cubit/admin_products_cubit.dart';

void main() {
  late MockAdminRepository repo;

  setUp(() => repo = MockAdminRepository());

  group('AdminOrdersCubit', () {
    test('load selects the first order by default', () async {
      final cubit = AdminOrdersCubit(repo);
      await cubit.load();
      expect(cubit.state.allOrders, isNotEmpty);
      expect(cubit.state.selectedId, cubit.state.allOrders.first.id);
    });

    test('filtering shows only the matching stage', () async {
      final cubit = AdminOrdersCubit(repo);
      await cubit.load();
      cubit.selectFilter(OrderStage.ordered);
      expect(
        cubit.state.filteredOrders.every((o) => o.stage == OrderStage.ordered),
        isTrue,
      );
      cubit.selectFilter(null);
      expect(cubit.state.filteredOrders.length, cubit.state.allOrders.length);
    });

    test('stage counts sum to the total', () async {
      final cubit = AdminOrdersCubit(repo);
      await cubit.load();
      final counts = cubit.state.stageCounts;
      final sum = counts.values.fold<int>(0, (a, b) => a + b);
      expect(sum, cubit.state.allOrders.length);
    });

    test('advanceSelected moves forward and is a no-op at allSet', () async {
      final cubit = AdminOrdersCubit(repo);
      await cubit.load();
      final before = cubit.state.selectedOrder!.stage;
      cubit.advanceSelected();
      expect(cubit.state.selectedOrder!.stage, before.next);

      // Drive to the final stage, then confirm advancing stops.
      while (cubit.state.selectedOrder!.stage.next != null) {
        cubit.advanceSelected();
      }
      final atEnd = cubit.state.selectedOrder!.stage;
      expect(atEnd, OrderStage.allSet);
      cubit.advanceSelected();
      expect(cubit.state.selectedOrder!.stage, OrderStage.allSet);
    });
  });

  group('AdminProductsCubit', () {
    test('search is case-insensitive', () async {
      final cubit = AdminProductsCubit(repo);
      await cubit.load();
      cubit.search('shirt');
      expect(cubit.state.visibleProducts, isNotEmpty);
      expect(
        cubit.state.visibleProducts
            .every((p) => p.name.toLowerCase().contains('shirt')),
        isTrue,
      );
      cubit.search('');
      expect(cubit.state.visibleProducts.length,
          cubit.state.allProducts.length);
    });

    test('upsert adds a new product and updates an existing one', () async {
      final cubit = AdminProductsCubit(repo);
      await cubit.load();
      final int initial = cubit.state.allProducts.length;

      const newProduct = AdminProduct(
        id: 'p_new',
        name: 'Test Jacket',
        category: CategoryKind.men,
        priceInr: 1200,
        stitchDays: 8,
        rating: 4.5,
        photoCount: 1,
        visibility: ProductVisibility.live,
      );
      cubit.upsertProduct(newProduct);
      expect(cubit.state.allProducts.length, initial + 1);

      final updated = newProduct.copyWith(priceInr: 1500);
      cubit.upsertProduct(updated);
      expect(cubit.state.allProducts.length, initial + 1);
      expect(
        cubit.state.allProducts.firstWhere((p) => p.id == 'p_new').priceInr,
        1500,
      );
    });
  });

  group('AdminCustomersCubit', () {
    test('search matches name or mobile, case-insensitive', () async {
      final cubit = AdminCustomersCubit(repo);
      await cubit.load();
      cubit.search('priya');
      expect(cubit.state.visibleCustomers, isNotEmpty);
      cubit.search('98765');
      expect(cubit.state.visibleCustomers, isNotEmpty);
      cubit.search('');
      expect(cubit.state.visibleCustomers.length,
          cubit.state.allCustomers.length);
    });
  });
}
