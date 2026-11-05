import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_product.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_products_state.dart';

/// Cubit for the admin Products screen.
///
/// Loads all products, keeps the search query in state (filtering is derived),
/// and supports [upsertProduct] to add a new product or replace an existing
/// one by id.
class AdminProductsCubit extends Cubit<AdminProductsState> {
  AdminProductsCubit(this._repository) : super(const AdminProductsState());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: AdminProductsStatus.loading, error: null));
    try {
      final List<AdminProduct> products = await _repository.loadProducts();
      emit(
        state.copyWith(
          status: AdminProductsStatus.loaded,
          allProducts: products,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AdminProductsStatus.failure,
          error: 'Could not load products, try again',
        ),
      );
    }
  }

  /// Updates the search [text].
  void search(String text) => emit(state.copyWith(query: text));

  /// Saves [product] to state immediately, then persists to repository.
  ///
  /// A create passes an empty id; the repository assigns the final unique id
  /// and returns the saved product, which is reconciled back into state so the
  /// new row can be edited or deleted without a reload.
  Future<void> saveProduct(AdminProduct product) async {
    final bool isCreate = product.id.trim().isEmpty;
    final int i = isCreate
        ? -1
        : state.allProducts.indexWhere((p) => p.id == product.id);
    final List<AdminProduct> updated = List.of(state.allProducts);
    if (i >= 0) {
      updated[i] = product;
    } else {
      updated.add(product);
    }
    emit(state.copyWith(allProducts: updated));

    try {
      final AdminProduct saved = await _repository.saveProduct(product);
      if (saved.id != product.id) {
        final List<AdminProduct> reconciled = state.allProducts
            .map((p) => identical(p, product) || p.id == product.id ? saved : p)
            .toList();
        emit(state.copyWith(allProducts: reconciled));
      }
    } catch (_) {
      emit(state.copyWith(error: 'Could not save product, try again'));
    }
  }

  /// Deletes [productId] from state immediately, then persists to repository.
  Future<void> deleteProduct(String productId) {
    final List<AdminProduct> updated = state.allProducts
        .where((p) => p.id != productId)
        .toList();
    emit(state.copyWith(allProducts: updated));

    return _repository.deleteProduct(productId).catchError((_) {
      emit(state.copyWith(error: 'Could not delete product, try again'));
    });
  }

  /// Adds [product] when its id is new, or replaces the existing product with
  /// the same id. List length changes by at most one.
  void upsertProduct(AdminProduct product) => saveProduct(product);
}
