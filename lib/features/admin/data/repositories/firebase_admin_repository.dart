import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_customer.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/admin_product.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/admin_repository.dart';
import '../models/admin_product_model.dart';
import 'mock_admin_repository.dart';

/// Firebase Firestore implementation of [AdminRepository].
///
/// Stores and fetches catalog products in the `products` collection in Firestore.
/// Orders, dashboard, and customers fall back to mock data until wired.
class FirebaseAdminRepository implements AdminRepository {
  FirebaseAdminRepository({
    FirebaseFirestore? firestore,
    MockAdminRepository? fallbackMock,
  })  : _injectedFirestore = firestore,
        _mockFallback = fallbackMock ?? MockAdminRepository();

  final FirebaseFirestore? _injectedFirestore;
  final MockAdminRepository _mockFallback;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  @override
  Future<List<AdminProduct>> loadProducts() async {
    try {
      final snapshot = await _productsRef.get();
      if (snapshot.docs.isEmpty) {
        // Seed initial products from mock data if Firestore products collection is empty
        final mockProducts = await _mockFallback.loadProducts();
        for (final p in mockProducts) {
          await saveProduct(p);
        }
        return mockProducts;
      }

      return snapshot.docs.map((doc) {
        return AdminProductModel.fromMap(doc.data(), doc.id).toEntity();
      }).toList();
    } catch (_) {
      return _mockFallback.loadProducts();
    }
  }

  @override
  Future<void> saveProduct(AdminProduct product) async {
    final String docId = product.id.trim().isEmpty
        ? 'p_${DateTime.now().millisecondsSinceEpoch}'
        : product.id;
    final AdminProduct toSave = product.copyWith(id: docId);
    final data = AdminProductModel.fromEntity(toSave).toMap();
    await _productsRef.doc(docId).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }

  @override
  Future<DashboardSummary> loadDashboard() => _mockFallback.loadDashboard();

  @override
  Future<List<AdminOrder>> loadOrders() => _mockFallback.loadOrders();

  @override
  Future<List<AdminCustomer>> loadCustomers() => _mockFallback.loadCustomers();
}
