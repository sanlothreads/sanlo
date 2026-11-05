import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_stage.dart';

/// Load status of the admin Orders screen.
enum AdminOrdersStatus { initial, loading, loaded, failure }

/// State for the admin Orders screen.
///
/// Holds every loaded order plus the active stage filter and the selected
/// order id. The [filteredOrders], [stageCounts], and [selectedOrder] getters
/// are pure derivations so they can be exercised directly by tests.
class AdminOrdersState extends Equatable {
  const AdminOrdersState({
    this.status = AdminOrdersStatus.initial,
    this.allOrders = const [],
    this.filter,
    this.selectedId,
    this.error,
  });

  final AdminOrdersStatus status;

  /// Every order, before the stage filter is applied.
  final List<AdminOrder> allOrders;

  /// The active stage filter. `null` means "All" (no filtering).
  final OrderStage? filter;

  /// The id of the currently selected order, or null.
  final String? selectedId;

  final String? error;

  /// Orders matching the active [filter] ("All" when null).
  List<AdminOrder> get filteredOrders {
    if (filter == null) return allOrders;
    return allOrders.where((o) => o.stage == filter).toList(growable: false);
  }

  /// Count of orders per stage across [allOrders].
  Map<OrderStage, int> get stageCounts {
    final Map<OrderStage, int> counts = {
      for (final OrderStage s in OrderStage.values) s: 0,
    };
    for (final AdminOrder o in allOrders) {
      counts[o.stage] = (counts[o.stage] ?? 0) + 1;
    }
    return counts;
  }

  /// The currently selected order, or null when none is selected / found.
  AdminOrder? get selectedOrder {
    if (selectedId == null) return null;
    for (final AdminOrder o in allOrders) {
      if (o.id == selectedId) return o;
    }
    return null;
  }

  AdminOrdersState copyWith({
    AdminOrdersStatus? status,
    List<AdminOrder>? allOrders,
    OrderStage? filter,
    bool clearFilter = false,
    String? selectedId,
    bool clearSelection = false,
    String? error,
  }) {
    return AdminOrdersState(
      status: status ?? this.status,
      allOrders: allOrders ?? this.allOrders,
      filter: clearFilter ? null : (filter ?? this.filter),
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, allOrders, filter, selectedId, error];
}
