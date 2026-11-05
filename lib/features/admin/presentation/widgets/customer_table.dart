import 'package:flutter/material.dart';

import '../../../../core/entities/gender.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/admin_customer.dart';

/// The Customers directory table (wide layout).
class CustomerTable extends StatelessWidget {
  const CustomerTable({super.key, required this.customers});

  final List<AdminCustomer> customers;

  static String _genderLabel(Gender g) {
    switch (g) {
      case Gender.female:
        return 'Female';
      case Gender.male:
        return 'Male';
      case Gender.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle header = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(1.8),
        1: FlexColumnWidth(1.3),
        2: FlexColumnWidth(1.6),
        3: FlexColumnWidth(0.9),
        4: FlexColumnWidth(1.4),
        5: FlexColumnWidth(1.4),
        6: FlexColumnWidth(0.8),
        7: FlexColumnWidth(1.1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        const TableRow(
          children: <Widget>[
            _C(child: Text('Customer', style: header)),
            _C(child: Text('Mobile', style: header)),
            _C(child: Text('Email', style: header)),
            _C(child: Text('Gender', style: header)),
            _C(child: Text('Registered Date', style: header)),
            _C(child: Text('Last Login', style: header)),
            _C(child: Text('Orders', style: header)),
            _C(child: Text('Last order', style: header)),
          ],
        ),
        for (final AdminCustomer c in customers) _row(c),
      ],
    );
  }

  TableRow _row(AdminCustomer c) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      children: <Widget>[
        _C(
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  c.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  c.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        _C(child: Text(c.mobile, style: _body)),
        _C(child: Text(c.email ?? '\u2014', style: _body)),
        _C(child: Text(_genderLabel(c.gender), style: _body)),
        _C(child: Text(c.registeredDate ?? '\u2014', style: _body)),
        _C(child: Text(c.lastLogin ?? '\u2014', style: _body)),
        _C(child: Text('${c.orderCount}', style: _bodyBold)),
        _C(
          child: Text(
            c.orderCount > 0 && c.lastOrderDate != null
                ? DateFormatX.dayMonthShort(c.lastOrderDate!)
                : '\u2014',
            style: _body,
          ),
        ),
      ],
    );
  }

  static const TextStyle _body = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
  );
  static const TextStyle _bodyBold = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}

class _C extends StatelessWidget {
  const _C({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.smd,
      horizontal: AppSpacing.xs,
    ),
    child: child,
  );
}
