import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static const fontFamily = 'Pretendard';

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.brand,
          brightness: brightness,
        ).copyWith(
          primary: p.brand,
          onPrimary: p.onBrand,
          primaryContainer: p.brandSubtle,
          onPrimaryContainer: p.brandPressed,
          secondary: p.brand,
          onSecondary: p.onBrand,
          surface: p.surface,
          onSurface: p.text1,
          onSurfaceVariant: p.text2,
          surfaceContainerLowest: p.surface,
          surfaceContainerLow: p.surface,
          surfaceContainer: p.surface,
          surfaceContainerHigh: p.surfaceAlt,
          surfaceContainerHighest: p.surfaceAlt,
          outline: p.border,
          outlineVariant: p.border,
          error: p.over,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: p.bg,
      extensions: [p],
    );

    final textTheme = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: p.text1,
      displayColor: p.text1,
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.text1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title2.copyWith(
          color: p.text1,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          disabledBackgroundColor: p.surfaceAlt,
          disabledForegroundColor: p.text3,
          minimumSize: const Size.fromHeight(56),
          shape: controlShape,
          textStyle: AppText.label.copyWith(
            fontSize: 16,
            fontFamily: fontFamily,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text1,
          side: BorderSide(color: p.border),
          minimumSize: const Size.fromHeight(56),
          shape: controlShape,
          textStyle: AppText.label.copyWith(
            fontSize: 16,
            fontFamily: fontFamily,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.brand),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: p.brand, width: 1.5),
        ),
        hintStyle: TextStyle(color: p.text3),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.text1,
        contentTextStyle: AppText.body.copyWith(
          color: p.bg,
          fontFamily: fontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.brandSubtle,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? p.brand : p.text3,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppText.micro.copyWith(
            fontFamily: fontFamily,
            color: s.contains(WidgetState.selected) ? p.text1 : p.text3,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.brand,
        thumbColor: p.brand,
        inactiveTrackColor: p.border,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.brand),
      listTileTheme: ListTileThemeData(
        iconColor: p.text2,
        titleTextStyle: AppText.body.copyWith(
          color: p.text1,
          fontFamily: fontFamily,
        ),
        subtitleTextStyle: AppText.caption.copyWith(
          color: p.text2,
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}
