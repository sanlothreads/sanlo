import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/order_stage.dart';

/// The "Update status" control: a vertical list of the six stages with the
/// current one highlighted, plus a primary button that advances to the next
/// stage. The button is hidden when the order is at the final stage.
class StageStepper extends StatelessWidget {
  const StageStepper({
    super.key,
    required this.current,
    required this.onAdvance,
  });

  final OrderStage current;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final String? advanceLabel = current.advanceActionLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'Update status',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.smd),
        for (final OrderStage s in OrderStage.values) _row(s),
        if (advanceLabel != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: advanceLabel, onPressed: onAdvance),
        ],
      ],
    );
  }

  Widget _row(OrderStage s) {
    final bool isCurrent = s == current;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smd,
        vertical: AppSpacing.smd,
      ),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primaryLight : AppColors.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.smd),
          Text(
            s.label,
            style: TextStyle(
              color: isCurrent
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
