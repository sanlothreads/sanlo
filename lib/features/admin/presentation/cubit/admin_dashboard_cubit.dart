import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_order.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/order_stage.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_dashboard_state.dart';

/// Cubit for the admin Dashboard screen.
///
/// Loads a [DashboardSummary] once and exposes [advanceStage] used by the
/// condensed mobile "Orders to update" list to move a recent order to its next
/// stage. Advancing recomputes the affected per-stage counts in place.
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._repository) : super(const AdminDashboardState());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: AdminDashboardStatus.loading, error: null));
    try {
      final DashboardSummary summary = await _repository.loadDashboard();
      emit(
        state.copyWith(status: AdminDashboardStatus.loaded, summary: summary),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AdminDashboardStatus.failure,
          error: 'Could not load the dashboard, try again',
        ),
      );
    }
  }

  /// Advances the recent order with [orderId] to its next stage, updating both
  /// the order and the per-stage counts. No-op when the order is not found or
  /// already at the final stage.
  void advanceStage(String orderId) {
    final DashboardSummary? summary = state.summary;
    if (summary == null) return;

    final int i = summary.recentOrders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;

    final AdminOrder order = summary.recentOrders[i];
    final OrderStage? next = order.stage.next;
    if (next == null) return;

    final List<AdminOrder> updatedOrders = List.of(summary.recentOrders)
      ..[i] = order.copyWith(stage: next);

    final Map<OrderStage, int> counts = Map.of(summary.stageCounts);
    counts[order.stage] = (counts[order.stage] ?? 1) - 1;
    counts[next] = (counts[next] ?? 0) + 1;

    emit(
      state.copyWith(
        summary: DashboardSummary(
          totalOrders: summary.totalOrders,
          newToday: summary.newToday,
          newTodayNote: summary.newTodayNote,
          inProgress: summary.inProgress,
          inProgressNote: summary.inProgressNote,
          readyToCollect: summary.readyToCollect,
          readyNote: summary.readyNote,
          stageCounts: counts,
          recentOrders: updatedOrders,
        ),
      ),
    );
  }
}
