import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/customer_details.dart';
import '../../domain/entities/measurement_set.dart';

/// Events that drive the multi-step order flow managed by `PlaceOrderBloc`.
sealed class PlaceOrderEvent extends Equatable {
  const PlaceOrderEvent();

  @override
  List<Object?> get props => [];
}

/// Starts a new order flow for [product] (resets to step `details`).
final class OrderStarted extends PlaceOrderEvent {
  const OrderStarted({required this.product});

  /// The product being ordered.
  final Product product;

  @override
  List<Object?> get props => [product];
}

/// Submits the step-1 customer details and advances to measurements.
final class CustomerDetailsSubmitted extends PlaceOrderEvent {
  const CustomerDetailsSubmitted({required this.details});

  /// Customer-provided contact details.
  final CustomerDetails details;

  @override
  List<Object?> get props => [details];
}

/// Submits the step-2 measurements and advances to review.
final class MeasurementsSubmitted extends PlaceOrderEvent {
  const MeasurementsSubmitted({required this.measurements});

  /// Captured measurements ("Not sure" with null fields is still valid).
  final MeasurementSet measurements;

  @override
  List<Object?> get props => [measurements];
}

/// Requests returning to the details step to edit (draft preserved).
final class EditDetailsRequested extends PlaceOrderEvent {
  const EditDetailsRequested();
}

/// Requests returning to the measurements step to edit (draft preserved).
final class EditMeasurementsRequested extends PlaceOrderEvent {
  const EditMeasurementsRequested();
}

/// Attempts to place the order from the review step.
final class OrderPlaced extends PlaceOrderEvent {
  const OrderPlaced();
}
