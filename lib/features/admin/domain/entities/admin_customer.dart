import 'package:equatable/equatable.dart';

import '../../../../core/entities/gender.dart';

/// Whether a customer is an anonymous guest or a registered account.
enum CustomerType { guest, registered }

/// Display helpers for [CustomerType].
extension CustomerTypeX on CustomerType {
  String get label => this == CustomerType.guest ? 'Guest' : 'Registered';
}

/// A customer row shown in the admin Customers directory.
class AdminCustomer extends Equatable {
  const AdminCustomer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.gender,
    required this.orderCount,
    this.lastOrderDate,
    this.email,
    this.type = CustomerType.registered,
    this.registeredDate,
    this.lastLogin,
  });

  final String id;
  final String name;
  final String mobile;

  /// Email address, or `null` when the customer has none (rendered as "—").
  final String? email;

  final Gender gender;
  final CustomerType type;

  /// Registration timestamp formatted string (e.g. "24-May-2025 02:30 PM").
  final String? registeredDate;

  /// Last app opened / login timestamp formatted string (e.g. "24-May-2025 02:30 PM").
  final String? lastLogin;

  /// Number of orders placed by this customer.
  final int orderCount;

  /// Date of the customer's most recent order, or `null` if [orderCount] is 0.
  final DateTime? lastOrderDate;

  /// Two-letter uppercase initials derived from [name], e.g. "PS" for
  /// "Priya Sharma". Falls back to the first letter for single-word names.
  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  List<Object?> get props => [
    id,
    name,
    mobile,
    email,
    gender,
    type,
    registeredDate,
    lastLogin,
    orderCount,
    lastOrderDate,
  ];
}
