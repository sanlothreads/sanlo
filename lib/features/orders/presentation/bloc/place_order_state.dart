import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_draft.dart';

/// The current step of the multi-step order flow.
enum OrderStep { details, measurements, review, placing, placed }

/// Sentinel used by [PlaceOrderState.copyWith] to distinguish "leave the
/// current value untouched" from "explicitly set this field to null".
///
/// Passing no argument leaves the field as-is; passing an explicit `null`
/// clears it (e.g. `copyWith(errorMessage: null)` clears the error).
const Object _unset = Object();

/// Immutable state for `PlaceOrderBloc`.
///
/// [draft] is `null` until an [OrderStarted] event initializes the flow; after
/// that it carries the product plus the optional details and measurements.
class PlaceOrderState extends Equatable {
  const PlaceOrderState({
    this.step = OrderStep.details,
    this.draft,
    this.draftId,
    this.placedOrder,
    this.errorMessage,
  });

  /// The current step in the flow.
  final OrderStep step;

  /// The in-progress draft (null before the flow starts).
  final OrderDraft? draft;

  /// The Firestore document ID for this order draft.
  final String? draftId;

  /// The created order, set once placing succeeds.
  final Order? placedOrder;

  /// User-facing error message, or null when there is no error.
  final String? errorMessage;

  /// Returns a copy with the given fields replaced.
  ///
  /// Every nullable field accepts an explicit `null` to clear it, implemented
  /// via a private sentinel: omit the argument to keep the current value, or
  /// pass `null` to clear it. For example `copyWith(errorMessage: null)`
  /// clears the error, while a plain `copyWith(step: ...)` preserves it.
  PlaceOrderState copyWith({
    OrderStep? step,
    Object? draft = _unset,
    Object? draftId = _unset,
    Object? placedOrder = _unset,
    Object? errorMessage = _unset,
  }) {
    return PlaceOrderState(
      step: step ?? this.step,
      draft: identical(draft, _unset) ? this.draft : draft as OrderDraft?,
      draftId: identical(draftId, _unset) ? this.draftId : draftId as String?,
      placedOrder: identical(placedOrder, _unset)
          ? this.placedOrder
          : placedOrder as Order?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [step, draft, draftId, placedOrder, errorMessage];
}
