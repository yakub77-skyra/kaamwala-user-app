import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// KaamWala UI 2.0 Design System (UI overhaul M1).
///
/// Style: premium-trust marketplace. Refined action-orange on warm neutrals
/// with ink-navy type. Token API names are stable across redesigns - screens
/// reference these constants, never raw hex/radii/shadows.
abstract final class KwColors {
  /// Action color - CTAs, highlights, active states ONLY (not decoration).
  static const Color primary = Color(0xFFF4511E);
  static const Color primaryPressed = Color(0xFFD63A0F);

  /// Soft brand tint for wells, selected chips, indicators.
  static const Color primaryLight = Color(0xFFFFF1EA);

  /// Warm neutral canvas & surfaces.
  static const Color background = Color(0xFFFAFAF8);
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle fill for search bars, icon wells, unselected chips.
  static const Color fill = Color(0xFFF3F1ED);

  /// Ink navy - all primary text & dark surfaces.
  static const Color ink = Color(0xFF0F172A);

  /// Secondary text.
  static const Color muted = Color(0xFF6B7280);

  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFE9F8EF);
  static const Color gold = Color(0xFFD97706);
  static const Color goldLight = Color(0xFFFDF3E2);
  static const Color red = Color(0xFFDC2626);
  static const Color redLight = Color(0xFFFDECEC);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFFEAF1FE);

  /// Hairline for card outlines & dividers (~8% ink).
  static const Color line = Color(0x140F172A);

  /// Legacy alias kept so pre-2.0 call sites compile; == [ink].
  @Deprecated('Use KwColors.ink')
  static const Color dark = ink;

  /// Brand gradient (splash / earnings hero). Single source of truth.
  static const List<Color> brandGradient = [
    Color(0xFFF4511E),
    Color(0xFFD63A0F),
  ];
}

/// Elevation system - three levels, no ad-hoc BoxShadows anywhere else.
abstract final class KwShadows {
  /// Resting cards that float above the canvas without outlines.
  static const List<BoxShadow> s1 = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Raised elements: sticky footers, floating panels, profile headers.
  static const List<BoxShadow> s2 = [
    BoxShadow(color: Color(0x12101828), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Hero moments only: logo marks, primary FABs. Brand-tinted.
  static const List<BoxShadow> s3 = [
    BoxShadow(color: Color(0x29F4511E), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

/// Shape scale - exactly four radii. No other corner values allowed.
abstract final class KwRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;

  // Legacy aliases (pre-2.0 call sites) mapped onto the canonical scale.
  static const double card = lg;
  static const double button = md;
  static const double chip = pill;
}

abstract final class KwSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Motion tokens - one feel across the app.
abstract final class KwMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve emphasized = Curves.easeOutCubic;
}

/// Min touch target 48dp for worker hands - NFR-USE-03.
abstract final class KwSizes {
  static const double minTouchTarget = 48;
  static const double buttonHeight = 52;
  static const double bottomNavHeight = 68;
}

/// App theme - Material 3 + Plus Jakarta Sans (Phase 3 section 1.2).
abstract final class AppTheme {
  /// Canonical type ramp. Sizes are fixed here - widgets must not invent
  /// font sizes; they pick a role and optionally adjust colour only.
  static TextTheme _ramp(TextTheme gf) => gf.copyWith(
    displaySmall: gf.displaySmall?.copyWith(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
      height: 1.1,
    ),
    headlineMedium: gf.headlineMedium?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -.5,
    ),
    headlineSmall: gf.headlineSmall?.copyWith(
      fontSize: 21,
      fontWeight: FontWeight.w800,
      letterSpacing: -.4,
    ),
    titleLarge: gf.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -.3,
    ),
    titleMedium: gf.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -.2,
    ),
    titleSmall: gf.titleSmall?.copyWith(
      fontSize: 14.5,
      fontWeight: FontWeight.w700,
      letterSpacing: -.1,
    ),
    bodyLarge: gf.bodyLarge?.copyWith(
      fontSize: 15.5,
      fontWeight: FontWeight.w500,
      height: 1.45,
    ),
    bodyMedium: gf.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    bodySmall: gf.bodySmall?.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      height: 1.45,
    ),
    labelLarge: gf.labelLarge?.copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
    ),
    labelMedium: gf.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: .2,
    ),
    labelSmall: gf.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: .3,
    ),
  );

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: KwColors.primary,
      onPrimary: Colors.white,
      secondary: KwColors.ink,
      onSecondary: Colors.white,
      surface: KwColors.surface,
      onSurface: KwColors.ink,
      error: KwColors.red,
      outline: KwColors.muted,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: KwColors.background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _ramp(
        GoogleFonts.plusJakartaSansTextTheme().apply(
          bodyColor: KwColors.ink,
          displayColor: KwColors.ink,
        ),
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
      appBarTheme: AppBarTheme(
        backgroundColor: KwColors.background,
        foregroundColor: KwColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: base.textTheme.titleLarge!.copyWith(
          color: KwColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: KwColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KwRadius.lg),
          side: const BorderSide(color: KwColors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KwColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: KwColors.primary.withValues(alpha: .4),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(KwSizes.buttonHeight),
          elevation: 0,
          textStyle: base.textTheme.labelLarge!.copyWith(
            fontSize: 15.5,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KwRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KwColors.ink,
          minimumSize: const Size.fromHeight(KwSizes.buttonHeight),
          side: const BorderSide(color: KwColors.line),
          textStyle: base.textTheme.labelLarge!.copyWith(fontSize: 15.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KwRadius.md),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KwColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(KwSizes.buttonHeight),
          textStyle: base.textTheme.labelLarge!.copyWith(
            fontSize: 15.5,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KwRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KwColors.fill,
        hintStyle: base.textTheme.bodyMedium!.copyWith(color: KwColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KwSpacing.lg,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.md),
          borderSide: const BorderSide(color: KwColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.md),
          borderSide: const BorderSide(color: KwColors.red, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KwRadius.md),
          borderSide: const BorderSide(color: KwColors.red, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: KwColors.fill,
        selectedColor: KwColors.primaryLight,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: base.textTheme.labelMedium,
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
          (states) => base.textTheme.labelSmall!.copyWith(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KwRadius.lg),
        ),
        titleTextStyle: base.textTheme.titleLarge,
        contentTextStyle: base.textTheme.bodyMedium!.copyWith(
          color: KwColors.muted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KwColors.ink,
        contentTextStyle: base.textTheme.bodyMedium!.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KwRadius.md),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KwColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KwRadius.lg),
          ),
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
