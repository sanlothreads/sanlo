import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Central [ThemeData] factory for the Sanlo tailoring app.
///
/// The theme is assembled from the [AppColors] palette and the [AppSpacing] /
/// [AppRadius] tokens so every screen shares the same crimson-on-off-white
/// look: near-black headings, muted grey body text, rounded inputs, full-width
/// crimson CTAs, rounded pastel-friendly cards, category filter chips, and a
/// crimson/grey bottom navigation bar.
///
/// Usage: `MaterialApp(theme: AppTheme.light, ...)`.
abstract final class AppTheme {
  const AppTheme._();

  /// The single light theme used across the app.
  static ThemeData get light {
    final ColorScheme colorScheme = _colorScheme;
    final TextTheme textTheme = _buildTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      textTheme: textTheme,
      // Material components default to the primary font color for icons/labels.
      primaryColor: AppColors.primary,
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: _inputDecorationTheme(textTheme),
      elevatedButtonTheme: _elevatedButtonTheme(textTheme),
      filledButtonTheme: _filledButtonTheme(textTheme),
      textButtonTheme: _textButtonTheme(textTheme),
      outlinedButtonTheme: _outlinedButtonTheme(textTheme),
      cardTheme: _cardTheme,
      chipTheme: _chipTheme(textTheme),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(textTheme),
    );
  }

  // ---------------------------------------------------------------------------
  // Color scheme
  // ---------------------------------------------------------------------------

  /// A light [ColorScheme] seeded from the crimson [AppColors.primary] and then
  /// pinned to the palette's surface/error/border colors so the generated
  /// tones never drift away from the mockups.
  static ColorScheme get _colorScheme {
    final ColorScheme seeded = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return seeded.copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surfaceMuted,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.error,
      onError: AppColors.onPrimary,
      errorContainer: AppColors.errorBg,
    );
  }

  // ---------------------------------------------------------------------------
  // Text theme
  // ---------------------------------------------------------------------------

  /// Builds the text theme: near-black [AppColors.textPrimary] for display,
  /// headline, title, and label roles (headings), and muted
  /// [AppColors.textSecondary] for body and caption roles.
  static TextTheme _buildTextTheme(TextTheme base) {
    TextStyle heading(TextStyle? style, double size, FontWeight weight) =>
        (style ?? const TextStyle()).copyWith(
          color: AppColors.textPrimary,
          fontSize: size,
          fontWeight: weight,
          height: 1.25,
        );

    TextStyle body(TextStyle? style, double size, Color color) =>
        (style ?? const TextStyle()).copyWith(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w400,
          height: 1.45,
        );

    return base.copyWith(
      // Headings — near-black.
      displayLarge: heading(base.displayLarge, 32, FontWeight.w700),
      displayMedium: heading(base.displayMedium, 28, FontWeight.w700),
      displaySmall: heading(base.displaySmall, 24, FontWeight.w700),
      headlineLarge: heading(base.headlineLarge, 24, FontWeight.w700),
      headlineMedium: heading(base.headlineMedium, 22, FontWeight.w700),
      headlineSmall: heading(base.headlineSmall, 20, FontWeight.w600),
      titleLarge: heading(base.titleLarge, 18, FontWeight.w600),
      titleMedium: heading(base.titleMedium, 16, FontWeight.w600),
      titleSmall: heading(base.titleSmall, 14, FontWeight.w600),
      // Body — muted grey.
      bodyLarge: body(base.bodyLarge, 16, AppColors.textPrimary),
      bodyMedium: body(base.bodyMedium, 14, AppColors.textSecondary),
      bodySmall: body(base.bodySmall, 12, AppColors.textSecondary),
      // Labels (buttons/chips) — near-black, slightly heavier.
      labelLarge: heading(base.labelLarge, 14, FontWeight.w600),
      labelMedium: heading(base.labelMedium, 12, FontWeight.w600),
      labelSmall: (base.labelSmall ?? const TextStyle()).copyWith(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Inputs
  // ---------------------------------------------------------------------------

  /// Rounded, filled input fields with [AppColors.border] outlines that turn
  /// indigo on focus and red on error.
  static InputDecorationTheme _inputDecorationTheme(TextTheme textTheme) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.smd,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.primary,
      ),
      helperStyle: textTheme.bodySmall,
      errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary, 1.5),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.5),
      disabledBorder: border(AppColors.border),
    );
  }

  // ---------------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------------

  static const Size _ctaMinimumSize = Size(0, 52);

  static final RoundedRectangleBorder _ctaShape = RoundedRectangleBorder(
    borderRadius: AppRadius.mdAll,
  );

  /// Full-width crimson elevated CTA (the primary call-to-action style).
  static ElevatedButtonThemeData _elevatedButtonTheme(TextTheme textTheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.surfaceMuted,
        disabledForegroundColor: AppColors.textTertiary,
        minimumSize: _ctaMinimumSize,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: _ctaShape,
        textStyle: textTheme.labelLarge,
      ),
    );
  }

  /// Filled button mirrors the elevated CTA so either widget renders the same
  /// full-width crimson button.
  static FilledButtonThemeData _filledButtonTheme(TextTheme textTheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.surfaceMuted,
        disabledForegroundColor: AppColors.textTertiary,
        minimumSize: _ctaMinimumSize,
        shape: _ctaShape,
        textStyle: textTheme.labelLarge,
      ),
    );
  }

  /// Text buttons (links like "Create an account" / "Sign in") in crimson.
  static TextButtonThemeData _textButtonTheme(TextTheme textTheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: textTheme.labelLarge,
        shape: _ctaShape,
      ),
    );
  }

  /// Outlined buttons (secondary actions) with a crimson border.
  static OutlinedButtonThemeData _outlinedButtonTheme(TextTheme textTheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: _ctaMinimumSize,
        side: const BorderSide(color: AppColors.primary),
        shape: _ctaShape,
        textStyle: textTheme.labelLarge,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cards
  // ---------------------------------------------------------------------------

  /// Flat white cards with a large [AppRadius.lg] corner radius.
  static final CardThemeData _cardTheme = CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
  );

  // ---------------------------------------------------------------------------
  // Chips (category filter)
  // ---------------------------------------------------------------------------

  /// Pill-shaped filter chips: muted surface when unselected, crimson when
  /// selected, used for the Home category filter (All / Women / Men / Kids).
  static ChipThemeData _chipTheme(TextTheme textTheme) {
    return ChipThemeData(
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: AppColors.primary,
      secondarySelectedColor: AppColors.primary,
      disabledColor: AppColors.surfaceMuted,
      checkmarkColor: AppColors.onPrimary,
      showCheckmark: false,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: const StadiumBorder(),
      labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
      secondaryLabelStyle: textTheme.labelLarge?.copyWith(
        color: AppColors.onPrimary,
      ),
      brightness: Brightness.light,
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------------

  /// Fixed bottom navigation bar: crimson for the selected tab, grey for the
  /// unselected tabs, on a white surface.
  static BottomNavigationBarThemeData _bottomNavigationBarTheme(
    TextTheme textTheme,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      selectedLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.primary,
      ),
      unselectedLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }
}
