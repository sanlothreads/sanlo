import 'package:flutter/material.dart';

import 'admin_destinations.dart';

/// Bottom navigation bar for the narrow admin layout, hosting the four admin
/// destinations. Presentational: reports taps through [onSelect].
class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AdminDestination selected;
  final ValueChanged<AdminDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selected.index,
      onTap: (i) => onSelect(AdminDestination.values[i]),
      items: <BottomNavigationBarItem>[
        for (final AdminDestination d in AdminDestination.values)
          BottomNavigationBarItem(
            icon: Icon(d.icon),
            activeIcon: Icon(d.activeIcon),
            label: d.label,
          ),
      ],
    );
  }
}
