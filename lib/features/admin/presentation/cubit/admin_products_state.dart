import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_product.dart';

/// Load status of the admin Products screen.
enum AdminProductsStatus { initial, loading, loaded, failure }

/// State for the admin Products screen.
class AdminProductsState extends Equatable {
  const AdminProductsState({
    this.status = AdminProductsStatus.initial,
    this.allProducts = const [],
    this.query = '',
    this.error,
  });

  final AdminProductsStatus status;

  /// Every product, before the search is applied.
  final List<AdminProduct> allProducts;

  /// Current search text. Empty / whitespace applies no filtering.
  final String query;

  final String? error;

  /// Products whose name contains [query], matched case-insensitively.
  List<AdminProduct> get visibleProducts {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return allProducts;
    return allProducts
        .where((p) => p.name.toLowerCase().contains(needle))
        .toList(growable: false);
  }

  AdminProductsState copyWith({
    AdminProductsStatus? status,
    List<AdminProduct>? allProducts,
    String? query,
    String? error,
  }) {
    return AdminProductsState(
      status: status ?? this.status,
      allProducts: allProducts ?? this.allProducts,
      query: query ?? this.query,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, allProducts, query, error];
}
