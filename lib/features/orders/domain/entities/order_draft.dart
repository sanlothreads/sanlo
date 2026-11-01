import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product.dart';
import 'customer_details.dart';
import 'measurement_set.dart';

/// Mutable-by-copy aggregate carried across the 3 order steps
/// (details -> measurements -> review).
class OrderDraft extends Equatable {
  const OrderDraft({
    required this.product,
    this.details,
    this.measurements,
  });

  /// The product being ordered (set when the flow starts).
  final Product product;

  /// Customer details, set in step 1.
  final CustomerDetails? details;

  /// Measurements, set in step 2.
  final MeasurementSet? measurements;

  /// Whether the draft has all required parts to be placed.
  bool get isReadyToPlace => details != null && measurements != null;

  /// Returns a copy of this draft with the given fields replaced.
  OrderDraft copyWith({
    Product? product,
    CustomerDetails? details,
    MeasurementSet? measurements,
  }) {
    return OrderDraft(
      product: product ?? this.product,
      details: details ?? this.details,
      measurements: measurements ?? this.measurements,
    );
  }

  @override
  List<Object?> get props => [product, details, measurements];
}
