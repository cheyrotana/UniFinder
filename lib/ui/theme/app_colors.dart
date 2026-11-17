import 'package:flutter/material.dart';

/// Colour tokens that `ColorScheme` has no slot for. Read them with
/// `context.colors.muted`, never with hex values in widgets.
///
/// Brand: the logo's blue (#2563EB) and slate navy ink, on HRM-style white
/// surfaces with slate hairlines; a matching slate dark mode.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ink,
    required this.muted,
    required this.subtle,
    required this.canvas,
    required this.card,
    required this.field,
    required this.hairline,
    required this.brandSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.glassBar,
    required this.scrim,
    required this.skeleton,
  });

  /// Titles and headlines.
  final Color ink;

  /// Meta lines, placeholders, inactive icons.
  final Color muted;

  /// Disabled text, tertiary meta.
  final Color subtle;

  /// Behind cards (the scaffold).
  final Color canvas;

  /// Cards and sheets.
  final Color card;

  /// Filled inputs, unselected chips, segmented controls.
  final Color field;
  final Color hairline;

  /// A pale tint of the primary: selected chips, icon tiles.
  final Color brandSoft;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;

  /// The floating nav bar's glass.
  final Color glassBar;

  /// Behind modals and over photos.
  final Color scrim;
  final Color skeleton;

  static const light = AppColors(
    ink: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    subtle: Color(0xFF94A3B8),
    canvas: Color(0xFFF5F7FB),
    card: Color(0xFFFFFFFF),
    field: Color(0xFFF1F5F9),
    hairline: Color(0xFFE2E8F0),
    brandSoft: Color(0xFFE8EFFE),
    success: Color(0xFF16A34A),
    successSoft: Color(0xFFDCFCE7),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0xFFFEF3C7),
    danger: Color(0xFFDC2626),
    dangerSoft: Color(0xFFFEE2E2),
    glassBar: Color(0xFFFFFFFF),
    scrim: Color(0x990F172A),
    skeleton: Color(0xFFE9EEF5),
  );

  static const dark = AppColors(
    ink: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    subtle: Color(0xFF64748B),
    canvas: Color(0xFF0B1120),
    card: Color(0xFF131B2E),
    field: Color(0xFF1C2639),
    hairline: Color(0xFF26324A),
    brandSoft: Color(0xFF1A2A4D),
    success: Color(0xFF4ADE80),
    successSoft: Color(0xFF14321F),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF3A2D0C),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF3B1517),
    glassBar: Color(0xFF1A2335),
    scrim: Color(0xB3000000),
    skeleton: Color(0xFF1C2639),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      subtle: l(subtle, other.subtle),
      canvas: l(canvas, other.canvas),
      card: l(card, other.card),
      field: l(field, other.field),
      hairline: l(hairline, other.hairline),
      brandSoft: l(brandSoft, other.brandSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      glassBar: l(glassBar, other.glassBar),
      scrim: l(scrim, other.scrim),
      skeleton: l(skeleton, other.skeleton),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
