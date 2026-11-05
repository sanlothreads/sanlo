import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_summary.dart';

/// Load status of the admin Dashboard.
enum AdminDashboardStatus { initial, loading, loaded, failure }

/// State for the admin Dashboard screen.
class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.status = AdminDashboardStatus.initial,
    this.summary,
    this.error,
  });

  final AdminDashboardStatus status;

  /// The loaded summary, or null before the first successful load.
  final DashboardSummary? summary;

  /// Error message to display, or null when there is no error.
  final String? error;

  AdminDashboardState copyWith({
    AdminDashboardStatus? status,
    DashboardSummary? summary,
    String? error,
  }) {
    return AdminDashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, summary, error];
}
