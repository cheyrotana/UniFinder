import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_restart.dart';
import '../core/env.dart';
import '../core/settings_controller.dart';
import '../routers/app_router.dart';
import 'dev/dev_tools.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, required this.prefs, required this.settings});

  final SharedPreferences prefs;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AppSettings(
      controller: settings,
      child: AppRestartScope(
        builder: (context, key) => _RouterApp(key: key, prefs: prefs),
      ),
    );
  }
}

/// Lets a mouse or trackpad drag lists too (Flutter only drags with touch
/// by default), so horizontal strips scroll on web and desktop.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}

/// The MaterialApp with its own router; a restart builds a new one (back
/// at the splash).
class _RouterApp extends StatefulWidget {
  const _RouterApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends State<_RouterApp> {
  late final GoRouter _router = AppRouter.create();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    return MaterialApp.router(
      title: 'UniFinder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      scaffoldMessengerKey: AppRouter.messengerKey,
      scrollBehavior: const _AppScrollBehavior(),
      routerConfig: _router,
      builder: (context, child) => DevTools(
        enabled: Env.devTools,
        prefs: widget.prefs,
        // Read below the dev tools' device frame, which swaps in the
        // phone's size and safe areas.
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(settings.textScale)),
            child: child!,
          ),
        ),
      ),
    );
  }
}
