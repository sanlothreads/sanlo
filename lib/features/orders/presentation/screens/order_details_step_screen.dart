import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
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
    final CustomerDetails? details = context
        .read<PlaceOrderBloc>()
        .state
        .draft
        ?.details;

    AuthUser? authUser;
    try {
      authUser = context.read<AuthBloc>().state.user;
    } catch (_) {
      authUser = null;
    }

    // Prefill full name from draft or logged-in user profile
    String initialFullName = details?.fullName ?? '';
    if (initialFullName.isEmpty && authUser != null) {
      final List<String> nameParts = <String>[
        if (authUser.firstName?.trim().isNotEmpty == true)
          authUser.firstName!.trim(),
        if (authUser.lastName?.trim().isNotEmpty == true)
          authUser.lastName!.trim(),
      ];
      initialFullName = nameParts.join(' ');
    }
    _fullNameController = TextEditingController(text: initialFullName);

    // Prefill mobile number from draft or logged-in user profile
    String initialMobile = '';
    final String rawMobile =
        details?.mobile ??
        ((authUser != null && !authUser.isGuest) ? authUser.mobile : null) ??
        '';
    if (rawMobile.isNotEmpty) {
      initialMobile = Validators.normalizeMobile(rawMobile);
    }
    _mobileController = TextEditingController(text: initialMobile);

    // Prefill email from draft or logged-in user profile
    final String initialEmail =
        details?.email ??
        ((authUser != null && !authUser.isGuest) ? authUser.email : null) ??
        '';
    _emailController = TextEditingController(text: initialEmail);

    // Prefill address from draft or logged-in user profile
    final String initialAddress =
        details?.address ??
        ((authUser != null && !authUser.isGuest) ? authUser.address : null) ??
        '';
    _addressController = TextEditingController(text: initialAddress);
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
    final String mobileDigits = _mobileController.text.trim();

    context.read<PlaceOrderBloc>().add(
      CustomerDetailsSubmitted(
        details: CustomerDetails(
          fullName: _fullNameController.text.trim(),
          mobile: '+91 $mobileDigits',
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
                          _buildMobileRow(),
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

  Widget _buildMobileRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.smd,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            '+91',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(hintText: '98765 43210'),
            validator: (String? value) {
              final String fullMobile = '+91 ${value ?? ''}';
              return Validators.isValidIndianMobile(fullMobile)
                  ? null
                  : 'Enter a valid 10-digit mobile number';
            },
          ),
        ),
      ],
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
          ImagePlaceholder(
            imageUrl: product.imageUrls.isNotEmpty
                ? product.imageUrls.first
                : null,
            width: 56,
            height: 56,
            borderRadius: AppRadius.smAll,
            backgroundColor: AppColors.surface,
            fit: BoxFit.scaleDown,
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
