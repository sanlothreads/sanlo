import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A bundled-asset-free "dummy image" box used everywhere the app would
/// otherwise show a photo (product grid cards, product detail carousel,
/// profile hero, etc.).
///
/// It renders a rounded container with a centered icon and, when provided, a
/// caption below it (for example `[Photo 1 of 4]` or
/// `[Hero photo – your shop / work]`). This is the app's dummy-image strategy:
/// no network calls and no bundled assets. When real images arrive later, the
/// internals can be swapped while keeping this same public API.
///
/// The background and foreground colors are customizable so product cards can
/// tint each placeholder per category using the pastel
/// [AppColors.cardPalette].
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.icon = Icons.checkroom,
    this.caption,
    this.height,
    this.width,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// The glyph shown in the center of the placeholder. Defaults to a
  /// t-shirt-ish [Icons.checkroom].
  final IconData icon;

  /// Optional caption rendered beneath the icon, e.g. `[Photo 1 of 4]`.
  ///
  /// When null, only the icon is shown.
  final String? caption;

  /// Optional fixed height for the box. When null the placeholder sizes to its
  /// parent / content constraints.
  final double? height;

  /// Optional fixed width for the box. When null the placeholder expands to
  /// fill the available horizontal space.
  final double? width;

  /// Corner radius of the box. Defaults to [AppRadius.lgAll].
  final BorderRadius? borderRadius;

  /// Background fill of the box. Defaults to [AppColors.cardLavender].
  final Color? backgroundColor;

  /// Color applied to the icon and caption. Defaults to a muted tone derived
  /// from the palette ([AppColors.textSecondary]).
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final Color background = backgroundColor ?? AppColors.cardLavender;
    final Color foreground = foregroundColor ?? AppColors.textSecondary;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String? caption = this.caption;

    final double effectiveIconSize =
        (height != null && height! <= 64) || (width != null && width! <= 64)
            ? 24.0
            : 40.0;
    final EdgeInsets effectivePadding =
        (height != null && height! <= 64) || (width != null && width! <= 64)
            ? const EdgeInsets.all(AppSpacing.xs)
            : const EdgeInsets.all(AppSpacing.md);

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius ?? AppRadius.lgAll,
      ),
      padding: effectivePadding,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: effectiveIconSize, color: foreground),
          if (caption != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ],
        ],
      ),
    );
  }
}
