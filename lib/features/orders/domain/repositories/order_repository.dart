import '../../../catalog/domain/entities/product.dart';
import '../entities/customer_details.dart';
import '../entities/measurement_set.dart';
import '../entities/order.dart';
import '../entities/order_draft.dart';
import '../entities/timeline_step.dart';

/// Which set of orders to return from [OrderRepository.getOrders].
enum OrderBucket {
  /// Orders still being worked on.
  active,

  /// Orders that have been completed/picked up.
  completed,
}

/// Contract for listing, placing, and tracking orders.
///
/// [getOrderById] and [getTimeline] throw a `NotFoundFailure` when the given
/// order id is unknown.
abstract interface class OrderRepository {
  /// Returns the orders in the given [bucket] (active or completed).
  Future<List<Order>> getOrders({OrderBucket bucket});

  /// Returns the order with [orderId]; throws a `NotFoundFailure` when unknown.
  Future<Order> getOrderById(String orderId);

  /// Creates a draft order in Firestore for [product] with status `draft`.
  Future<String> createDraftOrder(Product product);

  /// Updates customer details on the draft order in Firestore.
  Future<void> updateDraftDetails({
    required String draftId,
    required CustomerDetails details,
  });

  /// Updates measurements on the draft order in Firestore.
  Future<void> updateDraftMeasurements({
    required String draftId,
    required MeasurementSet measurements,
  });

  /// Places [draft] and returns the created order.
  Future<Order> placeOrder(OrderDraft draft, {String? draftId});

  /// Returns the tracking timeline for [orderId]; throws a `NotFoundFailure`
  /// when the id is unknown.
  Future<List<TimelineStep>> getTimeline(String orderId);
}
