import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

/// State for the Home (catalog browsing) screen.
///
/// Holds the loaded [categories] and [allProducts] plus the current
/// [selectedFilter] and search [query]. The [visibleProducts] getter derives
/// the list to show by applying the category filter followed by a
/// case-insensitive name-contains search; it is pure and deterministic so it
/// can be exercised directly by property tests.
class HomeState extends Equatable {
  const HomeState({
    this.loading = false,
    this.categories = const [],
    this.allProducts = const [],
    this.selectedFilter = CategoryKind.all,
    this.query = '',
    this.error,
  });

  /// Initial state shown while the catalog is first being loaded.
  const HomeState.initial() : this(loading: true);

  /// Whether the catalog is currently being loaded.
  final bool loading;

  /// The selectable categories (All, Women, Men, Kids).
  final List<Category> categories;

  /// Every product in the catalog, before any filter/search is applied.
  final List<Product> allProducts;

  /// The currently selected category filter. [CategoryKind.all] means no
  /// category filtering is applied.
  final CategoryKind selectedFilter;

  /// The current search text. An empty or whitespace-only query applies no
  /// name filtering.
  final String query;

  /// Error message to display, or null when there is no error.
  final String? error;

  /// The products to display, derived from [allProducts] by applying the
  /// category filter then the case-insensitive name-contains search.
  ///
  /// Pure and deterministic: given the same [allProducts], [selectedFilter]
  /// and [query] it always returns the same result and has no side effects.
  List<Product> get visibleProducts {
    Iterable<Product> result = allProducts;

    if (selectedFilter != CategoryKind.all) {
      result = result.where((p) => p.category == selectedFilter);
    }

    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      final needle = trimmed.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(needle));
    }

    return result.toList();
  }

  /// Returns a copy of this state with the given fields replaced.
  HomeState copyWith({
    bool? loading,
    List<Category>? categories,
    List<Product>? allProducts,
    CategoryKind? selectedFilter,
    String? query,
    String? error,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      categories: categories ?? this.categories,
      allProducts: allProducts ?? this.allProducts,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      query: query ?? this.query,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    categories,
    allProducts,
    selectedFilter,
    query,
    error,
  ];
}
