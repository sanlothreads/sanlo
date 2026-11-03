import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/image_placeholder.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';

/// The Sign in / Welcome screen.
///
/// Presents the brand header with a "Skip" (continue-as-guest) action, a hero
/// placeholder, the headline/subtext, a `+91` mobile entry, a revealed OTP
/// field once a code has been sent, a "Continue as guest" secondary action,
/// and a "Create an account" link to the Sign up screen.
///
/// The screen is purely presentational around the app-wide [AuthBloc]: it reads
/// the bloc via `context.read` and reacts to [AuthState] through a
/// [BlocConsumer]. It does not create a [BlocProvider] — `app.dart` provides the
/// bloc. On [AuthPhase.authenticated] it navigates to Home.
///
/// Validates Requirements 1.1, 1.2, 1.3, 1.4, 1.6, 1.7.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear any stale auth state (e.g. a previous error) when the screen opens.
    context.read<AuthBloc>().add(const AuthReset());
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(OtpRequested(_mobileController.text.trim()));
  }

  void _verifyOtp() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(OtpVerified(_otpController.text.trim()));
  }

  void _continueAsGuest() {
    context.read<AuthBloc>().add(const GuestRequested());
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (BuildContext context, AuthState state) {
            if (state.phase == AuthPhase.authenticated) {
              context.goNamed('home');
            } else if (state.phase == AuthPhase.needsRegistration) {
              // OTP verified but no profile yet: send the user to Sign up,
              // seeding the verified mobile so they can't change it there.
              context.pushNamed('signUp', extra: state.user);
            }
          },
          builder: (BuildContext context, AuthState state) {
            // Reveal the OTP field once a session exists (code was sent).
            final bool showOtpField = state.session != null;
            final bool isBusy =
                state.phase == AuthPhase.sendingOtp ||
                state.phase == AuthPhase.verifying ||
                state.phase == AuthPhase.creating;
            final bool hasError = state.phase == AuthPhase.error;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildHeader(context, textTheme),
                  const SizedBox(height: AppSpacing.lg),
                  const ImagePlaceholder(
                    height: 200,
                    icon: Icons.checkroom,
                    caption: '[Hero photo – your shop / work]',
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Clothes stitched to your exact measure',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sign in to track your orders, or continue as a guest.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMobileLabel(textTheme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildMobileRow(enabled: !isBusy),
                  if (showOtpField) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    _buildOtpLabel(textTheme),
                    const SizedBox(height: AppSpacing.sm),
                    _buildOtpField(enabled: !isBusy),
                  ],
                  if (hasError && state.errorMessage != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.errorMessage!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: showOtpField ? 'Verify' : 'Send OTP',
                    loading: isBusy,
                    onPressed: showOtpField ? _verifyOtp : _sendOtp,
                  ),
                  const SizedBox(height: AppSpacing.smd),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isBusy ? null : _continueAsGuest,
                      child: const Text('Continue as guest'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSignUpLink(context, textTheme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Row(
      children: <Widget>[
        const Icon(Icons.content_cut, color: AppColors.primary, size: 28),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Sanlo',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        TextButton(onPressed: _continueAsGuest, child: const Text('Skip')),
      ],
    );
  }

  Widget _buildMobileLabel(TextTheme textTheme) {
    return Text(
      'Mobile number',
      style: textTheme.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildMobileRow({required bool enabled}) {
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
          child: TextField(
            controller: _mobileController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(hintText: '98765 43210'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpLabel(TextTheme textTheme) {
    return Text(
      'Enter OTP',
      style: textTheme.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildOtpField({required bool enabled}) {
    return TextField(
      controller: _otpController,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: const InputDecoration(hintText: '000000'),
    );
  }

  Widget _buildSignUpLink(BuildContext context, TextTheme textTheme) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            'New to Sanlo? ',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          GestureDetector(
            onTap: () => context.pushNamed('signUp'),
            child: Text(
              'Create an account',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
