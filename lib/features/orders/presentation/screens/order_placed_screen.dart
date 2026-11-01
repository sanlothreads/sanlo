import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

/// Success confirmation shown after an order is placed.
///
/// Receives the placed [orderId] (wired by the router from a query/path
/// parameter) and fetches the matching [Order] via
/// `context.read<OrderRepository>().getOrderById` so the summary rows reflect
/// the real order. While the fetch is in flight the success UI renders with the
/// id and generic placeholders; if the id is unknown
/// ([NotFoundFailure]) the success UI still shows with the id and generic copy.
///
/// Offers two bottom actions — "Track order" (→ `orderTracking`) and "Back to
/// home" (→ `home`) — both via `context.goNamed` so the in-progress order flow
/// stack is cleared.
///
/// Matches the "Order placed" mockup.
class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({super.key, required this.orderId});

  /// The id of the order that was just placed, e.g. "SN-1048".
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final OrderRepository repository = context.read<OrderRepository>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: FutureBuilder<Order>(
          future: repository.getOrderById(orderId),
          builder: (BuildContext context, AsyncSnapshot<Order> snapshot) {
            // On success use the real order; on not-found / still-loading fall
            // back to null so the UI shows the id with generic copy.
            final Order? order =
                snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData
                ? snapshot.data
                : null;

            return _OrderPlacedView(orderId: orderId, order: order);
          },
        ),
      ),
    );
  }
}

/// Centered success content plus the pinned bottom actions. Rendered for every
/// snapshot state so the success UI is always visible.
class _OrderPlacedView extends StatelessWidget {
  const _OrderPlacedView({required this.orderId, required this.order});

  final String orderId;

  /// The loaded order, or `null` while loading or when the id is unknown.
  final Order? order;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Prefer the loaded order's id; fall back to the passed-in id otherwise.
    final String resolvedId = order?.id ?? orderId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: <Widget>[
          const Spacer(),
          const _SuccessBadge(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Order placed!',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "We've received your order. You'll get an SMS when each step is "
            'done.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _OrderSummary(orderId: resolvedId, order: order),
          const Spacer(),
          PrimaryButton(
            label: 'Track order',
            onPressed: () => context.goNamed(
              'orderTracking',
              pathParameters: <String, String>{'id': resolvedId},
            ),
          ),
          const SizedBox(height: AppSpacing.smd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.goNamed('home'),
              child: const Text('Back to home'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large green circular check badge shown at the top of the success state.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        color: AppColors.statusReadyBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.statusReady,
        size: 48,
      ),
    );
  }
}

/// Muted summary card listing the order id, item, estimated ready time, and the
/// amount payable at the shop. Falls back to generic copy while the order is
/// loading or unknown.
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.orderId, required this.order});

  final String orderId;
  final Order? order;

  @override
  Widget build(BuildContext context) {
    final Order? order = this.order;

    final String item = order?.product.name ?? '—';
    final String estReady = order != null
        ? '${order.product.readyInDays} days after measurement'
        : 'A few days after measurement';
    final String payAtShop = order != null
        ? '₹${order.amountAtShopInr}'
        : 'At the shop';

    return SectionCard(
      backgroundColor: AppColors.surfaceMuted,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _SummaryRow(label: 'Order ID', value: '#$orderId'),
          const SizedBox(height: AppSpacing.smd),
          _SummaryRow(label: 'Item', value: item),
          const SizedBox(height: AppSpacing.smd),
          _SummaryRow(label: 'Est. ready', value: estReady),
          const SizedBox(height: AppSpacing.smd),
          _SummaryRow(label: 'Pay at shop', value: payAtShop),
        ],
      ),
    );
  }
}

/// A single label/value row inside the summary card.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
