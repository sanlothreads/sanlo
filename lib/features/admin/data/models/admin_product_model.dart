import '../../../catalog/domain/entities/category.dart';
import '../../domain/entities/admin_product.dart';

/// Data-layer DTO for [AdminProduct].
class AdminProductModel {
  const AdminProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.priceInr,
    required this.stitchDays,
    required this.rating,
    required this.photoCount,
    required this.visibility,
    this.description = '',
    this.imageUrls = const <String>[],
  });

  final String id;
  final String name;
  final String category;
  final int priceInr;
  final int stitchDays;
  final double rating;
  final int photoCount;
  final String visibility;
  final String description;
  final List<String> imageUrls;

  factory AdminProductModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawUrls = map['imageUrls'] as List<dynamic>? ?? map['images'] as List<dynamic>?;
    final List<String> urls = rawUrls != null
        ? rawUrls.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList()
        : <String>[];
    final int count = (map['photoCount'] as num?)?.toInt() ?? urls.length;

    return AdminProductModel(
      id: (map['id'] as String?)?.isNotEmpty == true
          ? map['id'] as String
          : docId,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'women',
      priceInr: (map['priceInr'] as num?)?.toInt() ?? 0,
      stitchDays: (map['stitchDays'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      photoCount: urls.isNotEmpty ? urls.length : count,
      visibility: map['visibility'] as String? ?? 'live',
      description: map['description'] as String? ?? '',
      imageUrls: urls,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'priceInr': priceInr,
      'stitchDays': stitchDays,
      'rating': rating,
      'photoCount': imageUrls.isNotEmpty ? imageUrls.length : photoCount,
      'visibility': visibility,
      'description': description,
      'imageUrls': imageUrls,
    };
  }

  factory AdminProductModel.fromEntity(AdminProduct entity) {
    return AdminProductModel(
      id: entity.id,
      name: entity.name,
      category: entity.category.name,
      priceInr: entity.priceInr,
      stitchDays: entity.stitchDays,
      rating: entity.rating,
      photoCount: entity.imageUrls.isNotEmpty
          ? entity.imageUrls.length
          : entity.photoCount,
      visibility: entity.visibility.name,
      description: entity.description,
      imageUrls: entity.imageUrls,
    );
  }

  AdminProduct toEntity() {
    CategoryKind catKind;
    try {
      catKind = CategoryKind.values.byName(category);
    } catch (_) {
      catKind = CategoryKind.women;
    }

    ProductVisibility vis;
    try {
      vis = ProductVisibility.values.byName(visibility);
    } catch (_) {
      vis = ProductVisibility.live;
    }

    return AdminProduct(
      id: id,
      name: name,
      category: catKind,
      priceInr: priceInr,
      stitchDays: stitchDays,
      rating: rating,
      photoCount: imageUrls.isNotEmpty ? imageUrls.length : photoCount,
      visibility: vis,
      description: description,
      imageUrls: imageUrls,
    );
  }
}
