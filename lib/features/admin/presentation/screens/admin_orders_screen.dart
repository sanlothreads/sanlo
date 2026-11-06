import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_stage.dart';
import '../cubit/admin_orders_cubit.dart';
import '../cubit/admin_orders_state.dart';
import '../widgets/admin_order_detail_panel.dart';
import '../widgets/admin_order_list_tile.dart';

/// The admin Orders screen: stage filter chips, an order list, and a detail
/// panel with the stage stepper. Wide layouts show list + panel side by side;
/// narrow layouts show the list and open the detail in a bottom sheet.
class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
      builder: (context, state) {
        if (state.status == AdminOrdersStatus.loading ||
            state.status == AdminOrdersStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminOrdersStatus.failure) {
          return _error(context, state.error);
        }

        final bool wide =
            MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Orders',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _filterChips(context, state),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: wide ? _wide(context, state) : _narrow(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _error(BuildContext context, String? message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message ?? 'Something went wrong'),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.read<AdminOrdersCubit>().load(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _filterChips(BuildContext context, AdminOrdersState state) {
    final Map<OrderStage, int> counts = state.stageCounts;
    final AdminOrdersCubit cubit = context.read<AdminOrdersCubit>();

    final List<Widget> chips = <Widget>[
      _chip(
        label: 'All',
        count: state.allOrders.length,
        selected: state.filter == null,
        onTap: () => cubit.selectFilter(null),
      ),
      for (final OrderStage s in OrderStage.values)
        _chip(
          label: s.label,
          count: counts[s] ?? 0,
          selected: state.filter == s,
          onTap: () => cubit.selectFilter(s),
        ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }

  Widget _chip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text('$label \u00B7 $count'),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  // --- Wide: list + detail panel --------------------------------------------

  Widget _wide(BuildContext context, AdminOrdersState state) {
    final AdminOrder? selected = state.selectedOrder;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(flex: 2, child: _listCard(context, state)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgAll,
            ),
            child: selected == null
                ? const Center(child: Text('Select an order'))
                : AdminOrderDetailPanel(
                    order: selected,
                    onAdvance: () =>
                        context.read<AdminOrdersCubit>().advanceSelected(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _listCard(BuildContext context, AdminOrdersState state) {
    final List<AdminOrder> orders = state.filteredOrders;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: orders.isEmpty
          ? const Center(child: Text('No orders in this stage'))
          : ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) => AdminOrderListTile(
                order: orders[i],
                selected: orders[i].id == state.selectedId,
                onTap: () =>
                    context.read<AdminOrdersCubit>().selectOrder(orders[i].id),
              ),
            ),
    );
  }

  // --- Narrow: list, detail in a sheet --------------------------------------

  Widget _narrow(BuildContext context, AdminOrdersState state) {
    final List<AdminOrder> orders = state.filteredOrders;
    if (orders.isEmpty) {
      return const Center(child: Text('No orders in this stage'));
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: orders.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, i) => AdminOrderListTile(
          order: orders[i],
          selected: false,
          onTap: () {
            context.read<AdminOrdersCubit>().selectOrder(orders[i].id);
            _openDetailSheet(context);
          },
        ),
      ),
    );
  }

  void _openDetailSheet(BuildContext context) {
    final AdminOrdersCubit cubit = context.read<AdminOrdersCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) {
        return BlocProvider<AdminOrdersCubit>.value(
          value: cubit,
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
              builder: (sheetContext, state) {
                final AdminOrder? selected = state.selectedOrder;
                if (selected == null) {
                  return const SizedBox.shrink();
                }
                return AdminOrderDetailPanel(
                  order: selected,
                  onAdvance: () =>
                      sheetContext.read<AdminOrdersCubit>().advanceSelected(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
