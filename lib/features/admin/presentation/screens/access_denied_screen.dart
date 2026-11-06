import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';

/// Shown when a user is blocked from the admin area.
///
/// Presents the fixed access-denied message and a single "Go to Home" action
/// that routes to the Home tab. Per the recorded tradeoff in the requirements,
/// the action is non-context-aware: unauthenticated/guest users also land on
/// Home rather than Sign in.
class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  // Exact message required by Req 6.2.
                  "Access Denied — you don't have permission to access this page",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Go to Home', // Req 6.3 — single action
                  onPressed: () => context.goNamed(Routes.homeName), // Req 6.4
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
