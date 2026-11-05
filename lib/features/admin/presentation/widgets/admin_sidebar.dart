import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'admin_destinations.dart';

/// The persistent left navigation rail shown on wide admin layouts.
///
/// Renders the Sanlo brand mark with an "ADMIN" badge, the four destinations
/// (with an optional "new" count badge on Orders), and a pinned "Sign out"
/// action at the bottom.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    this.adminName,
    required this.selected,
    required this.onSelect,
    required this.onSignOut,
    this.ordersBadgeCount = 0,
  });

  /// Signed-in admin's display name (from Firebase); null until resolved.
  final String? adminName;

  final AdminDestination selected;
  final ValueChanged<AdminDestination> onSelect;
  final VoidCallback onSignOut;
  final int ordersBadgeCount;

  static const double width = 232;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _brand(),
          if (adminName != null && adminName!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.smd),
            Text(
              adminName!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          for (final AdminDestination d in AdminDestination.values)
            _navItem(d),
          const Spacer(),
          _signOut(),
        ],
      ),
    );
  }

  Widget _brand() {
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.mdAll,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.content_cut,
              size: 18, color: AppColors.onPrimary),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text(
          'Sanlo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: AppRadius.pillAll,
          ),
          child: const Text(
            'ADMIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _navItem(AdminDestination d) {
    final bool isActive = d == selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isActive ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: () => onSelect(d),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.smd,
              vertical: AppSpacing.smd,
            ),
            child: Row(
              children: <Widget>[
                Text(
                  d.label,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (d == AdminDestination.orders && ordersBadgeCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.pillAll,
                    ),
                    child: Text(
                      '$ordersBadgeCount new',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _signOut() {
    return TextButton.icon(
      onPressed: onSignOut,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.72),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smd),
      ),
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Sign out'),
    );
  }
}
