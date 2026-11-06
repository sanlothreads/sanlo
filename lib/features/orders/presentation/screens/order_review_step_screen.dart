import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/image_placeholder.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/step_indicator.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/customer_details.dart';
import '../../domain/entities/measurement_set.dart';
import '../bloc/place_order_bloc.dart';
import '../bloc/place_order_event.dart';
import '../bloc/place_order_state.dart';

/// Step 3 of the 3-step order flow — "Review".
///
/// Summarises the in-progress [PlaceOrderState.draft] (product, customer
/// details and measurements) and lets the customer place the order. The
/// [PlaceOrderBloc] is provided by the parent `/order` ShellRoute, so this
/// screen reads it via `context.read` / [BlocConsumer] and does NOT create its
/// own [BlocProvider].
///
/// Each summary section exposes an "Edit" action that jumps back to the
/// relevant step (dispatching [EditDetailsRequested] / [EditMeasurementsRequested]
/// to preserve the draft). The pinned "Place order" button dispatches
/// [OrderPlaced] and shows a spinner while `step == placing`; once the order is
/// placed a [BlocListener] navigates to the confirmation screen, passing the
/// new order id as an `id` query parameter.
///
/// Matches the "Order 3/3 – Review" mockup.
class OrderReviewStepScreen extends StatelessWidget {
  const OrderReviewStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('home');
            }
          },
        ),
        title: const Text('Place order'),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: BlocConsumer<PlaceOrderBloc, PlaceOrderState>(
            listenWhen: (PlaceOrderState previous, PlaceOrderState current) =>
                current.step == OrderStep.placed && current.placedOrder != null,
            listener: (BuildContext context, PlaceOrderState state) {
              // Navigate to the confirmation screen once the order is placed,
              // handing over the new order id via a query parameter.
              context.goNamed(
                'orderPlaced',
                queryParameters: <String, String>{'id': state.placedOrder!.id},
              );
            },
            builder: (BuildContext context, PlaceOrderState state) {
              if (state.draft?.product == null ||
                  state.draft?.details == null ||
                  state.draft?.measurements == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final OrderDraftView view = OrderDraftView(state);

              return Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.lg,
                      ),
                      children: <Widget>[
                        const StepIndicator(
                          currentStep: 3,
                          totalSteps: 3,
                          label: 'Review',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ProductSummary(product: view.product),
                        const SizedBox(height: AppSpacing.md),
                        _DetailsSection(details: view.details),
                        const SizedBox(height: AppSpacing.md),
                        _MeasurementsSection(measurements: view.measurements),
                        const SizedBox(height: AppSpacing.md),
                        _ChargesSection(product: view.product),
                        const SizedBox(height: AppSpacing.md),
                        const _PaymentNote(),
                        if (state.errorMessage != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          _ErrorText(message: state.errorMessage!),
                        ],
                      ],
                    ),
                  ),
                  _BottomBar(
                    loading: state.step == OrderStep.placing,
                    onPlaceOrder: () =>
                        context.read<PlaceOrderBloc>().add(const OrderPlaced()),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Thin convenience wrapper that pulls the non-null draft fields out of the
/// bloc state. The review screen is only ever shown once the draft is fully
/// populated, so the required parts are asserted non-null here.
@visibleForTesting
class OrderDraftView {
  OrderDraftView(PlaceOrderState state)
    : product = state.draft!.product,
      details = state.draft!.details!,
      measurements = state.draft!.measurements!;

  final Product product;
  final CustomerDetails details;
  final MeasurementSet measurements;
}

/// Muted card showing the product being ordered and its turnaround note.
class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SectionCard(
      backgroundColor: AppColors.surfaceMuted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: SizedBox(
              width: 56,
              height: 56,
              child: product.imageUrls.isNotEmpty
                  ? Image.network(
                      product.imageUrls.first,
                      width: 56,
                      height: 56,
                      fit: BoxFit.scaleDown,
                      errorBuilder: (ctx, err, stack) => const ImagePlaceholder(
                        width: 56,
                        height: 56,
                        backgroundColor: AppColors.surface,
                      ),
                    )
                  : const ImagePlaceholder(
                      width: 56,
                      height: 56,
                      backgroundColor: AppColors.surface,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  product.name,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Est. ready in ${product.readyInDays} days after measurement',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Your details" summary with an indigo "Edit" action that returns to step 1.
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.details});

  final CustomerDetails details;

  void _onEdit(BuildContext context) {
    context.read<PlaceOrderBloc>().add(const EditDetailsRequested());
    context.pushNamed('orderDetails');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String email =
        (details.email != null && details.email!.trim().isNotEmpty)
        ? details.email!.trim()
        : 'No email';
    final String address =
        (details.address != null && details.address!.trim().isNotEmpty)
        ? details.address!.trim()
        : 'No address';

    return SectionCard(
      title: 'Your details',
      trailing: _EditButton(onPressed: () => _onEdit(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            details.fullName,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            details.mobile,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$email · $address',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Measurements" summary. Shows a value grid when the customer supplied their
/// own measurements, or a "we'll measure you" note otherwise.
class _MeasurementsSection extends StatelessWidget {
  const _MeasurementsSection({required this.measurements});

  final MeasurementSet measurements;

  void _onEdit(BuildContext context) {
    context.read<PlaceOrderBloc>().add(const EditMeasurementsRequested());
    context.pushNamed('orderMeasurements');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget body;
    if (measurements.knowsMeasurements) {
      body = _MeasurementGrid(measurements: measurements);
    } else {
      body = Text(
        "We'll measure you at the shop.",
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    return SectionCard(
      title: 'Measurements',
      trailing: _EditButton(onPressed: () => _onEdit(context)),
      child: body,
    );
  }
}

/// A two-column grid of labelled inch values (Bust / Waist / Shoulder /
/// Sleeve / Armhole / Length), omitting any measurement that was left blank.
class _MeasurementGrid extends StatelessWidget {
  const _MeasurementGrid({required this.measurements});

  final MeasurementSet measurements;

  @override
  Widget build(BuildContext context) {
    final List<_Measurement> entries = <_Measurement>[
      _Measurement('Bust', measurements.bust),
      _Measurement('Waist', measurements.waist),
      _Measurement('Shoulder', measurements.shoulder),
      _Measurement('Sleeve', measurements.sleeveLength),
      _Measurement('Armhole', measurements.armhole),
      _Measurement('Length', measurements.blouseLength),
    ].where((_Measurement m) => m.value != null).toList();

    if (entries.isEmpty) {
      final TextTheme textTheme = Theme.of(context).textTheme;
      return Text(
        'No measurements entered.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    return Wrap(
      runSpacing: AppSpacing.smd,
      children: <Widget>[
        for (final _Measurement entry in entries)
          FractionallySizedBox(
            widthFactor: 0.5,
            child: _MeasurementTile(entry: entry),
          ),
      ],
    );
  }
}

class _Measurement {
  const _Measurement(this.label, this.value);

  final String label;
  final double? value;
}

/// A single `Label` / `12"` cell inside [_MeasurementGrid].
class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({required this.entry});

  final _Measurement entry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          entry.label,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_formatInches(entry.value!)}"',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Formats an inch value without a trailing ".0" for whole numbers.
  String _formatInches(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

/// Charges breakdown: the stitching charge and the bold "To pay at shop" total.
class _ChargesSection extends StatelessWidget {
  const _ChargesSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String price = '₹${product.priceInr}';

    return SectionCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Stitching charge',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(price, style: textTheme.bodyMedium),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.smd),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'To pay at shop',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                price,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Amber info box reminding the customer that payment happens in person.
class _PaymentNote extends StatelessWidget {
  const _PaymentNote();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 20, color: AppColors.rating),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No online payment. Pay by cash or UPI when you collect '
              'your order.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline red error message shown above the place-order button.
class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Text(
      message,
      style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
    );
  }
}

/// Small indigo "Edit" text button used as the trailing action of a section.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// Pinned bottom bar hosting the primary "Place order" action.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.loading, required this.onPlaceOrder});

  final bool loading;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.smd,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: 'Place order',
          loading: loading,
          onPressed: onPlaceOrder,
        ),
      ),
    );
  }
}
