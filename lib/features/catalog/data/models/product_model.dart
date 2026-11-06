import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

/// Data-layer DTO for [Product]. Serialises [CategoryKind] as its enum name.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.category,
    required this.name,
    required this.typeLabel,
    required this.rating,
    required this.readyInDays,
    required this.priceInr,
    required this.imageCount,
    this.shortDescription = '',
    this.imageUrls = const <String>[],
  });

  final String id;
  final String category;
  final String name;
  final String typeLabel;
  final double rating;
  final int readyInDays;
  final int priceInr;
  final int imageCount;
  final String shortDescription;
  final List<String> imageUrls;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawUrls =
        json['imageUrls'] as List<dynamic>? ?? json['images'] as List<dynamic>?;
    final List<String> urls = rawUrls != null
        ? rawUrls
              .map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList()
        : <String>[];

    return ProductModel(
      id: json['id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      typeLabel: json['typeLabel'] as String,
      rating: (json['rating'] as num).toDouble(),
      readyInDays: json['readyInDays'] as int,
      priceInr: json['priceInr'] as int,
      imageCount: json['imageCount'] as int,
      shortDescription: json['shortDescription'] as String? ?? '',
      imageUrls: urls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'typeLabel': typeLabel,
      'rating': rating,
      'readyInDays': readyInDays,
      'priceInr': priceInr,
      'imageCount': imageCount,
      'shortDescription': shortDescription,
      'imageUrls': imageUrls,
    };
  }

  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      category: entity.category.name,
      name: entity.name,
      typeLabel: entity.typeLabel,
      rating: entity.rating,
      readyInDays: entity.readyInDays,
      priceInr: entity.priceInr,
      imageCount: entity.imageCount,
      shortDescription: entity.shortDescription,
      imageUrls: entity.imageUrls,
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      category: CategoryKind.values.byName(category),
      name: name,
      typeLabel: typeLabel,
      rating: rating,
      readyInDays: readyInDays,
      priceInr: priceInr,
      imageCount: imageCount,
      shortDescription: shortDescription,
      imageUrls: imageUrls,
    );
  }
}
