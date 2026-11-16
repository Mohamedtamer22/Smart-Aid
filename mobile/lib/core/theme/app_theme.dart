import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const blue = Color(0xff1769AA);
  static const oceanBlue = blue;
  static const navy = Color(0xff0B3B6E);
  static const navyBlue = navy;
  static const deepNavy = Color(0xff071A33);
  static const sky = Color(0xffEAF5FF);
  static const emergencyRed = Color(0xffD92D20);
  static const softRed = Color(0xffFEF2F2);
  static const success = Color(0xff12B76A);
  static const softSuccess = Color(0xffECFDF5);
  static const mintTeal = Color(0xff00A896);
  static const warning = Color(0xffF79009);
  static const softWarning = Color(0xffFFFBEB);
  static const indigo = Color(0xff4F46E5);
  static const background = Color(0xffF4F7FB);
  static const surfaceAlt = Color(0xffF8FAFD);
  static const text = Color(0xff0F172A);
  static const charcoal = Color(0xff1E293B);
  static const textMuted = Color(0xff5B6B82);
  static const border = Color(0xffDDE5EF);
  static const radius = 20.0;

  static LinearGradient heroGradient(Color base) {
    final hsl = HSLColor.fromColor(base);
    final deeper = hsl
        .withLightness((hsl.lightness - 0.14).clamp(0.10, 0.85))
        .withSaturation((hsl.saturation + 0.06).clamp(0.0, 1.0))
        .toColor();
    final brighter = hsl
        .withLightness((hsl.lightness + 0.05).clamp(0.15, 0.90))
        .toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [brighter, base, deeper],
      stops: const [0.0, 0.45, 1.0],
    );
  }

  static const splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xff061529), Color(0xff0B2E58), Color(0xff145991)],
    stops: [0.0, 0.55, 1.0],
  );

  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: blue,
      onPrimary: Colors.white,
      primaryContainer: sky,
      onPrimaryContainer: navy,
      secondary: navy,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xffDCEBFA),
      onSecondaryContainer: navy,
      tertiary: mintTeal,
      onTertiary: Colors.white,
      error: emergencyRed,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: text,
      surfaceContainerHighest: Color(0xffEEF2F7),
      onSurfaceVariant: textMuted,
      outline: border,
      outlineVariant: border,
      shadow: Color(0x1A0F172A),
      scrim: Color(0x990F172A),
      inverseSurface: navy,
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xff8DCDFF),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -.6,
        ),
        headlineSmall: TextStyle(
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -.4,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -.2,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.42, color: text),
        bodySmall: TextStyle(fontSize: 13, height: 1.4, color: textMuted),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: textMuted,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emergencyRed, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: sky,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: sky,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? blue : textMuted,
            size: 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected) ? navy : textMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          foregroundColor: navy,
          backgroundColor: Colors.white,
          side: const BorderSide(color: border, width: 1.2),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: buttonShape,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: deepNavy,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.all(16),
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: blue),
    );
  }
}
