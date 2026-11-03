import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/order_repository.dart';
import 'orders_state.dart';

/// Drives the "My orders" screen: loads active and completed orders and
/// switches the visible bucket.
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repository) : super(const OrdersState.initial());

  final OrderRepository _repository;

  /// Loads both the active and completed order lists.
  ///
  /// Emits a loading state first, then a populated state on success, or an
  /// error state if either fetch fails.
  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final active = await _repository.getOrders(bucket: OrderBucket.active);
      final completed = await _repository.getOrders(
        bucket: OrderBucket.completed,
      );
      emit(
        state.copyWith(loading: false, active: active, completed: completed),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  /// Switches the visible bucket (active or completed).
  void selectBucket(OrderBucket bucket) {
    emit(state.copyWith(bucket: bucket));
  }
}
