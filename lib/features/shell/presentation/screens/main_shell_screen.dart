import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bottom_nav.dart';

/// The 3-tab bottom-navigation shell that hosts the Home, My orders, and
/// Profile branches.
///
/// It renders the [StatefulNavigationShell] built by `go_router`'s
/// `StatefulShellRoute.indexedStack` as the scaffold body (so each tab keeps
/// its own navigation stack) and an [AppBottomNav] as the bottom bar.
///
/// Tapping a tab calls [StatefulNavigationShell.goBranch]. When the tapped tab
/// is already the active one, `initialLocation: true` resets that branch back
/// to its initial route instead of being a no-op — matching the common
/// "tap the active tab to pop to root" behaviour.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  /// The navigation shell provided by `StatefulShellRoute.indexedStack`.
  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Re-tapping the active tab returns it to its initial location.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
