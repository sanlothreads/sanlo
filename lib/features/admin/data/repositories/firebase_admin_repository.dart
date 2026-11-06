import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../../core/entities/gender.dart';
import '../../../orders/domain/entities/order_status.dart';
import '../../domain/entities/admin_customer.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/admin_product.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/order_stage.dart';
import '../../domain/repositories/admin_repository.dart';
import '../models/admin_order_model.dart';
import '../models/admin_product_model.dart';
import 'mock_admin_repository.dart';

/// Firebase Firestore & Realtime Database implementation of [AdminRepository].
///
/// Stores and fetches catalog products in the `products` collection in Firestore,
/// orders in the `orders` collection in Firestore, and fetches logged-in
/// customers from the Realtime Database `users` node.
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

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

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
  Future<AdminProduct> saveProduct(AdminProduct product) async {
    // Create: empty id -> use a Firestore auto-generated document id.
    // Update: existing id -> write back to the same document.
    final DocumentReference<Map<String, dynamic>> docRef =
        product.id.trim().isEmpty
        ? _productsRef.doc()
        : _productsRef.doc(product.id);
    final AdminProduct toSave = product.copyWith(id: docRef.id);
    final data = AdminProductModel.fromEntity(toSave).toMap();
    await docRef.set(data, SetOptions(merge: true));
    return toSave;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }

  @override
  Stream<List<AdminOrder>> watchOrders() {
    try {
      return _ordersRef.snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return <AdminOrder>[];
        }
        final List<AdminOrder> orders = <AdminOrder>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final String statusStr = data['status'] as String? ?? '';
          if (statusStr == 'draft') continue;
          try {
            orders.add(AdminOrderModel.fromMap(data, doc.id).toEntity());
          } catch (_) {}
        }
        orders.sort((a, b) => b.placedDate.compareTo(a.placedDate));
        return orders;
      });
    } catch (_) {
      return Stream.value(<AdminOrder>[]);
    }
  }

  @override
  Future<List<AdminOrder>> loadOrders() async {
    try {
      final snapshot = await _ordersRef.get();
      if (snapshot.docs.isEmpty) {
        // Seed initial orders from mock data if Firestore orders collection is empty
        final mockOrders = await _mockFallback.loadOrders();
        for (final o in mockOrders) {
          await _saveMockAdminOrder(o);
        }
        return mockOrders;
      }

      final List<AdminOrder> orders = <AdminOrder>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final String statusStr = data['status'] as String? ?? '';
        if (statusStr == 'draft') continue;
        try {
          orders.add(AdminOrderModel.fromMap(data, doc.id).toEntity());
        } catch (_) {}
      }

      if (orders.isEmpty) {
        return _mockFallback.loadOrders();
      }

      orders.sort((a, b) => b.placedDate.compareTo(a.placedDate));
      return orders;
    } catch (_) {
      return _mockFallback.loadOrders();
    }
  }

  Future<void> _saveMockAdminOrder(AdminOrder order) async {
    final data = AdminOrderModel.fromEntity(order).toMap();
    await _ordersRef.doc(order.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updateOrderStage(String orderId, OrderStage nextStage) async {
    final String cleanId = orderId.replaceAll('#', '').trim();

    final String statusStr = _mapStageToOrderStatusName(nextStage);
    final double progress = _mapStageToProgress(nextStage);
    final String nextStep = _mapStageToNextStep(nextStage);

    final Map<String, dynamic> updateData = <String, dynamic>{
      'stage': nextStage.name,
      'status': statusStr,
      'progress': progress,
      'nextStep': nextStep,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _ordersRef.doc(cleanId).set(updateData, SetOptions(merge: true));
  }

  String _mapStageToOrderStatusName(OrderStage stage) {
    switch (stage) {
      case OrderStage.ordered:
        return OrderStatus.placed.name;
      case OrderStage.measurementDone:
      case OrderStage.stitchingStarted:
      case OrderStage.stitchingFinished:
      case OrderStage.finalTouchUp:
        return OrderStatus.inProgress.name;
      case OrderStage.allSet:
        return OrderStatus.completed.name;
    }
  }

  double _mapStageToProgress(OrderStage stage) {
    switch (stage) {
      case OrderStage.ordered:
        return 0.05;
      case OrderStage.measurementDone:
        return 0.20;
      case OrderStage.stitchingStarted:
        return 0.50;
      case OrderStage.stitchingFinished:
        return 0.75;
      case OrderStage.finalTouchUp:
        return 0.90;
      case OrderStage.allSet:
        return 1.00;
    }
  }

  String _mapStageToNextStep(OrderStage stage) {
    switch (stage) {
      case OrderStage.ordered:
        return 'Measurement done';
      case OrderStage.measurementDone:
        return 'Stitching started';
      case OrderStage.stitchingStarted:
        return 'Stitching finished';
      case OrderStage.stitchingFinished:
        return 'Final touch-up';
      case OrderStage.finalTouchUp:
        return 'All set';
      case OrderStage.allSet:
        return 'Completed';
    }
  }

  @override
  Future<DashboardSummary> loadDashboard() async {
    try {
      final List<AdminOrder> orders = await loadOrders();
      if (orders.isEmpty) {
        return _mockFallback.loadDashboard();
      }

      final int totalOrders = orders.length;
      final DateTime now = DateTime.now();
      final int newToday = orders.where((o) {
        return o.placedDate.year == now.year &&
            o.placedDate.month == now.month &&
            o.placedDate.day == now.day;
      }).length;

      final int inProgress = orders
          .where((o) => o.stage != OrderStage.allSet)
          .length;
      final int readyToCollect = orders
          .where((o) => o.stage == OrderStage.allSet)
          .length;

      final Map<OrderStage, int> stageCounts = <OrderStage, int>{
        for (final OrderStage s in OrderStage.values) s: 0,
      };

      for (final AdminOrder order in orders) {
        stageCounts[order.stage] = (stageCounts[order.stage] ?? 0) + 1;
      }

      return DashboardSummary(
        totalOrders: totalOrders,
        newToday: newToday,
        newTodayNote: '$newToday orders placed today',
        inProgress: inProgress,
        inProgressNote: 'In stitching pipeline',
        readyToCollect: readyToCollect,
        readyNote: 'Payment due at shop',
        stageCounts: stageCounts,
        recentOrders: orders.take(5).toList(growable: false),
      );
    } catch (_) {
      return _mockFallback.loadDashboard();
    }
  }

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
}
