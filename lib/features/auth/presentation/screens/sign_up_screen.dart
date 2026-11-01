import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/entities/gender.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/auth_user.dart';
import '../bloc/auth_bloc.dart';

/// Sign up ("Create your account") screen.
///
/// Collects first name, last name, mobile, email, and gender, then dispatches
/// [AccountSubmitted] with the assembled [AuthUser] draft. Navigation and
/// loading state are driven by the app-wide [AuthBloc]:
///
/// - [AuthPhase.creating] shows a spinner on the submit button.
/// - [AuthPhase.authenticated] navigates to Home.
///
/// A "Sign in" link at the bottom returns to the Sign in screen.
///
/// Validates Requirements 1.8, 1.9, 1.10.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  /// Currently selected gender; defaults to [Gender.female] per the mockup.
  Gender _selectedGender = Gender.female;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Returns the trimmed field value, or `null` when it is empty, so optional
  /// fields are stored as `null` rather than empty strings on the draft.
  String? _nullIfEmpty(TextEditingController controller) {
    final String text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  void _onCreateAccount() {
    final AuthUser draft = AuthUser(
      isGuest: false,
      firstName: _nullIfEmpty(_firstNameController),
      lastName: _nullIfEmpty(_lastNameController),
      mobile: _nullIfEmpty(_mobileController),
      email: _nullIfEmpty(_emailController),
      gender: _selectedGender,
    );
    context.read<AuthBloc>().add(AccountSubmitted(draft));
  }

  /// Goes back to the Sign in screen, popping if possible, otherwise routing by
  /// name so the link works even when there is nothing to pop back to.
  void _onSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('signIn');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (AuthState previous, AuthState current) =>
          previous.phase != current.phase,
      listener: (BuildContext context, AuthState state) {
        if (state.phase == AuthPhase.authenticated) {
          context.goNamed('home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Create your account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Save your details and measurements for faster orders.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // First + last name row.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _LabeledField(
                        label: 'First name',
                        hint: 'Priya',
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _LabeledField(
                        label: 'Last name',
                        hint: 'Sharma',
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                _LabeledField(
                  label: 'Mobile number',
                  hint: '+91 98765 43210',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                _LabeledField(
                  label: 'Email',
                  hint: 'priya@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.md),

                // Gender segmented pills.
                Text(
                  'Gender',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    _GenderPill(
                      label: 'Female',
                      selected: _selectedGender == Gender.female,
                      onTap: () =>
                          setState(() => _selectedGender = Gender.female),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _GenderPill(
                      label: 'Male',
                      selected: _selectedGender == Gender.male,
                      onTap: () =>
                          setState(() => _selectedGender = Gender.male),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _GenderPill(
                      label: 'Other',
                      selected: _selectedGender == Gender.other,
                      onTap: () =>
                          setState(() => _selectedGender = Gender.other),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (AuthState previous, AuthState current) =>
                      previous.phase != current.phase,
                  builder: (BuildContext context, AuthState state) {
                    final bool loading = state.phase == AuthPhase.creating;
                    return PrimaryButton(
                      label: 'Create account',
                      loading: loading,
                      onPressed: _onCreateAccount,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _onSignIn,
                        child: Text(
                          'Sign in',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A form field with a label above it, matching the sign-up mockup.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

/// A selectable pill for the gender segmented control.
///
/// When [selected], it renders with an indigo-tinted background and border per
/// the mockup; otherwise it uses the muted surface styling.
class _GenderPill extends StatelessWidget {
  const _GenderPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: selected ? AppColors.primaryLight : AppColors.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.smd),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
