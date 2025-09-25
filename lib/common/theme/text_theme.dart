// lib/common/theme/text_theme.dart

import 'package:flutter/material.dart';

TextTheme createTextTheme(ColorScheme colorScheme, {String? fontFamily}) {
  // Using the updated text color from requirement
  final Color onSurface = Color(
    0xFF171717,
  ); // Primary text color from requirement
  final Color onSurfaceVariant = Color(0xFF424242); // Secondary text color
  final String defaultFont = fontFamily ?? 'Inter';

  return TextTheme(
    // Display styles - For large, impactful text
    displayLarge: TextStyle(
      fontSize: 64, // Increased from 57 for more impact
      fontWeight: FontWeight.w700, // Bold for headlines
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: -0.5, // Tighter for large text
      height: 1.1, // Better line height
    ),
    displayMedium: TextStyle(
      fontSize: 52, // Increased from 45
      fontWeight: FontWeight.w700,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: -0.25,
      height: 1.15,
    ),
    displaySmall: TextStyle(
      fontSize: 40, // Increased from 36
      fontWeight: FontWeight.w600,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: 0.0,
      height: 1.2,
    ),

    // Headline styles - For section headers
    headlineLarge: TextStyle(
      fontSize: 36, // Increased from 32
      fontWeight: FontWeight.w700,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: -0.25,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 32, // Increased from 28
      fontWeight: FontWeight.w600,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: 0.0,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 28, // Increased from 24
      fontWeight: FontWeight.w600,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: 0.0,
      height: 1.35,
    ),

    // Title styles - For cards, dialogs, and prominent text
    titleLarge: TextStyle(
      fontSize: 24, // Increased from 22
      fontWeight: FontWeight.w600,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: 0.0,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 18, // Increased from 16
      fontWeight: FontWeight.w600,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: 0.1,
      height: 1.45,
    ),
    titleSmall: TextStyle(
      fontSize: 16, // Increased from 14
      fontWeight: FontWeight.w600,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: 0.1,
      height: 1.5,
    ),

    // Body styles - For main content text
    bodyLarge: TextStyle(
      fontSize: 18, // Increased from 16 for better readability
      fontWeight: FontWeight.w400,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: 0.15, // Reduced for better flow
      height: 1.6, // Improved readability
    ),
    bodyMedium: TextStyle(
      fontSize: 16, // Increased from 14
      fontWeight: FontWeight.w400,
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: 0.25,
      height: 1.55,
    ),
    bodySmall: TextStyle(
      fontSize: 14, // Increased from 12
      fontWeight: FontWeight.w400,
      fontFamily: defaultFont,
      color: onSurfaceVariant, // Secondary text color
      letterSpacing: 0.3,
      height: 1.5,
    ),

    // Label styles - For buttons, chips, and small text
    labelLarge: TextStyle(
      fontSize: 16, // Increased from 14
      fontWeight: FontWeight.w600, // Increased weight for prominence
      fontFamily: defaultFont,
      color: onSurface, // Using requirement text color
      letterSpacing: 0.1,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: 14, // Increased from 12
      fontWeight: FontWeight.w600,
      fontFamily: defaultFont,
      color: onSurfaceVariant, // Secondary text color
      letterSpacing: 0.5,
      height: 1.35,
    ),
    labelSmall: TextStyle(
      fontSize: 12, // Increased from 11
      fontWeight: FontWeight.w600,
      fontFamily: defaultFont,
      color: onSurfaceVariant, // Secondary text color
      letterSpacing: 0.5,
      height: 1.3,
    ),
  );
}

/// Extension for custom text styles not covered by Material 3 standard
extension CustomTextStyles on TextTheme {
  /// Caption text for image captions, timestamps, etc.
  TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
    color: Color(0xFF424242), // Secondary text color
    letterSpacing: 0.4,
    height: 1.33,
  );

  /// Overline text for category labels, etc.
  TextStyle get overline => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
    color: Color(0xFF171717), // Primary text color from requirement
    letterSpacing: 1.5,
    height: 1.0,
  );

  /// Button text variant for smaller buttons
  TextStyle get buttonSmall => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
    color: Color(0xFF171717), // Primary text color from requirement
    letterSpacing: 0.1,
    height: 1.0,
  );

  /// Navigation text for bottom nav, tabs, etc.
  TextStyle get navigation => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
    color: Color(0xFF171717), // Primary text color from requirement
    letterSpacing: 0.8,
    height: 1.0,
  );

  /// Primary text style for main content
  TextStyle get primaryText => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
    color: Color(0xFF171717), // Primary text color from requirement
    letterSpacing: 0.15,
    height: 1.5,
  );

  /// Secondary text style for less important content
  TextStyle get secondaryText => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
    color: Color(0xFF424242), // Secondary text color
    letterSpacing: 0.25,
    height: 1.45,
  );
}

/// Utility class for text style variations
class TextStyleVariants {
  static TextStyle semibold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w600);
  }

  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w700);
  }

  static TextStyle light(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w300);
  }

  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  static TextStyle colored(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle spacing(TextStyle style, double letterSpacing) {
    return style.copyWith(letterSpacing: letterSpacing);
  }

  /// Primary color variant (green from requirement)
  static TextStyle primaryColored(TextStyle style) {
    return style.copyWith(color: Color(0xFF2D6A4F));
  }

  /// Text on background color variant
  static TextStyle onBackground(TextStyle style) {
    return style.copyWith(color: Color(0xFF171717));
  }

  /// Disabled text variant
  static TextStyle disabled(TextStyle style) {
    return style.copyWith(color: Color(0xFF9E9E9E));
  }
}
