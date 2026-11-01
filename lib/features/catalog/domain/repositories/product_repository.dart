import '../entities/category.dart';
import '../entities/product.dart';
import '../entities/style_detail.dart';

/// Contract for reading the catalog of tailoring styles.
///
/// [getProductDetail] throws a `NotFoundFailure` when no product matches the
/// given id.
abstract interface class ProductRepository {
  /// Returns the selectable categories: All, Women, Men, Kids.
  Future<List<Category>> getCategories();

  /// Returns products for the given [filter]. A `null` filter, or a filter
  /// whose kind is [CategoryKind.all], returns every product.
  Future<List<Product>> getProducts({Category? filter});

  /// Returns the full style detail for [productId]; throws a `NotFoundFailure`
  /// when the id is unknown.
  Future<StyleDetail> getProductDetail(String productId);
}
