import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/timeline_step.dart';

/// State for the order tracking screen.
///
/// Holds the loaded [order] and its tracking [timeline]. When the order id is
/// unknown, [error] is set to "Not found".
class OrderTrackingState extends Equatable {
  const OrderTrackingState({
    this.loading = false,
    this.order,
    this.timeline = const [],
    this.error,
  });

  /// Initial loading state shown while the order is first fetched.
  const OrderTrackingState.initial() : this(loading: true);

  /// Whether the order and timeline are currently being loaded.
  final bool loading;

  /// The order being tracked, or null before it loads / on error.
  final Order? order;

  /// The tracking timeline steps; empty until loaded.
  final List<TimelineStep> timeline;

  /// Error message to display, or null when there is no error.
  final String? error;

  /// Returns a copy of this state with the given fields replaced.
  OrderTrackingState copyWith({
    bool? loading,
    Order? order,
    List<TimelineStep>? timeline,
    String? error,
  }) {
    return OrderTrackingState(
      loading: loading ?? this.loading,
      order: order ?? this.order,
      timeline: timeline ?? this.timeline,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, order, timeline, error];
}
