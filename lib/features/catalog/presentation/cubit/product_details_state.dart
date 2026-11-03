import 'package:equatable/equatable.dart';

import '../../domain/entities/style_detail.dart';

/// State for the Product details screen.
///
/// Holds the loaded [StyleDetail] along with the currently selected photo and
/// variant indices. While the detail is being fetched [loading] is `true`; when
/// the requested product does not exist [error] is set to `"Not found"`.
class ProductDetailsState extends Equatable {
  const ProductDetailsState({
    this.loading = false,
    this.detail,
    this.selectedPhotoIndex = 0,
    this.selectedVariantIndex = 0,
    this.error,
  });

  /// The initial state shown while the first load is in flight.
  const ProductDetailsState.initial() : this(loading: true);

  /// Whether the style detail is currently being loaded.
  final bool loading;

  /// The loaded style detail, or `null` before the first successful load.
  final StyleDetail? detail;

  /// 0-based index of the selected photo; always `< detail.product.imageCount`.
  final int selectedPhotoIndex;

  /// 0-based index of the selected variant/color thumbnail.
  final int selectedVariantIndex;

  /// User-facing error message; `"Not found"` when the product id is unknown.
  final String? error;

  ProductDetailsState copyWith({
    bool? loading,
    StyleDetail? detail,
    int? selectedPhotoIndex,
    int? selectedVariantIndex,
    String? error,
  }) {
    return ProductDetailsState(
      loading: loading ?? this.loading,
      detail: detail ?? this.detail,
      selectedPhotoIndex: selectedPhotoIndex ?? this.selectedPhotoIndex,
      selectedVariantIndex: selectedVariantIndex ?? this.selectedVariantIndex,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    detail,
    selectedPhotoIndex,
    selectedVariantIndex,
    error,
  ];
}
