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
  static const _latency = Duration(milliseconds: 150);

  static final List<AdminOrderModel> _orders = [
    AdminOrderModel(
      id: 'SN-1048',
      item: 'Designer Blouse',
      customerName: 'Priya Sharma',
      customerPhone: '+91 98765 43210',
      customerAddress: '21 Park Street, Pune',
      placedDate: DateTime(2025, 10, 25),
      dueDate: DateTime(2025, 10, 29),
      amountAtShopInr: 650,
      stage: 'ordered',
      measurementState: 'entered',
    ),
    AdminOrderModel(
      id: 'SN-1047',
      item: 'Formal Shirt',
      customerName: 'Rahul Verma',
      customerPhone: '+91 98111 22334',
      customerAddress: '12 MG Road, Pune',
      placedDate: DateTime(2025, 10, 24),
      dueDate: DateTime(2025, 10, 30),
      amountAtShopInr: 550,
      stage: 'ordered',
      measurementState: 'notSure',
      measurementNote:
          'Customer chose "Not sure" - take measurements when they visit '
          'the shop.',
    ),
    AdminOrderModel(
      id: 'SN-1045',
      item: 'Salwar Suit',
      customerName: 'Anita Desai',
      customerPhone: '+91 99887 66554',
      customerAddress: '5 Lake View, Pune',
      placedDate: DateTime(2025, 10, 23),
      dueDate: DateTime(2025, 11, 1),
      amountAtShopInr: 1100,
      stage: 'measurementDone',
      measurementState: 'entered',
    ),
    AdminOrderModel(
      id: 'SN-1041',
      item: 'Kurta Pajama',
      customerName: 'Vikram Singh',
      customerPhone: '+91 97654 32109',
      customerAddress: '8 Hill Road, Pune',
      placedDate: DateTime(2025, 10, 20),
      dueDate: DateTime(2025, 10, 27),
      amountAtShopInr: 1000,
      stage: 'stitchingStarted',
      measurementState: 'entered',
    ),
    AdminOrderModel(
      id: 'SN-1039',
      item: 'Kids Kurta Set',
      customerName: 'Sana Khan',
      customerPhone: '+91 91234 56789',
      customerAddress: '3 Green Avenue, Pune',
      placedDate: DateTime(2025, 10, 19),
      dueDate: DateTime(2025, 10, 25),
      amountAtShopInr: 500,
      stage: 'stitchingFinished',
      measurementState: 'entered',
    ),
    AdminOrderModel(
      id: 'SN-1036',
      item: 'Anarkali Kurti',
      customerName: 'Meera Iyer',
      customerPhone: '+91 90000 12345',
      customerAddress: '19 River Side, Pune',
      placedDate: DateTime(2025, 10, 17),
      dueDate: DateTime(2025, 10, 26),
      amountAtShopInr: 900,
      stage: 'finalTouchUp',
      measurementState: 'entered',
    ),
  ];

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

  static final List<AdminCustomerModel> _customers = [
    AdminCustomerModel(
      id: 'c_priya',
      name: 'Priya Sharma',
      mobile: '+91 98765 43210',
      gender: 'female',
      type: 'guest',
      orderCount: 1,
      lastOrderDate: DateTime(2025, 10, 24),
    ),
    AdminCustomerModel(
      id: 'c_rahul',
      name: 'Rahul Verma',
      mobile: '+91 98111 22334',
      email: 'rahul@example.com',
      gender: 'male',
      type: 'registered',
      orderCount: 3,
      lastOrderDate: DateTime(2025, 10, 24),
    ),
    AdminCustomerModel(
      id: 'c_anita',
      name: 'Anita Desai',
      mobile: '+91 99887 66554',
      email: 'anita@example.com',
      gender: 'female',
      type: 'registered',
      orderCount: 5,
      lastOrderDate: DateTime(2025, 10, 23),
    ),
    AdminCustomerModel(
      id: 'c_vikram',
      name: 'Vikram Singh',
      mobile: '+91 97654 32109',
      gender: 'male',
      type: 'guest',
      orderCount: 1,
      lastOrderDate: DateTime(2025, 10, 20),
    ),
    AdminCustomerModel(
      id: 'c_sana',
      name: 'Sana Khan',
      mobile: '+91 91234 56789',
      email: 'sana@example.com',
      gender: 'female',
      type: 'registered',
      orderCount: 2,
      lastOrderDate: DateTime(2025, 10, 19),
    ),
    AdminCustomerModel(
      id: 'c_meera',
      name: 'Meera Iyer',
      mobile: '+91 90000 12345',
      email: 'meera@example.com',
      gender: 'female',
      type: 'registered',
      orderCount: 4,
      lastOrderDate: DateTime(2025, 10, 17),
    ),
    AdminCustomerModel(
      id: 'c_arjun',
      name: 'Arjun Rao',
      mobile: '+91 93333 44455',
      gender: 'male',
      type: 'guest',
      orderCount: 1,
      lastOrderDate: DateTime(2025, 10, 2),
    ),
    AdminCustomerModel(
      id: 'c_kavya',
      name: 'Kavya Nair',
      mobile: '+91 95555 66677',
      email: 'kavya@example.com',
      gender: 'female',
      type: 'registered',
      orderCount: 2,
      lastOrderDate: DateTime(2025, 9, 21),
    ),
  ];

  @override
  Future<List<AdminOrder>> loadOrders() async {
    await Future<void>.delayed(_latency);
    return _orders.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<List<AdminProduct>> loadProducts() async {
    await Future<void>.delayed(_latency);
    return _products.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<void> saveProduct(AdminProduct product) async {
    await Future<void>.delayed(_latency);
    final int i = _products.indexWhere((p) => p.id == product.id);
    final AdminProductModel model = AdminProductModel.fromEntity(product);
    if (i >= 0) {
      _products[i] = model;
    } else {
      _products.add(model);
    }
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
    return DashboardSummary(
      totalOrders: 27,
      newToday: 3,
      newTodayNote: '1 needs measurement at shop',
      inProgress: 12,
      inProgressNote: 'Measured \u2192 touch-up',
      readyToCollect: 6,
      readyNote: 'Payment due at shop',
      stageCounts: const {
        OrderStage.ordered: 5,
        OrderStage.measurementDone: 4,
        OrderStage.stitchingStarted: 7,
        OrderStage.stitchingFinished: 3,
        OrderStage.finalTouchUp: 2,
        OrderStage.allSet: 6,
      },
      recentOrders: orders.take(5).toList(growable: false),
    );
  }
}
