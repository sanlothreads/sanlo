import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/greeting.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/order_stage.dart';
import '../../domain/repositories/admin_access_repository.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';
import '../cubit/admin_session_cubit.dart';
import '../widgets/admin_summary_card.dart';
import '../widgets/recent_orders_table.dart';
import '../widgets/stage_count_card.dart';

/// The admin Dashboard: date + greeting, summary cards, orders-by-stage, and
/// recent orders. Adapts between a wide multi-column layout and a condensed
/// mobile layout with an "Orders to update" action list.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onAddProduct,
    required this.onViewAllOrders,
  });

  final VoidCallback onAddProduct;
  final VoidCallback onViewAllOrders;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state.status == AdminDashboardStatus.loading ||
            state.status == AdminDashboardStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminDashboardStatus.failure ||
            state.summary == null) {
          return _error(context, state.error);
        }

        final bool wide =
            MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;
        final DashboardSummary s = state.summary!;
        return wide ? _wide(context, s) : _narrow(context, s);
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
            onPressed: () => context.read<AdminDashboardCubit>().load(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // --- Wide layout ----------------------------------------------------------

  Widget _wide(BuildContext context, DashboardSummary s) {
    final DateTime now = DateTime.now();
    final String greeting = _greetingWithName(context, greetingFor(now));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      DateFormatX.weekdayDayMonth(now),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add product'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _summaryRow(s),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(title: 'Orders by stage', child: _stageGrid(context, s)),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Recent orders',
            trailing: TextButton(
              onPressed: onViewAllOrders,
              child: const Text('View all \u2192'),
            ),
            child: RecentOrdersTable(orders: s.recentOrders),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(DashboardSummary s) {
    final List<Widget> cards = <Widget>[
      AdminSummaryCard(
        label: 'Total orders',
        value: '${s.totalOrders}',
        caption: 'All active orders',
      ),
      AdminSummaryCard(
        label: 'New today',
        value: '${s.newToday}',
        caption: s.newTodayNote,
      ),
      AdminSummaryCard(
        label: 'In progress',
        value: '${s.inProgress}',
        caption: s.inProgressNote,
      ),
      AdminSummaryCard(
        label: 'Ready to collect',
        value: '${s.readyToCollect}',
        caption: s.readyNote,
      ),
    ];
    return Row(
      children: <Widget>[
        for (int i = 0; i < cards.length; i++) ...<Widget>[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _stageGrid(BuildContext context, DashboardSummary s) {
    final double width = MediaQuery.sizeOf(context).width;
    final int columns = width >= 1200 ? 6 : (width >= 600 ? 3 : 2);
    final double aspectRatio = width >= 1200
        ? 1.4
        : (width >= 600 ? 1.1 : 0.95);
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: aspectRatio,
      children: <Widget>[
        for (final OrderStage stage in OrderStage.values)
          StageCountCard(stage: stage, count: s.stageCounts[stage] ?? 0),
      ],
    );
  }

  /// Appends the admin's first name to [base], e.g. "Good morning, Himanshu".
  /// Falls back to just [base] when the admin name has not resolved yet.
  String _greetingWithName(BuildContext context, String base) {
    final AdminAccount? account = context.watch<AdminSessionCubit>().state;
    final String name = (account?.name ?? '').trim();
    if (name.isEmpty) return base;
    final String firstName = name.split(RegExp(r'\s+')).first;
    final String pretty = firstName.isEmpty
        ? firstName
        : firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
    return '$base, $pretty';
  }

  // --- Narrow layout --------------------------------------------------------

  Widget _narrow(BuildContext context, DashboardSummary s) {
    final int activeToUpdate = s.recentOrders
        .where((o) => !o.stage.isFinal)
        .length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _mobileHeader(context, s),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Orders to update',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$activeToUpdate active',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (s.recentOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No orders yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  for (final AdminOrder o in s.recentOrders)
                    _updateCard(context, o),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileHeader(BuildContext context, DashboardSummary s) {
    final AdminAccount? account = context.watch<AdminSessionCubit>().state;
    final DateTime now = DateTime.now();
    final String greeting = _greetingWithName(context, greetingFor(now));
    return Container(
      color: AppColors.textPrimary,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                'SANLO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: AppRadius.pillAll,
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const SignOutRequested());
                  context.goNamed(Routes.signInName);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.85),
                ),
                child: const Text('Sign out'),
              ),
            ],
          ),
          if (account != null && account.name.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              greeting,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.0,
            children: <Widget>[
              AdminSummaryCard(
                label: 'Total orders',
                value: '${s.totalOrders}',
                dark: true,
              ),
              AdminSummaryCard(
                label: 'New today',
                value: '${s.newToday}',
                dark: true,
              ),
              AdminSummaryCard(
                label: 'In progress',
                value: '${s.inProgress}',
                dark: true,
              ),
              AdminSummaryCard(
                label: 'Ready',
                value: '${s.readyToCollect}',
                dark: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _updateCard(BuildContext context, AdminOrder o) {
    final String? advance = o.stage.advanceActionLabelShort;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  o.item,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: o.stage.bgColor,
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  o.stage.label,
                  style: TextStyle(
                    color: o.stage.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '#${o.id} · ${o.customerName} · Due ${DateFormatX.dayMonthShort(o.dueDate)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (advance != null) ...<Widget>[
            const SizedBox(height: AppSpacing.smd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    context.read<AdminDashboardCubit>().advanceStage(o.id),
                child: Text(advance),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
