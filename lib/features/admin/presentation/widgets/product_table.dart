import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../domain/entities/admin_product.dart';

/// The Products table (wide layout) with a per-row Edit action.
class ProductTable extends StatelessWidget {
  const ProductTable({
    super.key,
    required this.products,
    required this.onEdit,
  });

  final List<AdminProduct> products;
  final ValueChanged<AdminProduct> onEdit;

  static String _categoryLabel(CategoryKind c) {
    switch (c) {
      case CategoryKind.women:
        return 'Women';
      case CategoryKind.men:
        return 'Men';
      case CategoryKind.kids:
        return 'Kids';
      case CategoryKind.all:
        return 'All';
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
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.1),
        4: FlexColumnWidth(0.9),
        5: FlexColumnWidth(0.8),
        6: FlexColumnWidth(1),
        7: FlexColumnWidth(0.9),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        const TableRow(
          children: <Widget>[
            _C(child: Text('Product', style: header)),
            _C(child: Text('Category', style: header)),
            _C(child: Text('Price', style: header)),
            _C(child: Text('Stitch time', style: header)),
            _C(child: Text('Rating', style: header)),
            _C(child: Text('Photos', style: header)),
            _C(child: Text('Visible', style: header)),
            _C(child: SizedBox.shrink()),
          ],
        ),
        for (final AdminProduct p in products) _row(p),
      ],
    );
  }

  TableRow _row(AdminProduct p) {
    final bool live = p.visibility == ProductVisibility.live;
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      children: <Widget>[
        _C(
          child: Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.cardPink,
                  borderRadius: AppRadius.smAll,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.checkroom,
                    size: 16, color: AppColors.iconCrimson),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(p.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        _C(child: Text(_categoryLabel(p.category), style: _body)),
        _C(child: Text('\u20B9${p.priceInr}', style: _bodyBold)),
        _C(child: Text('${p.stitchDays} days', style: _body)),
        _C(child: Text('\u2605 ${p.rating}', style: _body)),
        _C(child: Text('${p.photoCount}', style: _body)),
        _C(
          child: Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge.text(
              p.visibility.label,
              color: live ? AppColors.statusReady : AppColors.textSecondary,
              background:
                  live ? AppColors.statusReadyBg : AppColors.surfaceMuted,
            ),
          ),
        ),
        _C(
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => onEdit(p),
              child: const Text('Edit'),
            ),
          ),
        ),
      ],
    );
  }

  static const TextStyle _body =
      TextStyle(color: AppColors.textSecondary, fontSize: 13);
  static const TextStyle _bodyBold = TextStyle(
      color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600);
}

class _C extends StatelessWidget {
  const _C({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.smd, horizontal: AppSpacing.xs),
        child: child,
      );
}
