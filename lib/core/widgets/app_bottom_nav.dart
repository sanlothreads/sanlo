import 'package:flutter/material.dart';

/// The app's 3-tab bottom navigation bar: Home, My orders, and Profile.
///
/// This is a thin wrapper around Material's [BottomNavigationBar]. Colors,
/// label styles, elevation, and the fixed layout all come from
/// `AppTheme.light`'s [BottomNavigationBarThemeData] (indigo for the selected
/// tab, grey for unselected tabs, on a white surface), so this widget only owns
/// the tab definitions and the selected/active state wiring.
///
/// It is intentionally presentational: it reports taps through [onTap] and
/// renders [currentIndex] as selected. The owning shell (driven by `go_router`'s
/// `StatefulNavigationShell`) decides what a tap means.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Index of the currently active tab (0: Home, 1: My orders, 2: Profile).
  final int currentIndex;

  /// Called with the tapped tab's index.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      // type/colors/label styles come from the app's BottomNavigationBarTheme.
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'My orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
