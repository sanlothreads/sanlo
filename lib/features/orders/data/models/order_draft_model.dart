import '../../../catalog/data/models/product_model.dart';
import '../../domain/entities/order_draft.dart';
import 'customer_details_model.dart';
import 'measurement_set_model.dart';

/// Data-layer DTO for [OrderDraft].
///
/// Nests a [ProductModel] plus optional [CustomerDetailsModel] and
/// [MeasurementSetModel] for the in-progress order being built.
class OrderDraftModel {
  const OrderDraftModel({
    required this.product,
    this.details,
    this.measurements,
  });

  final ProductModel product;
  final CustomerDetailsModel? details;
  final MeasurementSetModel? measurements;

  factory OrderDraftModel.fromJson(Map<String, dynamic> json) {
    return OrderDraftModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      details: json['details'] == null
          ? null
          : CustomerDetailsModel.fromJson(
              json['details'] as Map<String, dynamic>,
            ),
      measurements: json['measurements'] == null
          ? null
          : MeasurementSetModel.fromJson(
              json['measurements'] as Map<String, dynamic>,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'details': details?.toJson(),
      'measurements': measurements?.toJson(),
    };
  }

  factory OrderDraftModel.fromEntity(OrderDraft entity) {
    return OrderDraftModel(
      product: ProductModel.fromEntity(entity.product),
      details: entity.details == null
          ? null
          : CustomerDetailsModel.fromEntity(entity.details!),
      measurements: entity.measurements == null
          ? null
          : MeasurementSetModel.fromEntity(entity.measurements!),
    );
  }

  OrderDraft toEntity() {
    return OrderDraft(
      product: product.toEntity(),
      details: details?.toEntity(),
      measurements: measurements?.toEntity(),
    );
  }
}
