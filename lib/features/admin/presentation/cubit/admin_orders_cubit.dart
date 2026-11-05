import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_stage.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_orders_state.dart';

/// Cubit for the admin Orders screen.
///
/// Loads all orders, then keeps the active stage filter and the selected order
/// in state. Filtering, counts, and the selected order are derived in
/// [AdminOrdersState]. [advanceSelected] moves the selected order to its next
/// stage (no-op at the final stage).
class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  AdminOrdersCubit(this._repository) : super(const AdminOrdersState());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: AdminOrdersStatus.loading, error: null));
    try {
      final List<AdminOrder> orders = await _repository.loadOrders();
      emit(
        state.copyWith(
          status: AdminOrdersStatus.loaded,
          allOrders: orders,
          // Default-select the first order so the detail panel is populated.
          selectedId: orders.isNotEmpty ? orders.first.id : null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AdminOrdersStatus.failure,
          error: 'Could not load orders, try again',
        ),
      );
    }
  }

  /// Applies the given stage [filter] (null = "All") and keeps the selection
  /// valid by defaulting to the first order of the new filtered list when the
  /// current selection falls outside it.
  void selectFilter(OrderStage? filter) {
    final AdminOrdersState next = state.copyWith(
      filter: filter,
      clearFilter: filter == null,
    );
    final List<AdminOrder> visible = next.filteredOrders;
    final bool selectionVisible =
        visible.any((o) => o.id == state.selectedId);
    emit(
      next.copyWith(
        selectedId: selectionVisible
            ? state.selectedId
            : (visible.isNotEmpty ? visible.first.id : null),
        clearSelection: !selectionVisible && visible.isEmpty,
      ),
    );
  }

  /// Selects the order with [orderId].
  void selectOrder(String orderId) {
    emit(state.copyWith(selectedId: orderId));
  }

  /// Advances the selected order to its next stage. No-op when nothing is
  /// selected or the order is already at the final stage.
  void advanceSelected() {
    final AdminOrder? selected = state.selectedOrder;
    if (selected == null) return;
    final OrderStage? next = selected.stage.next;
    if (next == null) return;

    final List<AdminOrder> updated = state.allOrders
        .map((o) => o.id == selected.id ? o.copyWith(stage: next) : o)
        .toList(growable: false);
    emit(state.copyWith(allOrders: updated));
  }
}
