import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_stage.dart';

/// The "Recent orders" table shown on the wide dashboard layout.
class RecentOrdersTable extends StatelessWidget {
  const RecentOrdersTable({super.key, required this.orders});

  final List<AdminOrder> orders;

  @override
  Widget build(BuildContext context) {
    const TextStyle header = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.1),
        4: FlexColumnWidth(1.3),
        5: FlexColumnWidth(0.9),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        const TableRow(
          children: <Widget>[
            _Cell(child: Text('Order', style: header)),
            _Cell(child: Text('Customer', style: header)),
            _Cell(child: Text('Item', style: header)),
            _Cell(child: Text('Measurement', style: header)),
            _Cell(child: Text('Status', style: header)),
            _Cell(child: Text('Due', style: header)),
          ],
        ),
        for (final AdminOrder o in orders) _row(o),
      ],
    );
  }

  TableRow _row(AdminOrder o) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      children: <Widget>[
        _Cell(
          child: Text('#${o.id}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        _Cell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(o.customerName,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13)),
              Text(o.customerPhone,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
        ),
        _Cell(
          child: Text(o.item,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13)),
        ),
        _Cell(child: _measurement(o)),
        _Cell(
          child: Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge.text(
              o.stage.label,
              color: o.stage.color,
              background: o.stage.bgColor,
            ),
          ),
        ),
        _Cell(
          child: Text(DateFormatX.dayMonthShort(o.dueDate),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _measurement(AdminOrder o) {
    final bool notSure = o.measurementState == MeasurementState.notSure;
    return Align(
      alignment: Alignment.centerLeft,
      child: StatusBadge.text(
        o.measurementState.label,
        color: notSure ? AppColors.iconOrange : AppColors.textSecondary,
        background: notSure ? AppColors.cardPeach : AppColors.surfaceMuted,
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.smd,
        horizontal: AppSpacing.xs,
      ),
      child: child,
    );
  }
}
