import 'package:equatable/equatable.dart';

import 'admin_order.dart';
import 'order_stage.dart';

/// Aggregated figures and lists powering the admin Dashboard.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.totalOrders,
    required this.newToday,
    required this.newTodayNote,
    required this.inProgress,
    required this.inProgressNote,
    required this.readyToCollect,
    required this.readyNote,
    required this.stageCounts,
    required this.recentOrders,
  });

  final int totalOrders;
  final int newToday;
  final String newTodayNote;
  final int inProgress;
  final String inProgressNote;
  final int readyToCollect;
  final String readyNote;

  /// Count of orders currently in each stage.
  final Map<OrderStage, int> stageCounts;

  /// Orders shown in the "Recent orders" table.
  final List<AdminOrder> recentOrders;

  @override
  List<Object?> get props => [
    totalOrders,
    newToday,
    newTodayNote,
    inProgress,
    inProgressNote,
    readyToCollect,
    readyNote,
    stageCounts,
    recentOrders,
  ];
}
