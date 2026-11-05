import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// A metric tile used on the dashboard: a small label, a large value, and a
/// caption. Set [dark] for the tiles on the mobile dark header.
class AdminSummaryCard extends StatelessWidget {
  const AdminSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.dark = false,
  });

  final String label;
  final String value;
  final String? caption;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = dark
        ? Colors.white.withValues(alpha: 0.72)
        : AppColors.textSecondary;
    final Color valueColor = dark ? Colors.white : AppColors.textPrimary;
    final Color captionColor = dark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.textTertiary;

    return Container(
      padding: dark
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.smd,
              vertical: AppSpacing.sm,
            )
          : AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.06) : AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: dark ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: captionColor, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
