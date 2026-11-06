import '../../domain/entities/admin_customer.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/admin_product.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/order_stage.dart';
import '../../domain/repositories/admin_repository.dart';
import '../models/admin_customer_model.dart';
import '../models/admin_order_model.dart';
import '../models/admin_product_model.dart';

/// In-memory [AdminRepository] seeded with the sample data from the admin
/// mockups. Maps DTO models to domain entities via `toEntity()`, mirroring the
/// customer-side mocks so a Firebase-backed implementation can slot in later.
class MockAdminRepository implements AdminRepository {
  MockAdminRepository({
    List<AdminOrderModel>? initialOrders,
    List<AdminCustomerModel>? initialCustomers,
  }) : _orders = initialOrders ?? <AdminOrderModel>[],
       _customers = initialCustomers ?? <AdminCustomerModel>[];

  static const _latency = Duration(milliseconds: 150);

  final List<AdminOrderModel> _orders;
  final List<AdminCustomerModel> _customers;

  static final List<AdminProductModel> _products = [
    AdminProductModel(
      id: 'p_blouse',
      name: 'Designer Blouse',
      category: 'women',
      priceInr: 650,
      stitchDays: 5,
      rating: 4.8,
      photoCount: 4,
      visibility: 'live',
    ),
    AdminProductModel(
      id: 'p_anarkali',
      name: 'Anarkali Kurti',
      category: 'women',
      priceInr: 900,
      stitchDays: 6,
      rating: 4.7,
      photoCount: 3,
      visibility: 'live',
    ),
    AdminProductModel(
      id: 'p_salwar',
      name: 'Salwar Suit',
      category: 'women',
      priceInr: 1100,
      stitchDays: 7,
      rating: 4.6,
      photoCount: 4,
      visibility: 'live',
    ),
    AdminProductModel(
      id: 'p_lehenga',
      name: 'Bridal Lehenga',
      category: 'women',
      priceInr: 4500,
      stitchDays: 15,
      rating: 4.9,
      photoCount: 6,
      visibility: 'live',
    ),
    AdminProductModel(
      id: 'p_shirt',
      name: 'Formal Shirt',
      category: 'men',
      priceInr: 550,
      stitchDays: 4,
      rating: 4.6,
      photoCount: 3,
      visibility: 'live',
    ),
    AdminProductModel(
      id: 'p_trousers',
      name: 'Trousers',
      category: 'men',
      priceInr: 600,
      stitchDays: 4,
      rating: 4.5,
      photoCount: 2,
      visibility: 'live',
    ),
    AdminProductModel(
      id: 'p_kurta',
      name: 'Kurta Pajama',
      category: 'men',
      priceInr: 1000,
      stitchDays: 6,
      rating: 4.7,
      photoCount: 4,
      visibility: 'live',
    ),
    AdminProductModel(
      id: 'p_sherwani',
      name: 'Sherwani',
      category: 'men',
      priceInr: 5500,
      stitchDays: 14,
      rating: 4.8,
      photoCount: 5,
      visibility: 'hidden',
    ),
    AdminProductModel(
      id: 'p_frock',
      name: 'Kids Frock',
      category: 'kids',
      priceInr: 450,
      stitchDays: 3,
      rating: 4.8,
      photoCount: 3,
      visibility: 'live',
    ),
    AdminProductModel(
      id: 'p_kids_kurta',
      name: 'Kids Kurta Set',
      category: 'kids',
      priceInr: 500,
      stitchDays: 4,
      rating: 4.6,
      photoCount: 2,
      visibility: 'live',
    ),
  ];

  @override
  Future<List<AdminOrder>> loadOrders() async {
    await Future<void>.delayed(_latency);
    return _orders.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Stream<List<AdminOrder>> watchOrders() async* {
    yield await loadOrders();
  }

  @override
  Future<void> updateOrderStage(String orderId, OrderStage nextStage) async {
    await Future<void>.delayed(_latency);
    final int i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) {
      final AdminOrderModel old = _orders[i];
      _orders[i] = AdminOrderModel(
        id: old.id,
        item: old.item,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        customerAddress: old.customerAddress,
        placedDate: old.placedDate,
        dueDate: old.dueDate,
        amountAtShopInr: old.amountAtShopInr,
        stage: nextStage.name,
        measurementState: old.measurementState,
        measurementNote: old.measurementNote,
      );
    }
  }

  @override
  Future<List<AdminProduct>> loadProducts() async {
    await Future<void>.delayed(_latency);
    return _products.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<AdminProduct> saveProduct(AdminProduct product) async {
    await Future<void>.delayed(_latency);
    final String id = product.id.trim().isEmpty
        ? 'p_${DateTime.now().millisecondsSinceEpoch}'
        : product.id;
    final AdminProduct toSave = product.copyWith(id: id);
    final int i = _products.indexWhere((p) => p.id == id);
    final AdminProductModel model = AdminProductModel.fromEntity(toSave);
    if (i >= 0) {
      _products[i] = model;
    } else {
      _products.add(model);
    }
    return toSave;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await Future<void>.delayed(_latency);
    _products.removeWhere((p) => p.id == productId);
  }

  @override
  Future<List<AdminCustomer>> loadCustomers() async {
    await Future<void>.delayed(_latency);
    return _customers.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<DashboardSummary> loadDashboard() async {
    await Future<void>.delayed(_latency);
    final List<AdminOrder> orders = _orders
        .map((m) => m.toEntity())
        .toList(growable: false);
    final Map<OrderStage, int> stageCounts = <OrderStage, int>{
      for (final OrderStage s in OrderStage.values) s: 0,
    };
    for (final AdminOrder order in orders) {
      stageCounts[order.stage] = (stageCounts[order.stage] ?? 0) + 1;
    }

    return DashboardSummary(
      totalOrders: orders.length,
      newToday: 0,
      newTodayNote: 'No orders today',
      inProgress: orders.where((o) => o.stage != OrderStage.allSet).length,
      inProgressNote: 'In stitching pipeline',
      readyToCollect: orders.where((o) => o.stage == OrderStage.allSet).length,
      readyNote: 'Payment due at shop',
      stageCounts: stageCounts,
      recentOrders: orders.take(5).toList(growable: false),
    );
  }
}
