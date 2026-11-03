import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product.dart';
import 'order_status.dart';

/// A placed order being tracked through the stitching lifecycle.
class Order extends Equatable {
  const Order({
    required this.id,
    required this.product,
    required this.placedDate,
    required this.status,
    required this.progress,
    required this.nextStep,
    required this.amountAtShopInr,
    required this.expectedReady,
  });

  /// Order identifier, e.g. "SN-1048" (displayed as "#SN-1048").
  final String id;

  /// The product being stitched.
  final Product product;

  /// When the order was placed.
  final DateTime placedDate;

  /// Current lifecycle status.
  final OrderStatus status;

  /// Progress bar value in the range 0.0..1.0.
  final double progress;

  /// Next upcoming step, e.g. "Stitching started", "Ready for pickup".
  final String nextStep;

  /// Amount payable at the shop (INR).
  final int amountAtShopInr;

  /// Expected ready-for-pickup date.
  final DateTime expectedReady;

  @override
  List<Object?> get props => [
    id,
    product,
    placedDate,
    status,
    progress,
    nextStep,
    amountAtShopInr,
    expectedReady,
  ];
}
