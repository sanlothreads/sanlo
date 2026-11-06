import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/admin_order.dart';
import 'stage_stepper.dart';

/// The right-hand Orders detail panel: header (order no + placed date), item,
/// amount line, customer card, measurements note, and the stage stepper.
class AdminOrderDetailPanel extends StatelessWidget {
  const AdminOrderDetailPanel({
    super.key,
    required this.order,
    required this.onAdvance,
  });

  final AdminOrder order;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '#${order.id} · placed ${DateFormatX.dayMonthShort(order.placedDate)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            order.item,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '\u20B9${order.amountAtShopInr} to collect at shop',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _customerCard(),
          const SizedBox(height: AppSpacing.md),
          _measurementsCard(),
          const SizedBox(height: AppSpacing.md),
          StageStepper(current: order.stage, onAdvance: onAdvance),
        ],
      ),
    );
  }

  Widget _customerCard() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            order.customerName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            order.customerPhone,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            order.customerAddress,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurementsCard() {
    final String note =
        order.measurementNote ??
        (order.measurementState == MeasurementState.entered
            ? 'Customer entered measurements online.'
            : 'Take measurements when the customer visits the shop.');
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cardPeach,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Measurements',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            note,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
