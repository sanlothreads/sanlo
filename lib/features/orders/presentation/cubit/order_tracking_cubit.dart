import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/order_repository.dart';
import 'order_tracking_state.dart';

/// Drives the order tracking screen: loads a single order and its tracking
/// timeline for a given order id.
class OrderTrackingCubit extends Cubit<OrderTrackingState> {
  OrderTrackingCubit(this._repository)
      : super(const OrderTrackingState.initial());

  final OrderRepository _repository;

  /// Loads the order with [orderId] and its tracking timeline.
  ///
  /// Emits a loading state first, then a populated state on success. If the
  /// order id is unknown ([NotFoundFailure]), emits an error state with the
  /// message "Not found".
  Future<void> load(String orderId) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final order = await _repository.getOrderById(orderId);
      final timeline = await _repository.getTimeline(orderId);
      emit(state.copyWith(
        loading: false,
        order: order,
        timeline: timeline,
      ));
    } on NotFoundFailure {
      emit(state.copyWith(loading: false, error: 'Not found'));
    }
  }
}
