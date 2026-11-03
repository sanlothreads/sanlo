import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

/// State for the "My orders" screen.
///
/// Holds both the [active] and [completed] order lists and the currently
/// selected [bucket]. The [visible] getter derives which list to show.
class OrdersState extends Equatable {
  const OrdersState({
    this.loading = false,
    this.bucket = OrderBucket.active,
    this.active = const [],
    this.completed = const [],
    this.error,
  });

  /// Initial loading state shown while orders are first fetched.
  const OrdersState.initial() : this(loading: true);

  /// Whether orders are currently being loaded.
  final bool loading;

  /// Which bucket is currently selected (active or completed).
  final OrderBucket bucket;

  /// Orders still being worked on.
  final List<Order> active;

  /// Orders that have been completed/picked up.
  final List<Order> completed;

  /// Error message to display, or null when there is no error.
  final String? error;

  /// The list of orders to display for the selected [bucket].
  List<Order> get visible => bucket == OrderBucket.active ? active : completed;

  /// Returns a copy of this state with the given fields replaced.
  OrdersState copyWith({
    bool? loading,
    OrderBucket? bucket,
    List<Order>? active,
    List<Order>? completed,
    String? error,
  }) {
    return OrdersState(
      loading: loading ?? this.loading,
      bucket: bucket ?? this.bucket,
      active: active ?? this.active,
      completed: completed ?? this.completed,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, bucket, active, completed, error];
}
