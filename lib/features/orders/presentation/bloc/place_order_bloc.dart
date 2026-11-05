import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_draft.dart';
import '../../domain/repositories/order_repository.dart';
import 'place_order_event.dart';
import 'place_order_state.dart';

/// Multi-step state machine for placing an order:
/// `details -> measurements -> review -> placing -> placed`.
///
/// A single instance is provided above the three order step routes so the
/// [OrderDraft] (product + details + measurements) is preserved across steps.
class PlaceOrderBloc extends Bloc<PlaceOrderEvent, PlaceOrderState> {
  PlaceOrderBloc({required OrderRepository orderRepository})
    : _orderRepository = orderRepository,
      super(const PlaceOrderState()) {
    on<OrderStarted>(_onOrderStarted);
    on<CustomerDetailsSubmitted>(_onCustomerDetailsSubmitted);
    on<MeasurementsSubmitted>(_onMeasurementsSubmitted);
    on<EditDetailsRequested>(_onEditDetailsRequested);
    on<EditMeasurementsRequested>(_onEditMeasurementsRequested);
    on<OrderPlaced>(_onOrderPlaced);
  }

  final OrderRepository _orderRepository;

  Future<void> _onOrderStarted(
    OrderStarted event,
    Emitter<PlaceOrderState> emit,
  ) async {
    emit(
      PlaceOrderState(
        step: OrderStep.details,
        draft: OrderDraft(product: event.product),
      ),
    );
    try {
      final String draftId = await _orderRepository.createDraftOrder(event.product);
      emit(state.copyWith(draftId: draftId));
    } catch (_) {}
  }

  Future<void> _onCustomerDetailsSubmitted(
    CustomerDetailsSubmitted event,
    Emitter<PlaceOrderState> emit,
  ) async {
    final draft = state.draft;
    if (draft == null) return;
    final updatedDraft = draft.copyWith(details: event.details);
    emit(
      state.copyWith(
        draft: updatedDraft,
        step: OrderStep.measurements,
      ),
    );
    final String? draftId = state.draftId;
    if (draftId != null && draftId.isNotEmpty) {
      try {
        await _orderRepository.updateDraftDetails(
          draftId: draftId,
          details: event.details,
        );
      } catch (_) {}
    }
  }

  Future<void> _onMeasurementsSubmitted(
    MeasurementsSubmitted event,
    Emitter<PlaceOrderState> emit,
  ) async {
    final draft = state.draft;
    if (draft == null) return;
    final updatedDraft = draft.copyWith(measurements: event.measurements);
    emit(
      state.copyWith(
        draft: updatedDraft,
        step: OrderStep.review,
      ),
    );
    final String? draftId = state.draftId;
    if (draftId != null && draftId.isNotEmpty) {
      try {
        await _orderRepository.updateDraftMeasurements(
          draftId: draftId,
          measurements: event.measurements,
        );
      } catch (_) {}
    }
  }

  void _onEditDetailsRequested(
    EditDetailsRequested event,
    Emitter<PlaceOrderState> emit,
  ) {
    // Draft preserved; only the step changes.
    emit(state.copyWith(step: OrderStep.details));
  }

  void _onEditMeasurementsRequested(
    EditMeasurementsRequested event,
    Emitter<PlaceOrderState> emit,
  ) {
    // Draft preserved; only the step changes.
    emit(state.copyWith(step: OrderStep.measurements));
  }

  Future<void> _onOrderPlaced(
    OrderPlaced event,
    Emitter<PlaceOrderState> emit,
  ) async {
    final draft = state.draft;
    if (draft == null || !draft.isReadyToPlace) {
      emit(state.copyWith(errorMessage: 'Complete all steps first'));
      return;
    }

    emit(state.copyWith(step: OrderStep.placing));
    try {
      final Order order = await _orderRepository.placeOrder(
        draft,
        draftId: state.draftId,
      );
      emit(
        state.copyWith(
          step: OrderStep.placed,
          placedOrder: order,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          step: OrderStep.review,
          errorMessage: 'Could not place order, try again',
        ),
      );
    }
  }
}
