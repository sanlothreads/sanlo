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
    this.shortDescription = '',
    this.longDescription = '',
    this.imageUrls = const <String>[],
    this.highlights = const <String>[],
    this.included = const <String>[],
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
  final String shortDescription;
  final String longDescription;
  final List<String> imageUrls;
  final List<String> highlights;
  final List<String> included;

  factory AdminProductModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawUrls =
        map['imageUrls'] as List<dynamic>? ?? map['images'] as List<dynamic>?;
    final List<String> urls = rawUrls != null
        ? rawUrls
              .map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList()
        : <String>[];
    final int count = (map['photoCount'] as num?)?.toInt() ?? urls.length;

    final rawHighlights = map['highlights'] as List<dynamic>?;
    final List<String> hPoints = rawHighlights != null
        ? rawHighlights
              .map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList()
        : <String>[];

    final rawIncluded = map['included'] as List<dynamic>?;
    final List<String> incPoints = rawIncluded != null
        ? rawIncluded
              .map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList()
        : <String>[];

    final String sDesc = map['shortDescription'] as String? ?? '';
    final String lDesc =
        map['longDescription'] as String? ??
        map['description'] as String? ??
        '';

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
      description: lDesc.isNotEmpty ? lDesc : sDesc,
      shortDescription: sDesc,
      longDescription: lDesc,
      imageUrls: urls,
      highlights: hPoints,
      included: incPoints,
    );
  }

  Map<String, dynamic> toMap() {
    final String mainDesc = longDescription.isNotEmpty
        ? longDescription
        : description;
    return {
      'id': id,
      'name': name,
      'category': category,
      'priceInr': priceInr,
      'stitchDays': stitchDays,
      'rating': rating,
      'photoCount': imageUrls.isNotEmpty ? imageUrls.length : photoCount,
      'visibility': visibility,
      'shortDescription': shortDescription,
      'longDescription': mainDesc,
      'description': mainDesc,
      'imageUrls': imageUrls,
      'highlights': highlights,
      'included': included,
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
      shortDescription: entity.shortDescription,
      longDescription: entity.longDescription.isNotEmpty
          ? entity.longDescription
          : entity.description,
      imageUrls: entity.imageUrls,
      highlights: entity.highlights,
      included: entity.included,
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
      description: longDescription.isNotEmpty ? longDescription : description,
      shortDescription: shortDescription,
      longDescription: longDescription.isNotEmpty
          ? longDescription
          : description,
      imageUrls: imageUrls,
      highlights: highlights,
      included: included,
    );
  }
}
