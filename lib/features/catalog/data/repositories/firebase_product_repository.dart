import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/style_detail.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/category_model.dart';
import 'mock_product_repository.dart';

///
/// Reads saved products directly from the `products` collection in Firestore.
class FirebaseProductRepository implements ProductRepository {
  FirebaseProductRepository({
    FirebaseFirestore? firestore,
    MockProductRepository? fallbackMock,
  }) : _injectedFirestore = firestore,
       _mockFallback = fallbackMock ?? MockProductRepository();

  final FirebaseFirestore? _injectedFirestore;
  final MockProductRepository _mockFallback;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  static const List<CategoryModel> _categories = [
    CategoryModel(kind: 'all', label: 'All'),
    CategoryModel(kind: 'women', label: 'Women'),
    CategoryModel(kind: 'men', label: 'Men'),
    CategoryModel(kind: 'kids', label: 'Kids'),
  ];

  @override
  Future<List<Category>> getCategories() async {
    return _categories.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<List<Product>> getProducts({Category? filter}) async {
    try {
      final snapshot = await _productsRef.get();
      if (snapshot.docs.isEmpty) {
        return _mockFallback.getProducts(filter: filter);
      }

      final kind = filter?.kind ?? CategoryKind.all;
      final List<Product> products = [];

      for (final doc in snapshot.docs) {
        final map = doc.data();
        final String visibility = map['visibility'] as String? ?? 'live';
        if (visibility != 'live') continue;

        final String category = map['category'] as String? ?? 'women';
        if (kind != CategoryKind.all && category != kind.name) continue;

        final String name = map['name'] as String? ?? '';
        final int priceInr = (map['priceInr'] as num?)?.toInt() ?? 0;
        final int stitchDays = (map['stitchDays'] as num?)?.toInt() ?? 0;
        final double rating = (map['rating'] as num?)?.toDouble() ?? 0.0;
        final rawUrls =
            map['imageUrls'] as List<dynamic>? ??
            map['images'] as List<dynamic>?;
        final List<String> imageUrls = rawUrls != null
            ? rawUrls
                  .map((e) => e.toString())
                  .where((s) => s.trim().isNotEmpty)
                  .toList()
            : <String>[];
        final int photoCount = imageUrls.isNotEmpty
            ? imageUrls.length
            : ((map['photoCount'] as num?)?.toInt() ?? 1);
        final String shortDesc = map['shortDescription'] as String? ?? '';

        products.add(
          Product(
            id: doc.id,
            category: _parseCategoryKind(category),
            name: name,
            typeLabel: _deriveTypeLabel(name),
            rating: rating,
            readyInDays: stitchDays,
            priceInr: priceInr,
            imageCount: photoCount,
            shortDescription: shortDesc,
            imageUrls: imageUrls,
          ),
        );
      }

      return products;
    } catch (_) {
      return _mockFallback.getProducts(filter: filter);
    }
  }

  @override
  Future<StyleDetail> getProductDetail(String productId) async {
    try {
      final doc = await _productsRef.doc(productId).get();
      if (!doc.exists || doc.data() == null) {
        return _mockFallback.getProductDetail(productId);
      }

      final map = doc.data()!;
      final String name = map['name'] as String? ?? '';
      final String category = map['category'] as String? ?? 'women';
      final int priceInr = (map['priceInr'] as num?)?.toInt() ?? 0;
      final int stitchDays = (map['stitchDays'] as num?)?.toInt() ?? 0;
      final double rating = (map['rating'] as num?)?.toDouble() ?? 0.0;
      final rawUrls =
          map['imageUrls'] as List<dynamic>? ?? map['images'] as List<dynamic>?;
      final List<String> imageUrls = rawUrls != null
          ? rawUrls
                .map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList()
          : <String>[];
      final int photoCount = imageUrls.isNotEmpty
          ? imageUrls.length
          : ((map['photoCount'] as num?)?.toInt() ?? 1);

      final String shortDesc = map['shortDescription'] as String? ?? '';
      final String longDesc =
          map['longDescription'] as String? ??
          map['description'] as String? ??
          '';
      final String description = longDesc.isNotEmpty ? longDesc : shortDesc;

      final product = Product(
        id: doc.id,
        category: _parseCategoryKind(category),
        name: name,
        typeLabel: _deriveTypeLabel(name),
        rating: rating,
        readyInDays: stitchDays,
        priceInr: priceInr,
        imageCount: photoCount,
        shortDescription: shortDesc,
        imageUrls: imageUrls,
      );

      final aboutText = description.isNotEmpty
          ? description
          : 'A ${name.toLowerCase()} stitched to your measurements by our tailors. Ready in about $stitchDays days.';

      final rawIncluded = map['included'] as List<dynamic>?;
      final List<String> includedList =
          rawIncluded != null && rawIncluded.isNotEmpty
          ? rawIncluded
                .map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList()
          : const [
              'Lining and finishing',
              'One free alteration after trial',
              "Measurement at shop if you're not sure",
            ];

      final rawHighlights = map['highlights'] as List<dynamic>?;
      final List<String> highlightsList = rawHighlights != null
          ? rawHighlights
                .map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList()
          : <String>[];

      final List<String> variantLabels = imageUrls.isNotEmpty
          ? List.generate(imageUrls.length, (i) => 'Photo ${i + 1}')
          : const ['Color 1', 'Color 2', 'Color 3', 'Color 4'];

      return StyleDetail(
        product: product,
        categoryLabel: _categoryLabel(category),
        aboutText: aboutText,
        included: includedList,
        highlights: highlightsList,
        variantLabels: variantLabels,
        stitchingChargeInr: priceInr,
        paymentLabel: 'At shop',
      );
    } catch (_) {
      return _mockFallback.getProductDetail(productId);
    }
  }

  CategoryKind _parseCategoryKind(String name) {
    try {
      return CategoryKind.values.byName(name);
    } catch (_) {
      return CategoryKind.women;
    }
  }

  String _deriveTypeLabel(String productName) {
    if (productName.isEmpty) return 'Custom Stitch';
    final parts = productName.split(' ');
    return parts.last;
  }

  String _categoryLabel(String categoryName) {
    final match = _categories.where((c) => c.kind == categoryName).firstOrNull;
    if (match != null) return match.label;
    if (categoryName.isEmpty) return categoryName;
    return categoryName[0].toUpperCase() + categoryName.substring(1);
  }
}
