import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/image_placeholder.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/step_indicator.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/customer_details.dart';
import '../bloc/place_order_bloc.dart';
import '../bloc/place_order_event.dart';
import '../bloc/place_order_state.dart';

/// Step 1 of the 3-step order flow — "Your details".
///
/// Collects the customer's contact details (full name + mobile required, email
/// and address optional) for the in-progress [PlaceOrderState.draft]. The
/// [PlaceOrderBloc] is provided by the parent `/order` ShellRoute and already
/// initialised via `OrderStarted`, so this screen reads the bloc with
/// `context.read` and does NOT create its own [BlocProvider].
///
/// On "Continue to measurements" it validates the form, dispatches
/// [CustomerDetailsSubmitted], and navigates to the measurements step.
///
/// Matches the "Order 1/3 – Your details" mockup.
class OrderDetailsStepScreen extends StatefulWidget {
  const OrderDetailsStepScreen({super.key, this.entryProduct});

  final Product? entryProduct;

  @override
  State<OrderDetailsStepScreen> createState() => _OrderDetailsStepScreenState();
}

class _OrderDetailsStepScreenState extends State<OrderDetailsStepScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    // Prefill from the existing draft details (edit case); otherwise start the
    // mobile field with the "+91 " prefix per the mockup.
    final CustomerDetails? details = context
        .read<PlaceOrderBloc>()
        .state
        .draft
        ?.details;
    _fullNameController = TextEditingController(text: details?.fullName ?? '');
    _mobileController = TextEditingController(text: details?.mobile ?? '+91 ');
    _emailController = TextEditingController(text: details?.email ?? '');
    _addressController = TextEditingController(text: details?.address ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onContinue() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String email = _emailController.text.trim();
    final String address = _addressController.text.trim();

    context.read<PlaceOrderBloc>().add(
      CustomerDetailsSubmitted(
        details: CustomerDetails(
          fullName: _fullNameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: email.isEmpty ? null : email,
          address: address.isEmpty ? null : address,
        ),
      ),
    );

    context.pushNamed('orderMeasurements');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Place order'),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: BlocBuilder<PlaceOrderBloc, PlaceOrderState>(
            builder: (BuildContext context, PlaceOrderState state) {
              final Product? product =
                  state.draft?.product ?? widget.entryProduct;

              if (product == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted &&
                      context.read<PlaceOrderBloc>().state.draft?.product ==
                          null &&
                      widget.entryProduct == null) {
                    context.goNamed('home');
                  }
                });
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: <Widget>[
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        children: <Widget>[
                          const StepIndicator(
                            currentStep: 1,
                            totalSteps: 3,
                            label: 'Your details',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _ProductSummary(product: product),
                          const SizedBox(height: AppSpacing.lg),
                          _FieldLabel('Full name'),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _fullNameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Your name',
                            ),
                            validator: (String? value) =>
                                Validators.requiredError(
                                  value,
                                  fieldLabel: 'Full name',
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel('Mobile number'),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: '+91 98765 43210',
                            ),
                            validator: (String? value) =>
                                Validators.mobileError(value),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel('Email (optional)'),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                            ),
                            validator: (String? value) =>
                                Validators.emailError(value),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel('Address (optional)'),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _addressController,
                            keyboardType: TextInputType.multiline,
                            minLines: 3,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'House no., street, area, city',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _BottomBar(onContinue: _onContinue),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A small bold label rendered above each form field.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Muted summary card showing the product being ordered, its turnaround /
/// payment note, and price.
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
          const ImagePlaceholder(
            width: 56,
            height: 56,
            backgroundColor: AppColors.surface,
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
                  'Ready in ${product.readyInDays} days · Pay at shop',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '₹${product.priceInr}',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Pinned bottom bar hosting the primary "Continue to measurements" action.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onContinue});

  final VoidCallback onContinue;

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
          label: 'Continue to measurements',
          onPressed: onContinue,
        ),
      ),
    );
  }
}
