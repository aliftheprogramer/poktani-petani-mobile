// lib/common/theme/color_theme.dart
import 'package:flutter/material.dart';
import 'package:niteni/common/theme/text_theme.dart';

class AppColors {
  // Primary Brand Colors - Updated to match requirement
  static const Color primary = Color(
    0xFF2D6A4F,
  ); // Primary green from requirement
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(
    0xFFB8D4C6,
  ); // Light green variant
  static const Color onPrimaryContainer = Color(0xFF0F2419);

  // Secondary Colors - Complementary neutral tones
  static const Color secondary = Color(0xFF52796F); // Muted green-grey
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD5E3DF);
  static const Color onSecondaryContainer = Color(0xFF1B2E26);

  // Tertiary Colors - Warm accent for contrast
  static const Color tertiary = Color(0xFF6B705C); // Sage green
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFE8EAE6);
  static const Color onTertiaryContainer = Color(0xFF252720);

  // Surface Colors - Updated to match requirement
  static const Color surface = Color(
    0xFFFAFAFA,
  ); // Clean white for cards/surfaces
  static const Color onSurface = Color(
    0xFF171717,
  ); // Text color from requirement
  static const Color surfaceContainerHighest = Color(0xFFE0E0E0);
  static const Color onSurfaceVariant = Color(0xFF424242);
  static const Color surfaceContainer = Color(
    0xFFEEEEEE,
  ); // Background from requirement
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);

  // Outline Colors
  static const Color outline = Color(0xFFBDBDBD);
  static const Color outlineVariant = Color(0xFFE0E0E0);

  // Status & Semantic Colors - Harmonized with new palette
  static const Color error = Color(0xFFD32F2F); // Red that works with green
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onErrorContainer = Color(0xFF7F0000);

  static const Color warning = Color(0xFFF57C00); // Orange warning
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarningContainer = Color(0xFF663C00);

  static const Color success = Color(
    0xFF2E7D32,
  ); // Success green similar to primary
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color onSuccessContainer = Color(0xFF1B5E20);

  static const Color info = Color(0xFF1976D2); // Info blue
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFE3F2FD);
  static const Color onInfoContainer = Color(0xFF0D47A1);

  // Legacy Colors for backward compatibility
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color white = Colors.white;
  static const Color black = Color(0xFF171717); // Updated to match requirement
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(
    0xFFEEEEEE,
  ); // Updated to match requirement

  // Text Colors (using semantic colors from requirement)
  static const Color textPrimary = Color(
    0xFF171717,
  ); // Text color from requirement
  static const Color textSecondary = Color(0xFF424242);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textOnPrimary = onPrimary;
  static const Color textOnSurface = Color(
    0xFF171717,
  ); // Text color from requirement
}

class AppGradients {
  // Primary gradient with updated colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4CAF50), // Lighter green
      Color(0xFF2D6A4F), // Primary from requirement
      Color(0xFF1B5E20), // Darker green
    ],
  );

  // Secondary gradient for accents
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF66BB6A), // Light green
      Color(0xFF52796F), // Secondary green-grey
      Color(0xFF388E3C), // Medium green
    ],
  );

  // Neutral gradient for surfaces
  static const LinearGradient neutralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6B705C), // Sage green
      Color(0xFF52796F), // Muted green-grey
      Color(0xFF2D6A4F), // Primary green
    ],
  );

  // Subtle surface gradient
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAFAFA), // Light surface
      Color(0xFFEEEEEE), // Background from requirement
    ],
  );
}

// Create Material 3 Color Scheme with updated colors
final ColorScheme lightColorScheme = ColorScheme.light(
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.primaryContainer,
  onPrimaryContainer: AppColors.onPrimaryContainer,

  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  secondaryContainer: AppColors.secondaryContainer,
  onSecondaryContainer: AppColors.onSecondaryContainer,

  tertiary: AppColors.tertiary,
  onTertiary: AppColors.onTertiary,
  tertiaryContainer: AppColors.tertiaryContainer,
  onTertiaryContainer: AppColors.onTertiaryContainer,

  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  surfaceContainerHighest: AppColors.surfaceContainerHighest,
  onSurfaceVariant: AppColors.onSurfaceVariant,

  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,

  outline: AppColors.outline,
  outlineVariant: AppColors.outlineVariant,
);

/// Enhanced theme data following Material 3 guidelines
/// with updated color palette as per requirement
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,

  // Typography
  textTheme: createTextTheme(lightColorScheme, fontFamily: 'Inter'),

  // AppBar Theme - Clean and modern with updated colors
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors
        .surfaceContainer, // Using surfaceContainer instead of deprecated background
    foregroundColor: AppColors
        .onSurface, // Using onSurface instead of deprecated onBackground
    elevation: 0,
    surfaceTintColor: lightColorScheme.surfaceTint,
    scrolledUnderElevation: 1,
    titleTextStyle: TextStyle(
      color: AppColors
          .onSurface, // Using onSurface instead of deprecated onBackground
      fontSize: 22,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
      letterSpacing: 0,
    ),
    iconTheme: IconThemeData(
      color: AppColors
          .onSurface, // Using onSurface instead of deprecated onBackground
      size: 24,
    ),
  ),

  // Card Theme - Fixed type issue
  cardTheme: CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: lightColorScheme.surfaceTint,
    elevation: 1,
    shadowColor: Colors.black.withValues(
      alpha: 0.05,
    ), // Updated withOpacity to withValues
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.all(8),
  ),

  // Button Themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, // Updated primary color
      foregroundColor: AppColors.onPrimary,
      elevation: 2,
      shadowColor: AppColors.primary.withValues(
        alpha: 0.3,
      ), // Updated withOpacity to withValues
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        letterSpacing: 0.1,
      ),
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary, // Updated primary color
      foregroundColor: AppColors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        letterSpacing: 0.1,
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary, // Updated primary color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        letterSpacing: 0.1,
      ),
    ),
  ),

  // Input Decoration Theme - Modern form fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors
        .surfaceContainerHighest, // Updated to use non-deprecated color
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.primary,
        width: 2,
      ), // Updated primary
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.error, width: 1),
    ),
    labelStyle: TextStyle(
      color: AppColors.onSurfaceVariant,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    ),
    hintStyle: TextStyle(
      color: AppColors.onSurfaceVariant,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // Chip Theme
  chipTheme: ChipThemeData(
    backgroundColor: AppColors
        .surfaceContainerHighest, // Updated to use non-deprecated color
    labelStyle: TextStyle(
      color: AppColors.onSurfaceVariant,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),

  // Bottom Navigation Bar Theme
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary, // Updated primary color
    unselectedItemColor: AppColors.onSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: const TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
    unselectedLabelStyle: const TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      fontSize: 12,
    ),
  ),

  // FloatingActionButton Theme
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary, // Updated primary color
    foregroundColor: AppColors.onPrimary,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Divider Theme
  dividerTheme: DividerThemeData(
    color: AppColors.outlineVariant,
    thickness: 1,
    space: 1,
  ),
);
