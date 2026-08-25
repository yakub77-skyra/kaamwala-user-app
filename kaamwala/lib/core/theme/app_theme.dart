import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// KaamWala v2 Design System - Phase 3 section 1.
/// Brand colors carried over from v1.
abstract final class KwColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFE8551F);
  static const Color primaryLight = Color(0xFFFFF0E8);

  /// Soft neutral canvas - slightly cooler than pure warm white.
  static const Color background = Color(0xFFF7F6F3);
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle fill for search bars, icon wells, unselected chips.
  static const Color fill = Color(0xFFF1EFEA);

  static const Color dark = Color(0xFF191A23);
  static const Color muted = Color(0xFF71738A);
  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFE8F7EE);
  static const Color gold = Color(0xFFD97706);
  static const Color goldLight = Color(0xFFFDF3E2);
  static const Color red = Color(0xFFDC2626);
  static const Color redLight = Color(0xFFFDECEC);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFFEAF1FE);

  /// Hairline used for card outlines & dividers.
  static const Color line = Color(0x12191A23);
}

/// Shape & spacing tokens - Phase 3 section 1.3.
abstract final class KwRadius {
  static const double card = 18;
  static const double button = 14;
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
  static const double bottomNavHeight = 68;
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
      splashFactory: InkSparkle.splashFactory,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: KwColors.dark,
        displayColor: KwColors.dark,
      ),
    );

    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Horizontal slide + back-swipe feel on Android, native elsewhere.
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KwColors.background,
        foregroundColor: KwColors.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: KwColors.dark,
          letterSpacing: -.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: KwColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KwRadius.card),
          side: const BorderSide(color: KwColors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KwColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: KwColors.primary.withValues(alpha: .45),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(KwSizes.buttonHeight),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KwRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KwColors.dark,
          minimumSize: const Size.fromHeight(KwSizes.buttonHeight),
          side: const BorderSide(color: Color(0x29191A23)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KwRadius.button),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KwColors.dark,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(KwSizes.buttonHeight),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KwRadius.button),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KwColors.fill,
        hintStyle: const TextStyle(color: KwColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KwSpacing.lg,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
          borderSide: const BorderSide(color: KwColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
          borderSide: const BorderSide(color: KwColors.red, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
          borderSide: const BorderSide(color: KwColors.red, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: KwColors.fill,
        selectedColor: KwColors.primaryLight,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: KwSizes.bottomNavHeight,
        backgroundColor: KwColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: KwColors.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? KwColors.primary
                : KwColors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? KwColors.primary
                : KwColors.muted,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KwColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: KwColors.dark,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14.5,
          height: 1.45,
          color: KwColors.muted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KwColors.dark,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KwRadius.button),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KwColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: KwColors.line, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? KwColors.green : null,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KwColors.primary,
      ),
    );
  }
}
