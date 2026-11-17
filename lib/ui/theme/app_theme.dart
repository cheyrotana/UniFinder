import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'page_transitions.dart';

abstract final class AppTheme {
  static const brand = Color(0xFF2563EB);
  static const brandDark = Color(0xFF5B8DEF);

  static ThemeData light() => _build(
    brightness: Brightness.light,
    colors: AppColors.light,
    scheme: ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: brand,
      onPrimary: Colors.white,
      primaryContainer: AppColors.light.brandSoft,
      onPrimaryContainer: const Color(0xFF1E3A8A),
      secondary: const Color(0xFF334155),
      surface: AppColors.light.card,
      onSurface: AppColors.light.ink,
      onSurfaceVariant: AppColors.light.muted,
      outline: AppColors.light.hairline,
      outlineVariant: AppColors.light.hairline,
      error: AppColors.light.danger,
    ),
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    colors: AppColors.dark,
    scheme: ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
    ).copyWith(
      primary: brandDark,
      onPrimary: Colors.white,
      primaryContainer: AppColors.dark.brandSoft,
      onPrimaryContainer: const Color(0xFFC7D7FE),
      secondary: const Color(0xFFCBD5E1),
      surface: AppColors.dark.card,
      onSurface: AppColors.dark.ink,
      onSurfaceVariant: AppColors.dark.muted,
      outline: AppColors.dark.hairline,
      outlineVariant: AppColors.dark.hairline,
      error: AppColors.dark.danger,
    ),
  );

  static TextTheme _text(Color ink, Color muted) {
    TextStyle s(double size, FontWeight w, {double? ls, double h = 1.3}) =>
        TextStyle(
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: h,
          color: ink,
        );
    return TextTheme(
      displaySmall: s(34, FontWeight.w800, ls: -1.0, h: 1.1),
      headlineMedium: s(28, FontWeight.w800, ls: -0.8, h: 1.15),
      headlineSmall: s(24, FontWeight.w700, ls: -0.5, h: 1.2),
      titleLarge: s(20, FontWeight.w700, ls: -0.3),
      titleMedium: s(17, FontWeight.w600, ls: -0.2),
      titleSmall: s(15, FontWeight.w600, ls: -0.1),
      bodyLarge: s(16, FontWeight.w400, h: 1.5),
      bodyMedium: s(14, FontWeight.w400, h: 1.5),
      bodySmall: s(12.5, FontWeight.w400, h: 1.4).copyWith(color: muted),
      labelLarge: s(15, FontWeight.w600, ls: 0.1),
      labelMedium: s(13, FontWeight.w600, ls: 0.1),
      labelSmall: s(11.5, FontWeight.w600, ls: 0.2),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required AppColors colors,
  }) {
    final text = _text(colors.ink, colors.muted);
    final isLight = brightness == Brightness.light;
    const pill = StadiumBorder();
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      textTheme: text,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      extensions: [colors],
      // No ripples: presses are a slight colour change (PhumiYerng).
      splashFactory: NoSplash.splashFactory,
      highlightColor: scheme.primary.withValues(alpha: 0.06),
      hoverColor: scheme.primary.withValues(alpha: 0.04),
      dividerTheme: DividerThemeData(
        color: colors.hairline,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ParallaxSlideTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: ParallaxSlideTransitionsBuilder(),
          TargetPlatform.windows: ParallaxSlideTransitionsBuilder(),
          TargetPlatform.linux: ParallaxSlideTransitionsBuilder(),
          TargetPlatform.fuchsia: ParallaxSlideTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
        iconTheme: IconThemeData(color: colors.ink),
        systemOverlayStyle:
            (isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
                .copyWith(statusBarColor: Colors.transparent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: pill,
          textStyle: text.labelLarge,
          disabledBackgroundColor: colors.field,
          disabledForegroundColor: colors.subtle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: pill,
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.hairline, width: 1.5),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: pill,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.field,
        hintStyle: text.bodyMedium!.copyWith(color: colors.subtle),
        prefixIconColor: colors.muted,
        suffixIconColor: colors.muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 15,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.field,
        selectedColor: scheme.primary,
        side: BorderSide.none,
        shape: pill,
        labelStyle: text.labelMedium,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: colors.scrim,
        showDragHandle: true,
        dragHandleColor: colors.hairline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? colors.ink : colors.field,
        contentTextStyle: text.bodyMedium!.copyWith(
          color: isLight ? Colors.white : colors.ink,
        ),
        actionTextColor: isLight ? const Color(0xFF93B4FF) : scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: colors.field,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(primaryColor: scheme.primary),
    );
  }
}
