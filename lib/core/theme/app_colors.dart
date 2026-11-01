import 'package:flutter/material.dart';

/// Centralized color palette for the Sanlo tailoring app.
///
/// The design uses an indigo/purple primary, soft pastel card backgrounds for
/// the product grid, near-black text with muted grey secondary text, a light
/// grey scaffold background, and dedicated status colors for the order
/// lifecycle (In progress / Ready / Completed).
///
/// All members are static so colors can be referenced without an instance,
/// e.g. `AppColors.primary`.
abstract final class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Brand / primary
  // ---------------------------------------------------------------------------

  /// Indigo/purple primary used for CTAs, selected states, and accents.
  static const Color primary = Color(0xFF5B4FE0);

  /// Slightly darker indigo for pressed states and gradients.
  static const Color primaryDark = Color(0xFF4639C4);

  /// Light indigo tint for subtle backgrounds and selected chips.
  static const Color primaryLight = Color(0xFFEDEBFC);

  /// Foreground color placed on top of [primary].
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Deep brand red used for the splash screen and app icon background.
  static const Color brandRed = Color(0xFF9F1D2B);

  /// Warm cream used for the logo mark and text on [brandRed].
  static const Color brandCream = Color(0xFFF7F0E6);

  // ---------------------------------------------------------------------------
  // Surfaces / backgrounds
  // ---------------------------------------------------------------------------

  /// Light grey scaffold background behind all screens.
  static const Color scaffoldBackground = Color(0xFFF5F5F8);

  /// Default card / sheet surface (white).
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle surface used for inputs and inactive controls.
  static const Color surfaceMuted = Color(0xFFF0F0F4);

  /// Hairline borders and dividers.
  static const Color border = Color(0xFFE4E4EC);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  /// Near-black primary text.
  static const Color textPrimary = Color(0xFF1A1A22);

  /// Muted grey secondary text (captions, metadata).
  static const Color textSecondary = Color(0xFF6B6B7B);

  /// Faint grey for hints and disabled text.
  static const Color textTertiary = Color(0xFF9A9AA8);

  // ---------------------------------------------------------------------------
  // Pastel card backgrounds (product grid)
  // ---------------------------------------------------------------------------

  /// Light lavender pastel card background.
  static const Color cardLavender = Color(0xFFEDE9FB);

  /// Soft pink pastel card background.
  static const Color cardPink = Color(0xFFFCE7F0);

  /// Warm peach pastel card background.
  static const Color cardPeach = Color(0xFFFCEBDD);

  /// Fresh mint pastel card background.
  static const Color cardMint = Color(0xFFDFF3EC);

  /// Ordered palette used to tint product cards in a repeating cycle.
  static const List<Color> cardPalette = <Color>[
    cardLavender,
    cardPink,
    cardPeach,
    cardMint,
  ];

  /// Returns a pastel card background for the given index, cycling through
  /// [cardPalette]. Safe for any non-negative index.
  static Color cardBackgroundForIndex(int index) =>
      cardPalette[index % cardPalette.length];

  // ---------------------------------------------------------------------------
  // Order status colors
  // ---------------------------------------------------------------------------

  /// "In progress" status — indigo/blue.
  static const Color statusInProgress = Color(0xFF5B4FE0);

  /// Soft background tint for an "In progress" badge.
  static const Color statusInProgressBg = Color(0xFFEDEBFC);

  /// "Ready" status — green.
  static const Color statusReady = Color(0xFF1FA971);

  /// Soft background tint for a "Ready" badge.
  static const Color statusReadyBg = Color(0xFFDFF3EC);

  /// "Completed" status — muted grey-green.
  static const Color statusCompleted = Color(0xFF6B8577);

  /// Soft background tint for a "Completed" badge.
  static const Color statusCompletedBg = Color(0xFFE8EDEA);

  // ---------------------------------------------------------------------------
  // Feedback
  // ---------------------------------------------------------------------------

  /// Error / destructive color (used for inline validation messages).
  static const Color error = Color(0xFFD64545);

  /// Soft background tint for error banners.
  static const Color errorBg = Color(0xFFFBE9E9);

  /// Amber used for ratings and highlights.
  static const Color rating = Color(0xFFF5A623);
}
