import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanlo/core/theme/app_colors.dart';
import 'package:sanlo/core/theme/app_spacing.dart';
import 'package:sanlo/core/widgets/image_placeholder.dart';
import 'package:sanlo/core/widgets/responsive_center.dart';
import 'package:sanlo/core/widgets/section_card.dart';
import 'package:sanlo/core/widgets/status_badge.dart';
import 'package:sanlo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sanlo/features/orders/domain/entities/order.dart';
import 'package:sanlo/features/orders/domain/repositories/order_repository.dart';
import 'package:sanlo/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:sanlo/features/orders/presentation/cubit/orders_state.dart';

/// The "My orders" tab — lists the signed-in (or guest) customer's orders
/// split into Active / Completed buckets ("My orders" mockup).
///
/// Shows a title, a two-segment Active/Completed toggle bound to
/// [OrdersState.bucket], a guest sign-in info banner, and a list of order
/// cards built from [OrdersState.visible]. Each card shows the product, order
/// id + placed date, a [StatusBadge], a segmented progress bar, the next step,
/// and the amount payable at the shop. Tapping a card navigates to the order
/// tracking screen.
///
/// The bottom navigation bar is provided by the shell scaffold, so this screen
/// renders only the tab content inside a plain [Scaffold].
///
/// The [OrdersCubit] is provided locally, reading the [OrderRepository] from
/// the widget tree and kicking off [OrdersCubit.load] immediately.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>(
      create: (context) => OrdersCubit(context.read<OrderRepository>())..load(),
      child: const _MyOrdersView(),
    );
  }
}

class _MyOrdersView extends StatelessWidget {
  const _MyOrdersView();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: ResponsiveCenter(
          child: BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, state) {
              // A guest sees only the info banner; a signed-in user sees their
              // order list (and not the guest banner).
              final bool signedIn = context
                  .watch<AuthBloc>()
                  .state
                  .isAuthenticated;

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                children: <Widget>[
                  Text(
                    'My orders',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (signedIn) ...<Widget>[
                    _BucketToggle(
                      bucket: state.bucket,
                      onSelected: (bucket) =>
                          context.read<OrdersCubit>().selectBucket(bucket),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._buildBody(context, state, textTheme),
                  ] else
                    const _GuestBanner(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    OrdersState state,
    TextTheme textTheme,
  ) {
    if (state.loading) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.error != null) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: Center(
            child: Text(
              state.error!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ];
    }

    final List<Order> orders = state.visible;
    if (orders.isEmpty) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: Center(
            child: Text(
              'No orders yet',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ];
    }

    final List<Widget> cards = <Widget>[];
    for (int i = 0; i < orders.length; i++) {
      cards.add(_OrderCard(order: orders[i]));
      if (i != orders.length - 1) {
        cards.add(const SizedBox(height: AppSpacing.smd));
      }
    }
    return cards;
  }
}

/// A two-segment Active / Completed toggle. The selected segment is drawn as a
/// white pill on the muted track.
class _BucketToggle extends StatelessWidget {
  const _BucketToggle({required this.bucket, required this.onSelected});

  final OrderBucket bucket;
  final ValueChanged<OrderBucket> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ToggleSegment(
              label: 'Active',
              selected: bucket == OrderBucket.active,
              onTap: () => onSelected(OrderBucket.active),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: 'Completed',
              selected: bucket == OrderBucket.completed,
              onTap: () => onSelected(OrderBucket.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: AppRadius.pillAll,
        ),
        child: Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A light indigo info banner shown to guests, inviting them to sign in so
/// their orders follow them across devices.
class _GuestBanner extends StatefulWidget {
  const _GuestBanner();

  @override
  State<_GuestBanner> createState() => _GuestBannerState();
}

class _GuestBannerState extends State<_GuestBanner> {
  late final TapGestureRecognizer _tapRecognizer;

  @override
  void initState() {
    super.initState();
    _tapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        if (mounted) {
          context.pushNamed('signIn');
        }
      };
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? baseStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.smd),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.mdAll,
      ),
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: <InlineSpan>[
            const TextSpan(text: 'Showing orders for +91 98765 43210. '),
            const TextSpan(text: 'Sign in to see them on any device. '),
            TextSpan(
              text: 'Sign in',
              style: baseStyle?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer: _tapRecognizer,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tappable order card showing the product, id + date, status badge,
/// a segmented progress bar, the next step, and the amount payable at the shop.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  static const int _segments = 6;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.pushNamed(
        'orderTracking',
        pathParameters: <String, String>{'id': order.id},
      ),
      behavior: HitTestBehavior.opaque,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ImagePlaceholder(
                  imageUrl: order.product.imageUrls.isNotEmpty
                      ? order.product.imageUrls.first
                      : null,
                  width: 56,
                  height: 56,
                  borderRadius: AppRadius.mdAll,
                  backgroundColor: AppColors.cardLavender,
                  icon: Icons.checkroom,
                ),
                const SizedBox(width: AppSpacing.smd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        order.product.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '#${order.id} · ${_formatDate(order.placedDate)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.smd),
            _ProgressBar(progress: order.progress, segments: _segments),
            const SizedBox(height: AppSpacing.smd),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Next: ${order.nextStep}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '₹${order.amountAtShopInr}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal segmented progress bar. [segments] cells are drawn; the first
/// `ceil(progress * segments)` are filled indigo, the rest grey.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.segments});

  final double progress;
  final int segments;

  @override
  Widget build(BuildContext context) {
    final double clamped = progress.clamp(0.0, 1.0);
    final int filled = (clamped * segments).ceil().clamp(0, segments);

    return Row(
      children: <Widget>[
        for (int i = 0; i < segments; i++) ...<Widget>[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < filled ? AppColors.primary : AppColors.border,
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
          if (i != segments - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

/// Short month abbreviations for the local "d MMM" date formatter.
const List<String> _monthsShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [date] as "d MMM" (e.g. "24 Oct") without an `intl` dependency.
String _formatDate(DateTime date) {
  final String month = _monthsShort[(date.month - 1) % 12];
  return '${date.day} $month';
}
