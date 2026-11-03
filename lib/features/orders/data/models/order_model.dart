import '../../../catalog/data/models/product_model.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';

/// Data-layer DTO for [Order].
///
/// Nests a [ProductModel], serialises [OrderStatus] as its enum name, and
/// dates as ISO-8601 strings.
class OrderModel {
  const OrderModel({
    required this.id,
    required this.product,
    required this.placedDate,
    required this.status,
    required this.progress,
    required this.nextStep,
    required this.amountAtShopInr,
    required this.expectedReady,
  });

  final String id;
  final ProductModel product;
  final String placedDate;
  final String status;
  final double progress;
  final String nextStep;
  final int amountAtShopInr;
  final String expectedReady;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      placedDate: json['placedDate'] as String,
      status: json['status'] as String,
      progress: (json['progress'] as num).toDouble(),
      nextStep: json['nextStep'] as String,
      amountAtShopInr: json['amountAtShopInr'] as int,
      expectedReady: json['expectedReady'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'placedDate': placedDate,
      'status': status,
      'progress': progress,
      'nextStep': nextStep,
      'amountAtShopInr': amountAtShopInr,
      'expectedReady': expectedReady,
    };
  }

  factory OrderModel.fromEntity(Order entity) {
    return OrderModel(
      id: entity.id,
      product: ProductModel.fromEntity(entity.product),
      placedDate: entity.placedDate.toIso8601String(),
      status: entity.status.name,
      progress: entity.progress,
      nextStep: entity.nextStep,
      amountAtShopInr: entity.amountAtShopInr,
      expectedReady: entity.expectedReady.toIso8601String(),
    );
  }

  Order toEntity() {
    return Order(
      id: id,
      product: product.toEntity(),
      placedDate: DateTime.parse(placedDate),
      status: OrderStatus.values.byName(status),
      progress: progress,
      nextStep: nextStep,
      amountAtShopInr: amountAtShopInr,
      expectedReady: DateTime.parse(expectedReady),
    );
  }
}
