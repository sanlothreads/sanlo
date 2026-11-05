import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_destinations.dart';
import '../widgets/admin_sidebar.dart';

/// Responsive navigation container for the admin area.
///
/// At or above [AppSpacing.wideBreakpoint] it shows the persistent
/// [AdminSidebar] beside the active destination's [child]; below it, it shows
/// an [AdminBottomNav]. It is purely presentational — selection and sign-out
/// are reported through callbacks so the router owns navigation.
class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({
    super.key,
    this.adminName,
    required this.selected,
    required this.onSelect,
    required this.onSignOut,
    required this.child,
    this.ordersBadgeCount = 0,
  });

  /// The signed-in admin's display name (from Firebase); null until resolved.
  final String? adminName;

  final AdminDestination selected;
  final ValueChanged<AdminDestination> onSelect;
  final VoidCallback onSignOut;
  final Widget child;
  final int ordersBadgeCount;

  @override
  Widget build(BuildContext context) {
    final bool wide =
        MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;

    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AdminSidebar(
                adminName: adminName,
                selected: selected,
                onSelect: onSelect,
                onSignOut: onSignOut,
                ordersBadgeCount: ordersBadgeCount,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(child: child),
      bottomNavigationBar: AdminBottomNav(
        selected: selected,
        onSelect: onSelect,
      ),
    );
  }
}
