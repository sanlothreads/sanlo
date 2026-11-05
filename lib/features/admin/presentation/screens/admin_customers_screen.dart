import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/entities/admin_customer.dart';
import '../cubit/admin_customers_cubit.dart';
import '../cubit/admin_customers_state.dart';
import '../widgets/customer_table.dart';

/// The admin Customers directory: searchable by name or mobile. Wide layouts
/// show the table; narrow layouts show stacked cards.
class AdminCustomersScreen extends StatelessWidget {
  const AdminCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCustomersCubit, AdminCustomersState>(
      builder: (context, state) {
        if (state.status == AdminCustomersStatus.loading ||
            state.status == AdminCustomersStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminCustomersStatus.failure) {
          return _error(context, state.error);
        }

        final bool wide =
            MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;
        final List<AdminCustomer> customers = state.visibleCustomers;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _header(context, wide),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: customers.isEmpty
                    ? const Center(
                        child: Text('No customers match your search'),
                      )
                    : SingleChildScrollView(
                        child: SectionCard(
                          child: wide
                              ? CustomerTable(customers: customers)
                              : _stacked(customers),
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
        onChanged: (t) => context.read<AdminCustomersCubit>().search(t),
        decoration: const InputDecoration(
          hintText: 'Name or mobile',
          prefixIcon: Icon(Icons.search, size: 20),
          isDense: true,
        ),
      ),
    );

    if (wide) {
      return Row(
        children: <Widget>[
          const Text(
            'Customers',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          search,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Customers',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        search,
      ],
    );
  }

  Widget _stacked(List<AdminCustomer> customers) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < customers.length; i++)
          _stackedRow(customers[i], last: i == customers.length - 1),
      ],
    );
  }

  Widget _stackedRow(AdminCustomer c, {required bool last}) {
    final String lastOrderStr = (c.orderCount > 0 && c.lastOrderDate != null)
        ? DateFormatX.dayMonthShort(c.lastOrderDate!)
        : '—';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.smd),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              c.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  c.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.mobile} · Orders: ${c.orderCount} · Last Order: $lastOrderStr',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (c.registeredDate != null ||
                    c.lastLogin != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    'Reg: ${c.registeredDate ?? '—'} · Login: ${c.lastLogin ?? '—'}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
            onPressed: () => context.read<AdminCustomersCubit>().load(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
