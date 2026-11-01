import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../../domain/repositories/product_repository.dart';
import 'home_state.dart';

/// Cubit for the Home (catalog browsing) screen.
///
/// Loads the categories and the full product catalog once, then keeps the
/// category filter and search query in state. The derived
/// [HomeState.visibleProducts] getter does all filtering/searching, so these
/// methods only update the relevant piece of state.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeState.initial());

  final ProductRepository _repository;

  /// Loads the categories and full product catalog.
  ///
  /// Emits a loading state first, then a loaded state with the fetched
  /// categories and products. On failure emits an error state.
  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final categories = await _repository.getCategories();
      final products = await _repository.getProducts();
      emit(
        state.copyWith(
          loading: false,
          categories: categories,
          allProducts: products,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Could not load the catalog, try again',
        ),
      );
    }
  }

  /// Applies the given category [kind] filter. The visible products are
  /// recomputed from the derived getter.
  void applyFilter(CategoryKind kind) {
    emit(state.copyWith(selectedFilter: kind));
  }

  /// Updates the search [text]. The visible products are recomputed from the
  /// derived getter.
  void search(String text) {
    emit(state.copyWith(query: text));
  }
}
