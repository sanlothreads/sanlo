import 'package:flutter/material.dart';

/// Centralized color palette for the Sanlo tailoring app.
///
/// The design uses a deep crimson/maroon primary (brand red) for CTAs,
/// selected states, progress indicators, links and the active bottom-nav tab.
/// Product cards sit on soft pastel backgrounds, each with its own accent icon
/// color. Text is near-black for headings with a muted slate grey for body
/// copy, all on a warm off-white scaffold. Dedicated status colors cover the
/// order lifecycle (In progress / Ready / Completed).
///
/// All members are static so colors can be referenced without an instance,
/// e.g. `AppColors.primary`.
abstract final class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Brand / primary
  // ---------------------------------------------------------------------------

  /// Deep crimson/maroon primary used for CTAs, selected states, progress
  /// indicators, links and accents. This is the Sanlo brand red.
  static const Color primary = Color(0xFF9F1D2B);

  /// Slightly darker maroon for pressed states and gradients.
  static const Color primaryDark = Color(0xFF7E1622);

  /// Light red/pink tint for subtle backgrounds and selected chips.
  static const Color primaryLight = Color(0xFFF9E6E9);

  /// Foreground color placed on top of [primary].
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Deep brand red used for the splash screen and app icon background.
  /// Kept as an alias of [primary] now that the whole app is red-themed.
  static const Color brandRed = Color(0xFF9F1D2B);

  /// Warm cream used for the logo mark and text on [brandRed].
  static const Color brandCream = Color(0xFFF7F0E6);

  // ---------------------------------------------------------------------------
  // Surfaces / backgrounds
  // ---------------------------------------------------------------------------

  /// Warm off-white scaffold background behind all screens.
  static const Color scaffoldBackground = Color(0xFFF5F2EE);

  /// Default card / sheet surface (white).
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle surface used for inputs and inactive controls.
  static const Color surfaceMuted = Color(0xFFF1EEEA);

  /// Hairline borders and dividers.
  static const Color border = Color(0xFFE6E1DB);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  /// Near-black primary text.
  static const Color textPrimary = Color(0xFF1A1A22);

  /// Muted slate-grey secondary text (captions, metadata).
  static const Color textSecondary = Color(0xFF5E6472);

  /// Faint grey for hints and disabled text.
  static const Color textTertiary = Color(0xFF9A9AA8);

  // ---------------------------------------------------------------------------
  // Pastel card backgrounds (product grid)
  // ---------------------------------------------------------------------------

  /// Soft red/pink pastel card background.
  static const Color cardPink = Color(0xFFFBEAEE);

  /// Soft magenta/pink pastel card background.
  static const Color cardMagenta = Color(0xFFFCE7F0);

  /// Fresh mint pastel card background.
  static const Color cardMint = Color(0xFFE4F3EC);

  /// Warm peach pastel card background.
  static const Color cardPeach = Color(0xFFFCEEE2);

  /// Cool blue pastel card background.
  static const Color cardBlue = Color(0xFFE9EFFA);

  /// Light lavender/purple pastel card background.
  static const Color cardLavender = Color(0xFFF0EAFA);

  /// Ordered palette used to tint product cards in a repeating cycle.
  static const List<Color> cardPalette = <Color>[
    cardPink,
    cardMagenta,
    cardMint,
    cardPeach,
    cardBlue,
    cardLavender,
  ];

  /// Returns a pastel card background for the given index, cycling through
  /// [cardPalette]. Safe for any non-negative index.
  static Color cardBackgroundForIndex(int index) =>
      cardPalette[index % cardPalette.length];

  // ---------------------------------------------------------------------------
  // Pastel card icon accents (product grid)
  // ---------------------------------------------------------------------------

  /// Crimson accent icon (pairs with [cardPink]).
  static const Color iconCrimson = Color(0xFFB0203A);

  /// Magenta accent icon (pairs with [cardMagenta]).
  static const Color iconMagenta = Color(0xFFC81D73);

  /// Green accent icon (pairs with [cardMint]).
  static const Color iconGreen = Color(0xFF1E9E63);

  /// Orange accent icon (pairs with [cardPeach]).
  static const Color iconOrange = Color(0xFFE2622A);

  /// Blue accent icon (pairs with [cardBlue]).
  static const Color iconBlue = Color(0xFF2F6FD6);

  /// Purple accent icon (pairs with [cardLavender]).
  static const Color iconPurple = Color(0xFF7A3FD1);

  /// Icon accent colors aligned 1:1 with [cardPalette] by index.
  static const List<Color> iconPalette = <Color>[
    iconCrimson,
    iconMagenta,
    iconGreen,
    iconOrange,
    iconBlue,
    iconPurple,
  ];

  /// Returns an accent icon color for the given index, cycling through
  /// [iconPalette]. Safe for any non-negative index.
  static Color iconAccentForIndex(int index) =>
      iconPalette[index % iconPalette.length];

  // ---------------------------------------------------------------------------
  // Order status colors
  // ---------------------------------------------------------------------------

  /// "In progress" status — brand crimson.
  static const Color statusInProgress = Color(0xFF9F1D2B);

  /// Soft background tint for an "In progress" badge.
  static const Color statusInProgressBg = Color(0xFFF9E6E9);

  /// "Ready" status — green.
  static const Color statusReady = Color(0xFF1FA971);

  /// Soft background tint for a "Ready" badge.
  static const Color statusReadyBg = Color(0xFFD9F0E2);

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
