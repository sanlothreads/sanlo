import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/category.dart';

/// Whether a product is shown to customers or hidden from the catalog.
enum ProductVisibility { live, hidden }

/// Display helpers for [ProductVisibility].
extension ProductVisibilityX on ProductVisibility {
  String get label => this == ProductVisibility.live ? 'Live' : 'Hidden';
}

/// A catalog product row as managed on the admin Products screen.
class AdminProduct extends Equatable {
  const AdminProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.priceInr,
    required this.stitchDays,
    required this.rating,
    required this.photoCount,
    required this.visibility,
    this.description = '',
    this.shortDescription = '',
    this.longDescription = '',
    this.imageUrls = const <String>[],
    this.highlights = const <String>[],
    this.included = const <String>[],
  });

  /// Stable identifier, e.g. "p_formal_shirt".
  final String id;

  /// Display name, e.g. "Designer Blouse".
  final String name;

  /// Category (women / men / kids). [CategoryKind.all] is not a valid product
  /// category.
  final CategoryKind category;

  /// Price in Indian rupees.
  final int priceInr;

  /// Turnaround in days.
  final int stitchDays;

  /// Average rating, e.g. 4.8.
  final double rating;

  /// Number of photos attached.
  final int photoCount;

  /// Whether the product is live or hidden.
  final ProductVisibility visibility;

  /// Optional long description entered on the form.
  final String description;

  /// Short 1-line summary / tagline for the product.
  final String shortDescription;

  /// Detailed long description entered on the form.
  final String longDescription;

  /// List of image URLs attached to this product (min 1, max 6).
  final List<String> imageUrls;

  /// Key feature/highlight points for this product.
  final List<String> highlights;

  /// Included-items checklist (e.g. "Lining and finishing", "One free alteration").
  final List<String> included;

  AdminProduct copyWith({
    String? id,
    String? name,
    CategoryKind? category,
    int? priceInr,
    int? stitchDays,
    double? rating,
    int? photoCount,
    ProductVisibility? visibility,
    String? description,
    String? shortDescription,
    String? longDescription,
    List<String>? imageUrls,
    List<String>? highlights,
    List<String>? included,
  }) {
    final String lDesc = longDescription ?? this.longDescription;
    final String sDesc = shortDescription ?? this.shortDescription;
    final String desc = description ?? (lDesc.isNotEmpty ? lDesc : sDesc);

    return AdminProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      priceInr: priceInr ?? this.priceInr,
      stitchDays: stitchDays ?? this.stitchDays,
      rating: rating ?? this.rating,
      photoCount: photoCount ?? this.photoCount,
      visibility: visibility ?? this.visibility,
      description: desc,
      shortDescription: sDesc,
      longDescription: lDesc.isNotEmpty ? lDesc : desc,
      imageUrls: imageUrls ?? this.imageUrls,
      highlights: highlights ?? this.highlights,
      included: included ?? this.included,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    priceInr,
    stitchDays,
    rating,
    photoCount,
    visibility,
    description,
    shortDescription,
    longDescription,
    imageUrls,
    highlights,
    included,
  ];
}
