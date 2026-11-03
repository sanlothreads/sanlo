import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// The app's launch splash screen.
///
/// Shows the Sanlo logo mark (`assets/image/splash_image.png`) with the brand
/// name and tagline on the deep-red brand background for a fixed 2 seconds,
/// then routes to the Sign in screen. The screen is purely presentational and
/// owns a single [Timer] it cancels on dispose to avoid navigating after the
/// widget is gone.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// How long the splash is shown before navigating onward.
  static const Duration _displayDuration = Duration(seconds: 2);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  /// Set once the minimum display duration has elapsed. Routing only happens
  /// once this is true *and* the auth session restore has settled.
  bool _delayElapsed = false;

  /// Guards against navigating more than once.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen._displayDuration, () {
      _delayElapsed = true;
      _routeOnward();
    });
  }

  /// Sends an already-signed-in user straight to Home and everyone else to
  /// Sign in — but only after the splash delay has elapsed and the session
  /// restore kicked off by [AppStarted] is no longer in flight.
  ///
  /// Called both when the timer fires and whenever the [AuthBloc] state
  /// changes, so whichever settles last triggers the navigation.
  void _routeOnward() {
    if (!mounted || _navigated || !_delayElapsed) return;
    final AuthState state = context.read<AuthBloc>().state;
    if (state.phase == AuthPhase.restoring) return; // still resolving

    _navigated = true;
    context.goNamed(
      state.isAuthenticated ? Routes.homeName : Routes.signInName,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (AuthState previous, AuthState current) =>
          previous.phase != current.phase,
      listener: (BuildContext context, AuthState state) => _routeOnward(),
      child: Scaffold(
        backgroundColor: AppColors.brandRed,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                'assets/image/splash_image.png',
                width: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sanlo',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.brandCream,
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.smd),
              Text(
                'CUSTOM STITCHING',
                style: GoogleFonts.montserrat(
                  color: AppColors.brandCream,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
