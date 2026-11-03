import 'package:equatable/equatable.dart';

import 'category.dart';

/// A tailoring style shown in the catalog grid and on the product details
/// screen.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.category,
    required this.name,
    required this.typeLabel,
    required this.rating,
    required this.readyInDays,
    required this.priceInr,
    required this.imageCount,
  });

  /// Stable identifier, e.g. "p_blouse".
  final String id;

  /// The category this product belongs to (women / men / kids).
  final CategoryKind category;

  /// Display name, e.g. "Designer Blouse".
  final String name;

  /// Short type label, e.g. "Blouse", "Kurti", "Shirt".
  final String typeLabel;

  /// Average rating, e.g. 4.8.
  final double rating;

  /// Turnaround in days, e.g. 5.
  final int readyInDays;

  /// Price in Indian rupees, e.g. 650.
  final int priceInr;

  /// Number of placeholder images, used for "[Photo x of N]" captions.
  final int imageCount;

  Product copyWith({
    String? id,
    CategoryKind? category,
    String? name,
    String? typeLabel,
    double? rating,
    int? readyInDays,
    int? priceInr,
    int? imageCount,
  }) {
    return Product(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      typeLabel: typeLabel ?? this.typeLabel,
      rating: rating ?? this.rating,
      readyInDays: readyInDays ?? this.readyInDays,
      priceInr: priceInr ?? this.priceInr,
      imageCount: imageCount ?? this.imageCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    category,
    name,
    typeLabel,
    rating,
    readyInDays,
    priceInr,
    imageCount,
  ];
}
