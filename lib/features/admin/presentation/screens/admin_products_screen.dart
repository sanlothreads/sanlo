import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../domain/entities/admin_product.dart';
import '../cubit/admin_products_cubit.dart';
import '../cubit/admin_products_state.dart';
import '../widgets/product_table.dart';

/// The admin Products screen: searchable product table with a per-row Edit
/// action and a top-level Add product button. On narrow layouts the table
/// collapses to stacked cards.
class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({
    super.key,
    required this.onAddProduct,
    required this.onEditProduct,
  });

  final VoidCallback onAddProduct;
  final ValueChanged<AdminProduct> onEditProduct;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminProductsCubit, AdminProductsState>(
      builder: (context, state) {
        if (state.status == AdminProductsStatus.loading ||
            state.status == AdminProductsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminProductsStatus.failure) {
          return _error(context, state.error);
        }

        final bool wide =
            MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;
        final List<AdminProduct> products = state.visibleProducts;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _header(context, wide),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('No products match your search'))
                    : SingleChildScrollView(
                        child: SectionCard(
                          child: wide
                              ? ProductTable(
                                  products: products,
                                  onEdit: onEditProduct,
                                )
                              : _stacked(products),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, bool wide) {
    final Widget search = SizedBox(
      width: wide ? 280 : double.infinity,
      child: TextField(
        onChanged: (t) => context.read<AdminProductsCubit>().search(t),
        decoration: const InputDecoration(
          hintText: 'Search products',
          prefixIcon: Icon(Icons.search, size: 20),
          isDense: true,
        ),
      ),
    );
    final Widget addButton = ElevatedButton.icon(
      onPressed: onAddProduct,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add product'),
    );

    if (wide) {
      return Row(
        children: <Widget>[
          const Text(
            'Products',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          search,
          const SizedBox(width: AppSpacing.md),
          addButton,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text(
              'Products',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            addButton,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        search,
      ],
    );
  }

  Widget _stacked(List<AdminProduct> products) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < products.length; i++)
          _stackedRow(products[i], last: i == products.length - 1),
      ],
    );
  }

  Widget _stackedRow(AdminProduct p, {required bool last}) {
    final bool live = p.visibility == ProductVisibility.live;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.smd),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  p.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_categoryLabel(p.category)} · \u20B9${p.priceInr} · ${p.stitchDays} days',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge.text(
            p.visibility.label,
            color: live ? AppColors.statusReady : AppColors.textSecondary,
            background: live ? AppColors.statusReadyBg : AppColors.surfaceMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => onEditProduct(p),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

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

  Widget _error(BuildContext context, String? message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message ?? 'Something went wrong'),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.read<AdminProductsCubit>().load(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
