import '../../../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/style_detail.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/style_detail_model.dart';

/// In-memory [ProductRepository] seeded with the catalog shown in the mockups.
///
/// The seed data is expressed as DTO models ([ProductModel] / [CategoryModel])
/// and mapped to domain entities via `toEntity()`, matching how a real
/// network/JSON-backed implementation would behave.
class MockProductRepository implements ProductRepository {
  /// Small artificial latency to mimic a network round-trip.
  static const _latency = Duration(milliseconds: 150);

  /// The selectable category filters: All, Women, Men, Kids.
  static const List<CategoryModel> _categories = [
    CategoryModel(kind: 'all', label: 'All'),
    CategoryModel(kind: 'women', label: 'Women'),
    CategoryModel(kind: 'men', label: 'Men'),
    CategoryModel(kind: 'kids', label: 'Kids'),
  ];

  /// The six seeded products.
  static const List<ProductModel> _products = [
    ProductModel(
      id: 'p_blouse',
      category: 'women',
      name: 'Designer Blouse',
      typeLabel: 'Blouse',
      rating: 4.8,
      readyInDays: 5,
      priceInr: 650,
      imageCount: 4,
      imageUrls: [
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=500&auto=format&fit=crop',
      ],
    ),
    ProductModel(
      id: 'p_anarkali',
      category: 'women',
      name: 'Anarkali Kurti',
      typeLabel: 'Kurti',
      rating: 4.7,
      readyInDays: 7,
      priceInr: 900,
      imageCount: 4,
      imageUrls: [
        'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=500&auto=format&fit=crop',
      ],
    ),
    ProductModel(
      id: 'p_shirt',
      category: 'men',
      name: 'Formal Shirt',
      typeLabel: 'Shirt',
      rating: 4.6,
      readyInDays: 4,
      priceInr: 550,
      imageCount: 4,
      imageUrls: [
        'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=500&auto=format&fit=crop',
      ],
    ),
    ProductModel(
      id: 'p_kurta',
      category: 'men',
      name: 'Kurta Pajama',
      typeLabel: 'Kurta set',
      rating: 4.8,
      readyInDays: 6,
      priceInr: 1000,
      imageCount: 4,
      imageUrls: [
        'https://images.unsplash.com/photo-1597983073493-88cd35cfa3d0?w=500&auto=format&fit=crop',
      ],
    ),
    ProductModel(
      id: 'p_frock',
      category: 'kids',
      name: 'Kids Frock',
      typeLabel: 'Frock',
      rating: 4.9,
      readyInDays: 3,
      priceInr: 450,
      imageCount: 4,
      imageUrls: [
        'https://images.unsplash.com/photo-1518831959646-742c3a14ebf7?w=500&auto=format&fit=crop',
      ],
    ),
    ProductModel(
      id: 'p_salwar',
      category: 'women',
      name: 'Salwar Suit',
      typeLabel: 'Suit',
      rating: 4.7,
      readyInDays: 8,
      priceInr: 1100,
      imageCount: 4,
      imageUrls: [
        'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=500&auto=format&fit=crop',
      ],
    ),
  ];

  @override
  Future<List<Category>> getCategories() async {
    await Future<void>.delayed(_latency);
    return _categories.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<List<Product>> getProducts({Category? filter}) async {
    await Future<void>.delayed(_latency);
    final kind = filter?.kind ?? CategoryKind.all;
    final products = _products.map((m) => m.toEntity());
    if (kind == CategoryKind.all) {
      return products.toList(growable: false);
    }
    return products.where((p) => p.category == kind).toList(growable: false);
  }

  @override
  Future<StyleDetail> getProductDetail(String productId) async {
    await Future<void>.delayed(_latency);
    final model = _products.where((p) => p.id == productId).firstOrNull;
    if (model == null) {
      throw NotFoundFailure('No product with id "$productId"');
    }
    return _buildStyleDetail(model).toEntity();
  }

  /// Builds a [StyleDetailModel] for [product], deriving the descriptive and
  /// order-related fields from the product itself.
  StyleDetailModel _buildStyleDetail(ProductModel product) {
    return StyleDetailModel(
      product: product,
      categoryLabel: _categoryLabel(product.category),
      aboutText:
          'A ${product.name.toLowerCase()} stitched to your measurements by '
          'our tailors. Ready in about ${product.readyInDays} days, with a '
          'focus on clean finishing and a comfortable fit.',
      included: const [
        'Lining and finishing',
        'One free alteration after trial',
        "Measurement at shop if you're not sure",
      ],
      variantLabels: const ['Color 1', 'Color 2', 'Color 3', 'Color 4'],
      stitchingChargeInr: product.priceInr,
      paymentLabel: 'At shop',
    );
  }

  /// Maps a stored category name to the label shown on the details screen.
  String _categoryLabel(String categoryName) {
    final match = _categories.where((c) => c.kind == categoryName).firstOrNull;
    if (match != null) {
      return match.label;
    }
    // Fallback: capitalise the raw name.
    if (categoryName.isEmpty) return categoryName;
    return categoryName[0].toUpperCase() + categoryName.substring(1);
  }
}
