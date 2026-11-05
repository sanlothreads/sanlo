import 'package:flutter/material.dart';

/// The four admin navigation destinations, in display order.
enum AdminDestination { dashboard, orders, products, customers }

/// Display metadata for an [AdminDestination].
extension AdminDestinationX on AdminDestination {
  String get label {
    switch (this) {
      case AdminDestination.dashboard:
        return 'Dashboard';
      case AdminDestination.orders:
        return 'Orders';
      case AdminDestination.products:
        return 'Products';
      case AdminDestination.customers:
        return 'Customers';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminDestination.dashboard:
        return Icons.dashboard_outlined;
      case AdminDestination.orders:
        return Icons.receipt_long_outlined;
      case AdminDestination.products:
        return Icons.checkroom_outlined;
      case AdminDestination.customers:
        return Icons.people_outline;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case AdminDestination.dashboard:
        return Icons.dashboard;
      case AdminDestination.orders:
        return Icons.receipt_long;
      case AdminDestination.products:
        return Icons.checkroom;
      case AdminDestination.customers:
        return Icons.people;
    }
  }
}
