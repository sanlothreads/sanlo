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

  AdminProduct toEntity() {
    return AdminProduct(
      id: id,
      name: name,
      category: CategoryKind.values.byName(category),
      priceInr: priceInr,
      stitchDays: stitchDays,
      rating: rating,
      photoCount: photoCount,
      visibility: ProductVisibility.values.byName(visibility),
      description: description,
    );
  }
}
