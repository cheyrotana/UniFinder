import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App preferences kept on this device: theme and text size. Shared by the
/// Profile screen and the dev tools; read with [AppSettings.of].
class SettingsController extends ChangeNotifier {
  SettingsController(this.prefs);

  final SharedPreferences prefs;

  static const _kTheme = 'settings.theme_mode';
  static const _kTextScale = 'settings.text_scale';

  static const textScales = [0.9, 1.0, 1.15, 1.3];

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[prefs.getString(_kTheme)] ??
      ThemeMode.light;

  Future<void> setThemeMode(ThemeMode mode) async {
    await prefs.setString(_kTheme, mode.name);
    notifyListeners();
  }

  double get textScale => prefs.getDouble(_kTextScale) ?? 1.0;

  Future<void> setTextScale(double scale) async {
    await prefs.setDouble(_kTextScale, scale);
    notifyListeners();
  }
}

/// Puts the [SettingsController] above the app.
class AppSettings extends InheritedNotifier<SettingsController> {
  const AppSettings({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Rebuilds the caller when a setting changes.
  static SettingsController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppSettings>()!
      .notifier!;

  /// Without listening.
  static SettingsController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppSettings>()!.notifier!;
}
