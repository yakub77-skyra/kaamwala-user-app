import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// KaamWala v2 Design System - Phase 3 section 1.
/// Brand colors carried over from v1.
abstract final class KwColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFFF4500);
  static const Color primaryLight = Color(0xFFFFF0E8);
  static const Color background = Color(0xFFFFF8F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF1A1A2E);
  static const Color muted = Color(0xFF7A7A9D);
  static const Color green = Color(0xFF22C55E);
  static const Color gold = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF3B82F6);
}

/// Shape & spacing tokens - Phase 3 section 1.3.
abstract final class KwRadius {
  static const double card = 16;
  static const double button = 12;
  static const double chip = 999;
}

abstract final class KwSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Min touch target 48dp for worker hands - NFR-USE-03.
abstract final class KwSizes {
  static const double minTouchTarget = 48;
  static const double buttonHeight = 52;
  static const double bottomNavHeight = 64;
}

/// App theme - Material 3 + Plus Jakarta Sans (Phase 3 section 1.2).
abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: KwColors.primary,
      onPrimary: Colors.white,
      secondary: KwColors.dark,
      onSecondary: Colors.white,
      surface: KwColors.surface,
      onSurface: KwColors.dark,
      error: KwColors.red,
      outline: KwColors.muted,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: KwColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: KwColors.dark,
        displayColor: KwColors.dark,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: KwColors.background,
        foregroundColor: KwColors.dark,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: KwColors.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: KwColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KwRadius.card),
          side: const BorderSide(color: Color(0x141A1A2E)),
        ),
        shadowColor: const Color(0x141A1A2E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KwColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(KwSizes.buttonHeight),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KwRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KwColors.primary,
          minimumSize: const Size.fromHeight(KwSizes.buttonHeight),
          side: const BorderSide(color: KwColors.primary),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KwRadius.button),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KwColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: KwSpacing.lg, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
          borderSide: const BorderSide(color: Color(0x291A1A2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
          borderSide: const BorderSide(color: Color(0x291A1A2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
          borderSide: const BorderSide(color: KwColors.primary, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: KwSizes.bottomNavHeight,
        backgroundColor: KwColors.surface,
        indicatorColor: KwColors.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? KwColors.primary
                  : KwColors.muted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? KwColors.primary
                  : KwColors.muted,
            )),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x141A1A2E)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
        ),
      ),
    );
  }
}
