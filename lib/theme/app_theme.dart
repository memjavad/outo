import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Digital Curator Color Palette ---
  static const Color primary = Color(0xFF001D2F);
  static const Color primaryContainer = Color(0xFF00334E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  static const Color secondary = Color(0xFF006497);
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  static const Color background = Color(0xFFF8FAFB);
  static const Color onBackground = Color(0xFF191C1D);
  
  static const Color surface = Color(0xFFF8FAFB);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF42474D);
  
  // Custom Tonal Surfaces
  static const Color surfaceContainerLow = Color(0xFFF2F4F5);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  
  static const Color outlineVariant = Color(0xFFC2C7CE);

  // Ghost Border implementation for Focus State 
  static final Color ghostBorderColor = secondary.withOpacity(0.4);

  static ThemeData getLightTheme([Color? dynamicPrimary]) {
    final activePrimary = dynamicPrimary ?? primary;
    final activePrimaryContainer = dynamicPrimary != null 
        ? HSLColor.fromColor(dynamicPrimary).withLightness(0.15).toColor() 
        : primaryContainer;

    // Determine the base TextTheme enforcing Inter globally
    final baseTextTheme = GoogleFonts.interTextTheme();
    
    // Manrope for high-end headers
    final manropeFont = GoogleFonts.manrope().fontFamily;
    
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: manropeFont, fontSize: 56, fontWeight: FontWeight.w700, color: onSurface,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: manropeFont, fontSize: 28, fontWeight: FontWeight.w600, color: onSurface,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22, fontWeight: FontWeight.w600, color: onSurface,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w400, color: onSurfaceVariant,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w500, color: onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: activePrimary,
        onPrimary: onPrimary,
        primaryContainer: activePrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainer: surface,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      
      // Card Theme: No elevation, uses lowest container color, 24px radius
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant.withOpacity(0.6),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ghostBorderColor, width: 2),
        ),
      ),

      // Elevated Buttons (Primary CTAs)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: activePrimary, 
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: GoogleFonts.manrope(
            fontSize: 18, 
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: activePrimary,
          side: BorderSide(color: outlineVariant.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      // Removing all horizontal standard dividers natively
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 32, // Equivalent to spacing-8
      ),
    );
  }
}
