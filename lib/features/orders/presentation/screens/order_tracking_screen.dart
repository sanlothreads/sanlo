import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/phone_launcher.dart';
import '../../../../core/widgets/image_placeholder.dart';
import '../../../../core/widgets/order_timeline.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../cubit/order_tracking_cubit.dart';
import '../cubit/order_tracking_state.dart';

/// Phone number for the sample tailoring shop, dialed by "Call the shop".
const String _shopPhoneNumber = '+919876543210';

/// The Order tracking screen (matches the "Order tracking" mockup).
///
/// Shows an indigo header card summarizing the order (product, placed date,
/// amount at shop, current status, and expected-ready date), a white "Tracking"
/// card hosting the six-stage [OrderTimeline], and a "Call the shop" action
/// that dials the shop via [PhoneLauncher].
///
/// The [OrderTrackingCubit] is provided locally and loads the order and its
/// timeline for [orderId] on creation. When the id is unknown the cubit emits
/// an error ("Not found") and a simple not-found view with a back action is
/// shown instead of the content.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  /// The id of the order to track, e.g. "SN-1048".
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderTrackingCubit>(
      create: (c) =>
          OrderTrackingCubit(c.read<OrderRepository>())..load(orderId),
      child: _OrderTrackingView(orderId: orderId),
    );
  }
}

class _OrderTrackingView extends StatelessWidget {
  const _OrderTrackingView({required this.orderId});

  final String orderId;

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.homeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
      builder: (context, state) {
        if (state.error == 'Not found') {
          return const _NotFoundView();
        }

        // Prefer the loaded order id for the title once available.
        final String titleId = state.order?.id ?? orderId;

        return PopScope(
          canPop: context.canPop(),
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _handleBack(context);
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBack(context),
              ),
              title: Text('Order #$titleId'),
            ),
            body: ResponsiveCenter(
              child: state.loading && state.order == null
                  ? const Center(child: CircularProgressIndicator())
                  : _LoadedBody(state: state),
            ),
          ),
        );
      },
    );
  }
}

/// The scrollable tracking content: header card, tracking card, and the
/// "Call the shop" action.
class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});

  final OrderTrackingState state;

  @override
  Widget build(BuildContext context) {
    final Order? order = state.order;
    if (order == null) {
      return const _NotFoundView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _HeaderCard(order: order),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Tracking',
            child: OrderTimeline(steps: state.timeline),
          ),
          const SizedBox(height: AppSpacing.md),
          const _CallShopButton(),
        ],
      ),
    );
  }
}

/// Indigo header card summarizing the order: product + placed/amount line and
/// a current-status / expected-ready row.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.lgAll,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ImagePlaceholder(
                imageUrl: order.product.imageUrls.isNotEmpty
                    ? order.product.imageUrls.first
                    : null,
                width: 56,
                height: 56,
                icon: Icons.checkroom,
                borderRadius: AppRadius.mdAll,
                backgroundColor: Colors.white24,
                foregroundColor: AppColors.onPrimary,
              ),
              const SizedBox(width: AppSpacing.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      order.product.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Placed ${_formatDayMonth(order.placedDate)} · '
                      '₹${order.amountAtShopInr} at shop',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Current status',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      order.nextStep,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Expected ${_formatDayMonth(order.expectedReady)}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Outlined "Call the shop" button that dials the sample shop number.
class _CallShopButton extends StatelessWidget {
  const _CallShopButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => PhoneLauncher.call(_shopPhoneNumber),
      icon: const Icon(Icons.phone),
      label: const Text('Call the shop'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }
}

/// Simple "Not found" state with a back action, shown when the order id is
/// unknown.
class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.homeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context),
          ),
          title: const Text('Order'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.search_off,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Not found', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We could not find that order.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => _handleBack(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Local "d MMM" date formatter (e.g. "5 Mar") avoiding an `intl` dependency.
String _formatDayMonth(DateTime date) {
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
