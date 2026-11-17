import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_preset.dart';

/// The dev tools' choices, kept in this device's preferences: the web
/// preview's phone and the sidebar's side. (Ported from PhumiYerng's dev
/// tools, without its mock/API data switch: UniFinder is offline.)
class DevToolsController extends ChangeNotifier {
  DevToolsController(this._prefs);

  final SharedPreferences _prefs;

  static const _kPreset = 'dev.frame.preset';
  static const _kCutout = 'dev.frame.cutout';
  static const _kNav = 'dev.frame.nav';
  static const _kStatusBar = 'dev.frame.status_bar';
  static const _kBezel = 'dev.frame.bezel';
  static const _kSidebarRight = 'dev.sidebar.right';
  static const _kSlowMotion = 'dev.slow_motion';

  // Device (web preview).

  DevicePreset get preset =>
      devicePresets.where((p) => p.id == _prefs.getString(_kPreset)).firstOrNull ??
      devicePresets.first;

  DeviceLook get look => DeviceLook(
    preset: preset,
    cutout:
        DeviceCutout.values.asNameMap()[_prefs.getString(_kCutout)] ??
        preset.cutout,
    nav: DeviceNav.values.asNameMap()[_prefs.getString(_kNav)] ?? preset.nav,
    statusBar: _prefs.getBool(_kStatusBar) ?? true,
    bezel: _prefs.getBool(_kBezel) ?? false,
  );

  /// Picking a phone resets the cutout and navigation to its own.
  Future<void> setPreset(DevicePreset value) => _set(() async {
    await _prefs.setString(_kPreset, value.id);
    await _prefs.remove(_kCutout);
    await _prefs.remove(_kNav);
  });

  Future<void> setCutout(DeviceCutout value) =>
      _set(() => _prefs.setString(_kCutout, value.name));

  Future<void> setNav(DeviceNav value) =>
      _set(() => _prefs.setString(_kNav, value.name));

  Future<void> setStatusBar(bool value) =>
      _set(() => _prefs.setBool(_kStatusBar, value));

  Future<void> setBezel(bool value) =>
      _set(() => _prefs.setBool(_kBezel, value));

  // Sidebar (web preview).

  /// Which edge of the window the sidebar sits on; dragged by its header.
  bool get sidebarRight => _prefs.getBool(_kSidebarRight) ?? false;

  Future<void> setSidebarRight(bool value) =>
      _set(() => _prefs.setBool(_kSidebarRight, value));

  // Animations.

  /// Slows every animation down 5× (`timeDilation`), to inspect the page
  /// and tab transitions.
  bool get slowMotion => _prefs.getBool(_kSlowMotion) ?? false;

  Future<void> setSlowMotion(bool value) => _set(() async {
    await _prefs.setBool(_kSlowMotion, value);
    applySlowMotion();
  });

  void applySlowMotion() => timeDilation = slowMotion ? 5.0 : 1.0;

  Future<void> _set(Future<void> Function() write) async {
    await write();
    notifyListeners();
  }
}
