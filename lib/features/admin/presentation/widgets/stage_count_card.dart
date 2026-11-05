import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/order_stage.dart';

/// A small card for the "Orders by stage" row: a top progress bar tinted by the
/// stage color, the stage name, and its count.
class StageCountCard extends StatelessWidget {
  const StageCountCard({
    super.key,
    required this.stage,
    required this.count,
  });

  final OrderStage stage;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: stage.color,
              borderRadius: AppRadius.pillAll,
            ),
          ),
          const SizedBox(height: AppSpacing.smd),
          Text(stage.label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.xs),
          Text('$count',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
