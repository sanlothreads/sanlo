import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../../core/entities/gender.dart';
import '../../domain/entities/admin_customer.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/admin_product.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/admin_repository.dart';
import '../models/admin_product_model.dart';
import 'mock_admin_repository.dart';

/// Firebase Firestore & Realtime Database implementation of [AdminRepository].
///
/// Stores and fetches catalog products in the `products` collection in Firestore,
/// and fetches logged-in customers from the Realtime Database `users` node.
class FirebaseAdminRepository implements AdminRepository {
  FirebaseAdminRepository({
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
    MockAdminRepository? fallbackMock,
  }) : _injectedFirestore = firestore,
       _injectedDb = database,
       _mockFallback = fallbackMock ?? MockAdminRepository();

  final FirebaseFirestore? _injectedFirestore;
  final FirebaseDatabase? _injectedDb;
  final MockAdminRepository _mockFallback;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  FirebaseDatabase get _db => _injectedDb ?? FirebaseDatabase.instance;

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
  Future<List<AdminCustomer>> loadCustomers() async {
    try {
      final snapshot = await _db.ref('users').get();
      if (!snapshot.exists || snapshot.value == null) {
        return _mockFallback.loadCustomers();
      }

      final Object? value = snapshot.value;
      if (value is! Map) {
        return _mockFallback.loadCustomers();
      }

      final List<AdminOrder> orders = await loadOrders();
      final Map<String, int> phoneOrderCounts = <String, int>{};
      final Map<String, DateTime> phoneLastDates = <String, DateTime>{};

      for (final AdminOrder order in orders) {
        final String normPhone = _normMobile(order.customerPhone);
        phoneOrderCounts[normPhone] = (phoneOrderCounts[normPhone] ?? 0) + 1;
        final DateTime? currentLast = phoneLastDates[normPhone];
        if (currentLast == null || order.placedDate.isAfter(currentLast)) {
          phoneLastDates[normPhone] = order.placedDate;
        }
      }

      final List<AdminCustomer> customers = <AdminCustomer>[];

      for (final MapEntry<dynamic, dynamic> entry in value.entries) {
        final String uid = entry.key.toString();
        final Object? data = entry.value;
        if (data is! Map) continue;

        final Map<String, dynamic> map = Map<String, dynamic>.from(data);

        final String firstName = (map['firstName'] as String? ?? '').trim();
        final String lastName = (map['lastName'] as String? ?? '').trim();
        String name = '$firstName $lastName'.trim();

        final String rawMobile = (map['mobile'] as String? ?? '').trim();
        if (name.isEmpty) {
          name = rawMobile.isNotEmpty ? rawMobile : 'Customer';
        }

        final String? email = map['email'] as String?;
        final String? createdAtStr = map['createdAt'] as String?;
        final String? lastAppOpenedStr =
            map['lastAppOpened'] as String? ?? map['lastOtpLogin'] as String?;

        Gender gender = Gender.female;
        final String? genderStr = map['gender'] as String?;
        if (genderStr != null) {
          try {
            gender = Gender.values.byName(genderStr);
          } catch (_) {}
        }

        final String normPhone = _normMobile(rawMobile);
        final int orderCount = phoneOrderCounts[normPhone] ?? 0;
        final DateTime? lastOrderDate = orderCount > 0
            ? phoneLastDates[normPhone]
            : null;

        customers.add(
          AdminCustomer(
            id: uid,
            name: name,
            mobile: rawMobile.isNotEmpty ? rawMobile : '—',
            email: email,
            gender: gender,
            type: CustomerType.registered,
            registeredDate: createdAtStr ?? '—',
            lastLogin: lastAppOpenedStr ?? '—',
            orderCount: orderCount,
            lastOrderDate: lastOrderDate,
          ),
        );
      }

      return customers.isEmpty ? _mockFallback.loadCustomers() : customers;
    } catch (_) {
      return _mockFallback.loadCustomers();
    }
  }

  String _normMobile(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  DateTime _parseDateString(String dateStr) {
    try {
      final List<String> parts = dateStr.trim().split(' ');
      if (parts.isNotEmpty) {
        final List<String> dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          final int day = int.parse(dateParts[0]);
          final int month = _monthIndex(dateParts[1]);
          final int year = int.parse(dateParts[2]);
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}
    return DateTime.now();
  }

  int _monthIndex(String m) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final int idx = months.indexWhere(
      (element) => element.toLowerCase() == m.toLowerCase(),
    );
    return idx >= 0 ? idx + 1 : 1;
  }
}
