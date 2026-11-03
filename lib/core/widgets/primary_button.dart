import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A full-width indigo call-to-action button used across the order flow and
/// detail screens.
///
/// Relies on the app's [ElevatedButton] theme (styled in `AppTheme.light` as a
/// full-width indigo CTA) and layers in two behaviours on top:
///
/// - When [onPressed] is `null`, the button is disabled.
/// - When [loading] is `true`, the button shows a small
///   [CircularProgressIndicator] in place of its content and is disabled so it
///   cannot be tapped again while an action is in flight.
///
/// An optional leading [icon] is rendered before the [label].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  /// Text displayed on the button.
  final String label;

  /// Tap handler. When `null` the button is rendered in a disabled state.
  final VoidCallback? onPressed;

  /// When `true`, shows a progress spinner and disables interaction.
  final bool loading;

  /// Optional leading icon displayed before [label].
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Disable while loading so the action cannot be triggered twice.
    final VoidCallback? effectiveOnPressed = loading ? null : onPressed;

    final Widget child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
            ),
          )
        : _buildLabel();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: effectiveOnPressed, child: child),
    );
  }

  Widget _buildLabel() {
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(label),
      ],
    );
  }
}
