import '../../domain/entities/style_detail.dart';
import 'product_model.dart';

/// Data-layer DTO for [StyleDetail]. Nests a [ProductModel] for its product.
class StyleDetailModel {
  const StyleDetailModel({
    required this.product,
    required this.categoryLabel,
    required this.aboutText,
    required this.included,
    required this.variantLabels,
    required this.stitchingChargeInr,
    required this.paymentLabel,
  });

  final ProductModel product;
  final String categoryLabel;
  final String aboutText;
  final List<String> included;
  final List<String> variantLabels;
  final int stitchingChargeInr;
  final String paymentLabel;

  factory StyleDetailModel.fromJson(Map<String, dynamic> json) {
    return StyleDetailModel(
      product:
          ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      categoryLabel: json['categoryLabel'] as String,
      aboutText: json['aboutText'] as String,
      included: (json['included'] as List<dynamic>).cast<String>(),
      variantLabels:
          (json['variantLabels'] as List<dynamic>).cast<String>(),
      stitchingChargeInr: json['stitchingChargeInr'] as int,
      paymentLabel: json['paymentLabel'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'categoryLabel': categoryLabel,
      'aboutText': aboutText,
      'included': included,
      'variantLabels': variantLabels,
      'stitchingChargeInr': stitchingChargeInr,
      'paymentLabel': paymentLabel,
    };
  }

  factory StyleDetailModel.fromEntity(StyleDetail entity) {
    return StyleDetailModel(
      product: ProductModel.fromEntity(entity.product),
      categoryLabel: entity.categoryLabel,
      aboutText: entity.aboutText,
      included: entity.included,
      variantLabels: entity.variantLabels,
      stitchingChargeInr: entity.stitchingChargeInr,
      paymentLabel: entity.paymentLabel,
    );
  }

  StyleDetail toEntity() {
    return StyleDetail(
      product: product.toEntity(),
      categoryLabel: categoryLabel,
      aboutText: aboutText,
      included: included,
      variantLabels: variantLabels,
      stitchingChargeInr: stitchingChargeInr,
      paymentLabel: paymentLabel,
    );
  }
}
