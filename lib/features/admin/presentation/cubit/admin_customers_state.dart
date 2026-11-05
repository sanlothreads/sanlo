import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_customer.dart';

/// Load status of the admin Customers screen.
enum AdminCustomersStatus { initial, loading, loaded, failure }

/// State for the admin Customers screen.
class AdminCustomersState extends Equatable {
  const AdminCustomersState({
    this.status = AdminCustomersStatus.initial,
    this.allCustomers = const [],
    this.query = '',
    this.error,
  });

  final AdminCustomersStatus status;

  /// Every customer, before the search is applied.
  final List<AdminCustomer> allCustomers;

  /// Current search text. Empty / whitespace applies no filtering.
  final String query;

  final String? error;

  /// Customers whose name or mobile contains [query], case-insensitively.
  List<AdminCustomer> get visibleCustomers {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return allCustomers;
    return allCustomers
        .where((c) =>
            c.name.toLowerCase().contains(needle) ||
            c.mobile.toLowerCase().contains(needle))
        .toList(growable: false);
  }

  AdminCustomersState copyWith({
    AdminCustomersStatus? status,
    List<AdminCustomer>? allCustomers,
    String? query,
    String? error,
  }) {
    return AdminCustomersState(
      status: status ?? this.status,
      allCustomers: allCustomers ?? this.allCustomers,
      query: query ?? this.query,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, allCustomers, query, error];
}
