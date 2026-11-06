import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_stage.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_orders_state.dart';

/// Cubit for the admin Orders screen.
///
/// Loads all orders and listens to realtime database updates, keeping the active stage filter and
/// the selected order in state. Filtering, counts, and the selected order are derived in
/// [AdminOrdersState].
class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  AdminOrdersCubit(this._repository) : super(const AdminOrdersState());

  final AdminRepository _repository;
  StreamSubscription<List<AdminOrder>>? _subscription;

  Future<void> load() async {
    emit(state.copyWith(status: AdminOrdersStatus.loading, error: null));
    await _subscription?.cancel();

    _subscription = _repository.watchOrders().listen(
      (orders) {
        final String? currentSelectedId = state.selectedId;
        final bool selectionStillValid =
            orders.any((o) => o.id == currentSelectedId);
        final String? newSelectedId = selectionStillValid
            ? currentSelectedId
            : (orders.isNotEmpty ? orders.first.id : null);

        emit(
          state.copyWith(
            status: AdminOrdersStatus.loaded,
            allOrders: orders,
            selectedId: newSelectedId,
            clearSelection: !selectionStillValid && orders.isEmpty,
          ),
        );
      },
      onError: (_) {
        emit(
          state.copyWith(
            status: AdminOrdersStatus.failure,
            error: 'Could not load orders, try again',
          ),
        );
      },
    );

    try {
      final List<AdminOrder> initial = await _repository.loadOrders();
      if (state.status == AdminOrdersStatus.loading) {
        final String? currentSelectedId = state.selectedId;
        final bool selectionStillValid =
            initial.any((o) => o.id == currentSelectedId);
        final String? newSelectedId = selectionStillValid
            ? currentSelectedId
            : (initial.isNotEmpty ? initial.first.id : null);

        emit(
          state.copyWith(
            status: AdminOrdersStatus.loaded,
            allOrders: initial,
            selectedId: newSelectedId,
          ),
        );
      }
    } catch (_) {
      if (state.status == AdminOrdersStatus.loading) {
        emit(
          state.copyWith(
            status: AdminOrdersStatus.failure,
            error: 'Could not load orders, try again',
          ),
        );
      }
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
    final bool selectionVisible = visible.any((o) => o.id == state.selectedId);
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

  /// Updates the stage of the selected order directly to [newStage], writing to the database in realtime.
  Future<void> updateSelectedStage(OrderStage newStage) async {
    final AdminOrder? selected = state.selectedOrder;
    if (selected == null || selected.stage == newStage) return;

    final List<AdminOrder> updated = state.allOrders
        .map((o) => o.id == selected.id ? o.copyWith(stage: newStage) : o)
        .toList(growable: false);
    emit(state.copyWith(allOrders: updated));

    try {
      await _repository.updateOrderStage(selected.id, newStage);
    } catch (_) {
      // Stream updates or retry handles reverts
    }
  }

  /// Advances the selected order to its next stage. No-op when nothing is
  /// selected or the order is already at the final stage.
  Future<void> advanceSelected() async {
    final AdminOrder? selected = state.selectedOrder;
    if (selected == null) return;
    final OrderStage? next = selected.stage.next;
    if (next == null) return;

    await updateSelectedStage(next);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
