import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.sage,
      onPrimary: AppPalette.ink,
      secondary: AppPalette.sky,
      onSecondary: AppPalette.ink,
      error: AppPalette.terracotta,
      onError: Colors.white,
      surface: AppPalette.surface,
      onSurface: AppPalette.ink,
    );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    final textTheme = baseTextTheme
        .copyWith(
          displayLarge: _display(baseTextTheme.displayLarge),
          displayMedium: _display(baseTextTheme.displayMedium),
          headlineLarge: _headline(baseTextTheme.headlineLarge),
          headlineMedium: _headline(baseTextTheme.headlineMedium),
          titleLarge: _title(baseTextTheme.titleLarge),
          titleMedium: _title(baseTextTheme.titleMedium),
          bodyLarge: _body(baseTextTheme.bodyLarge),
          bodyMedium: _body(baseTextTheme.bodyMedium),
          bodySmall: _body(
            baseTextTheme.bodySmall,
          ).copyWith(color: AppPalette.inkSoft),
          labelLarge: _label(baseTextTheme.labelLarge),
          labelMedium: _label(baseTextTheme.labelMedium),
          labelSmall: _label(baseTextTheme.labelSmall),
        )
        .apply(bodyColor: AppPalette.ink, displayColor: AppPalette.ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppPalette.background,
      canvasColor: AppPalette.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.ink,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: const BorderSide(color: AppPalette.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppPalette.inkMuted),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppPalette.inkSoft),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppPalette.terracotta),
        enabledBorder: _inputBorder(AppPalette.line),
        focusedBorder: _inputBorder(AppPalette.sageStrong),
        errorBorder: _inputBorder(AppPalette.terracotta),
        focusedErrorBorder: _inputBorder(AppPalette.terracotta),
        border: _inputBorder(AppPalette.line),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppPalette.sage,
          foregroundColor: AppPalette.ink,
          disabledBackgroundColor: AppPalette.lineStrong,
          disabledForegroundColor: AppPalette.inkMuted,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.sage,
          foregroundColor: AppPalette.ink,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.ink,
          side: const BorderSide(color: AppPalette.lineStrong),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.surfaceSoft,
        selectedColor: AppPalette.sageSoft,
        disabledColor: AppPalette.line,
        side: const BorderSide(color: AppPalette.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        labelStyle: textTheme.labelMedium ?? const TextStyle(),
        secondaryLabelStyle: (textTheme.labelMedium ?? const TextStyle())
            .copyWith(color: AppPalette.ink),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.xs,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.inkSoft,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.xs,
        ),
        iconColor: AppPalette.inkSoft,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppPalette.background,
        selectedIconTheme: const IconThemeData(color: AppPalette.ink, size: 20),
        unselectedIconTheme: const IconThemeData(
          color: AppPalette.inkSoft,
          size: 20,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppPalette.ink,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppPalette.inkSoft,
        ),
        indicatorColor: AppPalette.sageSoft,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: AppPalette.line,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppPalette.sageStrong, width: 2),
        ),
        labelColor: AppPalette.ink,
        unselectedLabelColor: AppPalette.inkSoft,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
      ),
    );
  }

  static TextStyle numeric(TextStyle? baseStyle) {
    return GoogleFonts.ibmPlexMono(
      textStyle: (baseStyle ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -0.1,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.field),
      borderSide: BorderSide(color: color),
    );
  }

  static TextStyle _display(TextStyle? style) {
    return (style ?? const TextStyle()).copyWith(
      fontSize: 34,
      height: 1.08,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.9,
      color: AppPalette.ink,
    );
  }

  static TextStyle _headline(TextStyle? style) {
    return (style ?? const TextStyle()).copyWith(
      fontSize: 26,
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: AppPalette.ink,
    );
  }

  static TextStyle _title(TextStyle? style) {
    return (style ?? const TextStyle()).copyWith(
      fontSize: 18,
      height: 1.24,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
      color: AppPalette.ink,
    );
  }

  static TextStyle _body(TextStyle? style) {
    return (style ?? const TextStyle()).copyWith(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: AppPalette.ink,
    );
  }

  static TextStyle _label(TextStyle? style) {
    return (style ?? const TextStyle()).copyWith(
      fontSize: 13,
      height: 1.15,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: AppPalette.ink,
    );
  }
}

final class AppPalette {
  static const Color background = Color(0xFFF6F1E8);
  static const Color surface = Color(0xFFFFFDF9);
  static const Color surfaceSoft = Color(0xFFFAF6EF);
  static const Color line = Color(0xFFDDD3C4);
  static const Color lineStrong = Color(0xFFCABDAA);
  static const Color ink = Color(0xFF1D2A22);
  static const Color inkSoft = Color(0xFF37473F);
  static const Color inkMuted = Color(0xFF5F6D65);
  static const Color sage = Color(0xFF98BFA6);
  static const Color sageStrong = Color(0xFF6F9A82);
  static const Color sageSoft = Color(0xFFDCE9E0);
  static const Color sky = Color(0xFF8DBEC6);
  static const Color skySoft = Color(0xFFE8F3F5);
  static const Color apricot = Color(0xFFDDB085);
  static const Color apricotSoft = Color(0xFFF7EDE1);
  static const Color oliveStrong = Color(0xFF8FA16F);
  static const Color oliveSoft = Color(0xFFEEF3E3);
  static const Color blossom = Color(0xFFD3AEB4);
  static const Color terracotta = Color(0xFFC97D6B);
  static const Color menCategory = Color(0xFF8BB8BA);
  static const Color fortyCategory = Color(0xFF8EAF98);
  static const Color fiftyCategory = Color(0xFFB7BE86);
  static const Color womenCategory = Color(0xFFD3AEB4);
}

final class AppSpace {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
}

final class AppRadii {
  static const double field = 18;
  static const double control = 20;
  static const double chip = 999;
  static const double panel = 28;
}
