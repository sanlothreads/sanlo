import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_stage.dart';

/// A selectable row in the Orders list: "#SN-xxxx · Item", customer · due, and
/// a trailing stage badge. Highlights when [selected].
class AdminOrderListTile extends StatelessWidget {
  const AdminOrderListTile({
    super.key,
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final AdminOrder order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.smd,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '#${order.id} · ${order.item}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customerName} · Due ${DateFormatX.dayMonthShort(order.dueDate)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge.text(
                order.stage.label,
                color: order.stage.color,
                background: order.stage.bgColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
