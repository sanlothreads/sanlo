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

  /// Places [draft] and returns the created order (mock: assigns id #SN-####).
  Future<Order> placeOrder(OrderDraft draft);

  /// Returns the tracking timeline for [orderId]; throws a `NotFoundFailure`
  /// when the id is unknown.
  Future<List<TimelineStep>> getTimeline(String orderId);
}
