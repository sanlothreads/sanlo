import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_customer.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_customers_state.dart';

/// Cubit for the admin Customers screen.
///
/// Loads all customers and keeps the search query in state; filtering by name
/// or mobile is derived in [AdminCustomersState].
class AdminCustomersCubit extends Cubit<AdminCustomersState> {
  AdminCustomersCubit(this._repository) : super(const AdminCustomersState());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: AdminCustomersStatus.loading, error: null));
    try {
      final List<AdminCustomer> customers = await _repository.loadCustomers();
      emit(
        state.copyWith(
          status: AdminCustomersStatus.loaded,
          allCustomers: customers,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AdminCustomersStatus.failure,
          error: 'Could not load customers, try again',
        ),
      );
    }
  }

  /// Updates the search [text].
  void search(String text) => emit(state.copyWith(query: text));
}
