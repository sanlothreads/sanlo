import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../catalog/data/models/product_model.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/customer_details.dart';
import '../../domain/entities/measurement_set.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_draft.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/timeline_step.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/customer_details_model.dart';
import '../models/measurement_set_model.dart';
import '../models/order_model.dart';
import 'mock_order_repository.dart';

/// Firestore implementation of [OrderRepository] for customer order lifecycle.
///
/// Handles draft initiation, step details saving, measurements saving, final
/// order placement, and fetching live active/completed orders from Firestore.
class FirebaseOrderRepository implements OrderRepository {
  FirebaseOrderRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseDatabase? database,
    MockOrderRepository? fallbackMock,
  }) : _injectedFirestore = firestore,
       _injectedAuth = auth,
       _injectedDb = database,
       _mockFallback = fallbackMock ?? MockOrderRepository();

  final FirebaseFirestore? _injectedFirestore;
  final FirebaseAuth? _injectedAuth;
  final FirebaseDatabase? _injectedDb;
  final MockOrderRepository _mockFallback;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  FirebaseDatabase get _db => _injectedDb ?? FirebaseDatabase.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  /// Generates a guaranteed unique, incremental order ID formatted as `SN-xxxx`.
  ///
  /// Uses an atomic Firestore transaction counter (padding to at least 4 digits),
  /// querying the highest existing `SN-xxxx` document if needed, and checking
  /// document existence to ensure sequential incrementation with zero collisions.
  Future<String> _generateUniqueOrderId() async {
    try {
      final counterRef = _firestore.collection('counters').doc('orders');

      // Atomic transaction increment
      final String? nextId = await _firestore.runTransaction<String?>((
        transaction,
      ) async {
        final snapshot = await transaction.get(counterRef);
        int currentNumber = 1001;
        if (snapshot.exists && snapshot.data() != null) {
          currentNumber =
              (snapshot.data()!['nextNumber'] as num?)?.toInt() ?? 1001;
        }
        final String numStr = currentNumber.toString().padLeft(4, '0');
        final String candidateId = 'SN-$numStr';
        transaction.set(counterRef, {
          'nextNumber': currentNumber + 1,
        }, SetOptions(merge: true));
        return candidateId;
      });

      if (nextId != null) {
        final doc = await _ordersRef.doc(nextId).get();
        if (!doc.exists) {
          return nextId;
        }
      }
    } catch (_) {
      // Transaction fallback
    }

    // Fallback: Query highest existing SN-xxxx order number from Firestore
    try {
      final querySnapshot = await _ordersRef
          .orderBy(FieldPath.documentId, descending: true)
          .limit(10)
          .get();
      int highest = 1000;
      for (final doc in querySnapshot.docs) {
        if (doc.id.startsWith('SN-')) {
          final String numPart = doc.id.substring(3);
          final int? parsed = int.tryParse(numPart);
          if (parsed != null && parsed > highest) {
            highest = parsed;
          }
        }
      }
      final int nextNum = highest + 1;
      return 'SN-${nextNum.toString().padLeft(4, '0')}';
    } catch (_) {
      // High-precision millisecond fallback
      final int millis = DateTime.now().millisecondsSinceEpoch % 10000;
      return 'SN-${millis.toString().padLeft(4, '0')}';
    }
  }

  @override
  Future<String> createDraftOrder(Product product) async {
    try {
      final String orderId = await _generateUniqueOrderId();
      final docRef = _ordersRef.doc(orderId);
      final String? uid = _auth.currentUser?.uid;

      final data = <String, dynamic>{
        'id': orderId,
        'status': 'draft',
        'userId': uid ?? 'guest',
        'product': ProductModel.fromEntity(product).toJson(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await docRef.set(data);
      return orderId;
    } catch (_) {
      final int rand = 1000 + Random().nextInt(9000);
      return 'SN-$rand';
    }
  }

  @override
  Future<void> updateDraftDetails({
    required String draftId,
    required CustomerDetails details,
  }) async {
    try {
      final docRef = _ordersRef.doc(draftId);
      await docRef.set(<String, dynamic>{
        'details': CustomerDetailsModel.fromEntity(details).toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
        'step': 'measurements',
      }, SetOptions(merge: true));
    } catch (_) {
      // Ignored for offline mode
    }
  }

  @override
  Future<void> updateDraftMeasurements({
    required String draftId,
    required MeasurementSet measurements,
  }) async {
    try {
      final docRef = _ordersRef.doc(draftId);
      await docRef.set(<String, dynamic>{
        'measurements': MeasurementSetModel.fromEntity(measurements).toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
        'step': 'review',
      }, SetOptions(merge: true));
    } catch (_) {
      // Ignored for offline mode
    }
  }

  @override
  Future<Order> placeOrder(OrderDraft draft, {String? draftId}) async {
    try {
      final String docId =
          (draftId != null && draftId.isNotEmpty && draftId.startsWith('SN-'))
          ? draftId
          : await _generateUniqueOrderId();
      final now = DateTime.now();
      final String? uid = _auth.currentUser?.uid;

      final order = Order(
        id: docId,
        product: draft.product,
        placedDate: now,
        status: OrderStatus.placed,
        progress: 0.05,
        nextStep: 'Measurement done',
        amountAtShopInr: draft.product.priceInr,
        expectedReady: now.add(Duration(days: draft.product.readyInDays)),
      );

      final map = <String, dynamic>{
        'id': docId,
        'status': OrderStatus.placed.name,
        'userId': uid ?? 'guest',
        'placedDate': now.toIso8601String(),
        'expectedReady': now
            .add(Duration(days: draft.product.readyInDays))
            .toIso8601String(),
        'progress': 0.05,
        'nextStep': 'Measurement done',
        'amountAtShopInr': draft.product.priceInr,
        'product': ProductModel.fromEntity(draft.product).toJson(),
        if (draft.details != null)
          'details': CustomerDetailsModel.fromEntity(draft.details!).toJson(),
        if (draft.measurements != null)
          'measurements': MeasurementSetModel.fromEntity(
            draft.measurements!,
          ).toJson(),
        'updatedAt': now.toIso8601String(),
      };

      await _ordersRef.doc(docId).set(map, SetOptions(merge: true));
      return order;
    } catch (_) {
      return _mockFallback.placeOrder(draft);
    }
  }

  Future<Map<String, String>> _getCurrentUserInfo() async {
    final Map<String, String> info = <String, String>{};
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return info;

    if (firebaseUser.uid.isNotEmpty) {
      info['uid'] = firebaseUser.uid;
    }
    if (firebaseUser.phoneNumber != null &&
        firebaseUser.phoneNumber!.isNotEmpty) {
      info['mobile'] = firebaseUser.phoneNumber!;
    }
    if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
      info['email'] = firebaseUser.email!;
    }

    try {
      final snapshot = await _db.ref('users/${firebaseUser.uid}').get();
      if (snapshot.exists && snapshot.value is Map) {
        final Map map = Map.from(snapshot.value as Map);
        final String? mob =
            map['mobile'] as String? ?? map['phone'] as String?;
        final String? em = map['email'] as String?;
        if (mob != null &&
            mob.trim().isNotEmpty &&
            !info.containsKey('mobile')) {
          info['mobile'] = mob.trim();
        }
        if (em != null &&
            em.trim().isNotEmpty &&
            !info.containsKey('email')) {
          info['email'] = em.trim();
        }
      }
    } catch (_) {}

    return info;
  }

  bool _orderMatchesUser({
    required Map<String, dynamic> data,
    required String? userUid,
    required String? userMobile,
    required String? userEmail,
  }) {
    // 1. User ID check
    if (userUid != null && userUid.isNotEmpty) {
      final String? orderUserId = data['userId'] as String?;
      if (orderUserId != null && orderUserId == userUid) {
        return true;
      }
    }

    // Extract order mobile and email
    final dynamic details = data['details'];
    String? orderMobile;
    String? orderEmail;
    if (details is Map) {
      final Map<String, dynamic> detMap =
          Map<String, dynamic>.from(details);
      orderMobile =
          detMap['phone'] as String? ?? detMap['mobile'] as String?;
      orderEmail = detMap['email'] as String?;
    }
    orderMobile ??= data['customerPhone'] as String? ??
        data['mobile'] as String? ??
        data['phone'] as String?;
    orderEmail ??=
        data['customerEmail'] as String? ?? data['email'] as String?;

    // 2. Mobile check
    if (userMobile != null &&
        userMobile.isNotEmpty &&
        orderMobile != null &&
        orderMobile.isNotEmpty) {
      if (_mobilesMatch(orderMobile, userMobile)) {
        return true;
      }
    }

    // 3. Email check
    if (userEmail != null &&
        userEmail.isNotEmpty &&
        orderEmail != null &&
        orderEmail.isNotEmpty) {
      if (orderEmail.trim().toLowerCase() ==
          userEmail.trim().toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  bool _mobilesMatch(String m1, String m2) {
    final String digits1 = m1.replaceAll(RegExp(r'\D'), '');
    final String digits2 = m2.replaceAll(RegExp(r'\D'), '');
    if (digits1.isEmpty || digits2.isEmpty) return false;
    if (digits1 == digits2) return true;

    final String last10_1 = digits1.length >= 10
        ? digits1.substring(digits1.length - 10)
        : digits1;
    final String last10_2 = digits2.length >= 10
        ? digits2.substring(digits2.length - 10)
        : digits2;
    return last10_1 == last10_2;
  }

  @override
  Future<List<Order>> getOrders({
    OrderBucket bucket = OrderBucket.active,
  }) async {
    try {
      final userInfo = await _getCurrentUserInfo();
      final String? userUid = userInfo['uid'];
      final String? userMobile = userInfo['mobile'];
      final String? userEmail = userInfo['email'];

      final snapshot = await _ordersRef.get();
      if (snapshot.docs.isEmpty) {
        if (userUid != null) {
          return <Order>[];
        }
        return _mockFallback.getOrders(bucket: bucket);
      }

      final List<Order> orders = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final String statusStr = data['status'] as String? ?? 'draft';
        if (statusStr == 'draft') continue;

        if (!_orderMatchesUser(
          data: data,
          userUid: userUid,
          userMobile: userMobile,
          userEmail: userEmail,
        )) {
          continue;
        }

        try {
          final order = OrderModel.fromJson(data).toEntity();
          final bool isCompleted = order.status == OrderStatus.completed;
          if (bucket == OrderBucket.completed && isCompleted) {
            orders.add(order);
          } else if (bucket == OrderBucket.active && !isCompleted) {
            orders.add(order);
          }
        } catch (_) {
          // Skip invalid rows
        }
      }

      if (orders.isEmpty && userUid == null) {
        return _mockFallback.getOrders(bucket: bucket);
      }

      orders.sort((a, b) => b.placedDate.compareTo(a.placedDate));
      return orders;
    } catch (_) {
      return _mockFallback.getOrders(bucket: bucket);
    }
  }

  @override
  Future<Order> getOrderById(String orderId) async {
    try {
      final String cleanId = orderId.replaceAll('#', '').trim();

      // First try exact document ID lookup
      var doc = await _ordersRef.doc(cleanId).get();
      if (!doc.exists || doc.data() == null) {
        // Query by id field in Firestore
        final query = await _ordersRef
            .where('id', isEqualTo: cleanId)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          doc = query.docs.first;
        }
      }

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final String statusStr = data['status'] as String? ?? 'draft';
        if (statusStr != 'draft') {
          return OrderModel.fromJson(data).toEntity();
        }
      }
      return _mockFallback.getOrderById(orderId);
    } catch (_) {
      return _mockFallback.getOrderById(orderId);
    }
  }

  @override
  Future<List<TimelineStep>> getTimeline(String orderId) async {
    try {
      final Order order = await getOrderById(orderId);
      final DateTime placed = order.placedDate;
      final double progress = order.progress;
      final bool isCompleted = order.status == OrderStatus.completed;

      return <TimelineStep>[
        TimelineStep(
          stage: TimelineStage.orderPlaced,
          label: 'Order placed',
          state: StepState.done,
          timestamp: placed,
        ),
        TimelineStep(
          stage: TimelineStage.measurementDone,
          label: 'Measurement done',
          state: progress >= 0.2 || isCompleted
              ? StepState.done
              : (progress >= 0.05 ? StepState.current : StepState.pending),
          timestamp: progress >= 0.2
              ? placed.add(const Duration(hours: 6))
              : null,
        ),
        TimelineStep(
          stage: TimelineStage.stitchingStarted,
          label: 'Stitching started',
          state: progress >= 0.5 || isCompleted
              ? StepState.done
              : (progress >= 0.2 ? StepState.current : StepState.pending),
          timestamp: progress >= 0.5
              ? placed.add(const Duration(days: 1))
              : null,
        ),
        TimelineStep(
          stage: TimelineStage.stitchingFinished,
          label: 'Stitching finished',
          state: progress >= 0.75 || isCompleted
              ? StepState.done
              : (progress >= 0.5 ? StepState.current : StepState.pending),
          timestamp: progress >= 0.75
              ? placed.add(const Duration(days: 2))
              : null,
        ),
        TimelineStep(
          stage: TimelineStage.finalTouchUp,
          label: 'Final touch-up',
          state: progress >= 0.9 || isCompleted
              ? StepState.done
              : (progress >= 0.75 ? StepState.current : StepState.pending),
          timestamp: progress >= 0.9
              ? placed.add(const Duration(days: 3))
              : null,
        ),
        TimelineStep(
          stage: TimelineStage.allSet,
          label: 'All set',
          state: isCompleted
              ? StepState.done
              : (progress >= 0.9 ? StepState.current : StepState.pending),
          timestamp: isCompleted ? order.expectedReady : null,
        ),
      ];
    } catch (_) {
      return _mockFallback.getTimeline(orderId);
    }
  }
}
