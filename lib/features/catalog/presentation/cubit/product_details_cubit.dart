import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_details_state.dart';

/// Drives the Product details screen: loads a [StyleDetail] by id and tracks
/// the selected photo and variant.
class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit(this._repository)
    : super(const ProductDetailsState.initial());

  final ProductRepository _repository;

  /// Loads the style detail for [productId].
  ///
  /// Emits a loading state first, then either the loaded detail (with the
  /// photo/variant selection reset to the first item) or an error state with
  /// message `"Not found"` when the id is unknown.
  Future<void> load(String productId) async {
    emit(const ProductDetailsState(loading: true));
    try {
      final detail = await _repository.getProductDetail(productId);
      emit(
        ProductDetailsState(
          loading: false,
          detail: detail,
          selectedPhotoIndex: 0,
          selectedVariantIndex: 0,
        ),
      );
    } on NotFoundFailure {
      emit(const ProductDetailsState(loading: false, error: 'Not found'));
    }
  }

  /// Selects the photo at [index], clamped to `[0, imageCount - 1]`.
  void selectPhoto(int index) {
    final detail = state.detail;
    final int maxIndex = detail != null && detail.product.imageCount > 0
        ? detail.product.imageCount - 1
        : 0;
    final int clamped = maxIndex > 0 ? index.clamp(0, maxIndex) : 0;
    emit(state.copyWith(
      selectedPhotoIndex: clamped,
      selectedVariantIndex: clamped,
    ));
  }

  /// Selects the variant/color thumbnail at [index] and updates the photo index.
  void selectVariant(int index) {
    selectPhoto(index);
  }
}
