import '../../../../core/error/failures.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/customer_details.dart';
import '../../domain/entities/measurement_set.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_draft.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/timeline_step.dart';
import '../../domain/repositories/order_repository.dart';

/// In-memory [OrderRepository] used before a real API exists.
///
/// Seeds the active/completed orders and the six-stage tracking timeline shown
/// in the "My orders" and "Order tracking" mockups, and supports placing new
/// orders with generated `SN-####` ids.
class MockOrderRepository implements OrderRepository {
  MockOrderRepository()
    : _active = List<Order>.from(_seedActiveOrders()),
      _completed = List<Order>.from(_seedCompletedOrders());

  final List<Order> _active;
  final List<Order> _completed;

  /// Counter used to generate the next `SN-####` id for placed orders.
  int _nextOrderNumber = 1052;

  // --- Order seeds --------------------------------------------------------

  static List<Order> _seedActiveOrders() {
    return <Order>[];
  }

  static List<Order> _seedCompletedOrders() {
    return <Order>[];
  }

  // --- Timeline seed ------------------------------------------------------

  /// Builds the six-stage tracking timeline for an in-progress order.
  ///
  /// Done/current steps carry timestamps; pending steps have `null`.
  static List<TimelineStep> _buildTimeline() {
    return [
      TimelineStep(
        stage: TimelineStage.orderPlaced,
        label: 'Order placed',
        state: StepState.done,
        timestamp: DateTime(2025, 10, 20, 11, 20),
      ),
      TimelineStep(
        stage: TimelineStage.measurementDone,
        label: 'Measurement done',
        state: StepState.done,
        timestamp: DateTime(2025, 10, 21, 17, 45),
      ),
      TimelineStep(
        stage: TimelineStage.stitchingStarted,
        label: 'Stitching started',
        state: StepState.current,
        timestamp: DateTime(2025, 10, 23),
      ),
      const TimelineStep(
        stage: TimelineStage.stitchingFinished,
        label: 'Stitching finished',
        state: StepState.pending,
      ),
      const TimelineStep(
        stage: TimelineStage.finalTouchUp,
        label: 'Final touch-up',
        state: StepState.pending,
      ),
      const TimelineStep(
        stage: TimelineStage.allSet,
        label: 'All set',
        state: StepState.pending,
      ),
    ];
  }

  // --- OrderRepository ----------------------------------------------------

  @override
  Future<List<Order>> getOrders({
    OrderBucket bucket = OrderBucket.active,
  }) async {
    return switch (bucket) {
      OrderBucket.active => List<Order>.unmodifiable(_active),
      OrderBucket.completed => List<Order>.unmodifiable(_completed),
    };
  }

  @override
  Future<Order> getOrderById(String orderId) async {
    for (final order in [..._active, ..._completed]) {
      if (order.id == orderId) return order;
    }
    throw NotFoundFailure('No order with id "$orderId".');
  }

  @override
  Future<String> createDraftOrder(Product product) async {
    return 'draft_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> updateDraftDetails({
    required String draftId,
    required CustomerDetails details,
  }) async {}

  @override
  Future<void> updateDraftMeasurements({
    required String draftId,
    required MeasurementSet measurements,
  }) async {}

  @override
  Future<Order> placeOrder(OrderDraft draft, {String? draftId}) async {
    final id = 'SN-${_nextOrderNumber++}';
    final now = DateTime.now();
    final order = Order(
      id: id,
      product: draft.product,
      placedDate: now,
      status: OrderStatus.placed,
      progress: 0.05,
      nextStep: 'Measurement done',
      amountAtShopInr: draft.product.priceInr,
      expectedReady: now.add(Duration(days: draft.product.readyInDays)),
    );
    _active.insert(0, order);
    return order;
  }

  @override
  Future<List<TimelineStep>> getTimeline(String orderId) async {
    // Validates the id exists (throws NotFoundFailure when unknown).
    await getOrderById(orderId);
    return _buildTimeline();
  }
}
