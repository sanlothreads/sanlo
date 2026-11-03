import 'package:flutter/widgets.dart';

/// Spacing scale for the Sanlo tailoring app.
///
/// A small, consistent set of `double` tokens drives all padding, margins, and
/// gaps so layouts stay rhythmic across screens. Values follow a 4px base grid.
abstract final class AppSpacing {
  const AppSpacing._();

  /// 4.0 — hairline gaps between tightly-related elements.
  static const double xs = 4;

  /// 8.0 — small gaps (icon/label, chip padding).
  static const double sm = 8;

  /// 12.0 — compact spacing used inside dense cards.
  static const double smd = 12;

  /// 16.0 — default content padding and the standard gap between elements.
  static const double md = 16;

  /// 24.0 — section spacing and screen horizontal padding.
  static const double lg = 24;

  /// 32.0 — large gaps between major blocks.
  static const double xl = 32;

  /// 48.0 — extra-large spacing for hero/empty states.
  static const double xxl = 48;

  /// Maximum content width for a screen's body. On wide (web/desktop) windows
  /// the content is capped at this width and centered instead of stretching
  /// edge-to-edge; on phones it has no effect. See [ResponsiveCenter].
  static const double maxContentWidth = 720;

  /// Common horizontal page padding applied to screens.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: md);

  /// Default inset used inside cards and section containers.
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}

/// Corner-radius tokens matching the rounded cards, chips, and buttons in the
/// mockups.
abstract final class AppRadius {
  const AppRadius._();

  /// 8.0 — small controls (inputs, small chips).
  static const double sm = 8;

  /// 12.0 — buttons and medium controls.
  static const double md = 12;

  /// 16.0 — product cards and section containers.
  static const double lg = 16;

  /// 24.0 — large sheets and hero/promo banners.
  static const double xl = 24;

  /// Fully rounded (pills, status badges, circular avatars).
  static const double pill = 999;

  // Convenience [BorderRadius] helpers for the tokens above.

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
