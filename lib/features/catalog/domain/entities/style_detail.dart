import 'package:equatable/equatable.dart';

import 'product.dart';

/// The full style detail shown on the Product details screen, wrapping a
/// [Product] with the descriptive and order-related information.
class StyleDetail extends Equatable {
  const StyleDetail({
    required this.product,
    required this.categoryLabel,
    required this.aboutText,
    required this.included,
    required this.variantLabels,
    required this.stitchingChargeInr,
    required this.paymentLabel,
    this.highlights = const <String>[],
  });

  /// The product this detail describes.
  final Product product;

  /// Human-readable category label, e.g. "Women".
  final String categoryLabel;

  /// "About this style" description text.
  final String aboutText;

  /// Included-items checklist.
  final List<String> included;

  /// Product highlight points.
  final List<String> highlights;

  /// Labels for the selectable variant/color thumbnails.
  final List<String> variantLabels;

  /// Stitching charge in Indian rupees shown in the bottom bar.
  final int stitchingChargeInr;

  /// Payment label, e.g. "At shop".
  final String paymentLabel;

  StyleDetail copyWith({
    Product? product,
    String? categoryLabel,
    String? aboutText,
    List<String>? included,
    List<String>? highlights,
    List<String>? variantLabels,
    int? stitchingChargeInr,
    String? paymentLabel,
  }) {
    return StyleDetail(
      product: product ?? this.product,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      aboutText: aboutText ?? this.aboutText,
      included: included ?? this.included,
      highlights: highlights ?? this.highlights,
      variantLabels: variantLabels ?? this.variantLabels,
      stitchingChargeInr: stitchingChargeInr ?? this.stitchingChargeInr,
      paymentLabel: paymentLabel ?? this.paymentLabel,
    );
  }

  @override
  List<Object?> get props => [
    product,
    categoryLabel,
    aboutText,
    included,
    highlights,
    variantLabels,
    stitchingChargeInr,
    paymentLabel,
  ];
}
