import 'package:flutter/material.dart';

/// Rebuilds the whole app from scratch (a fresh router back at the splash,
/// every screen's state gone). The dev tools' Restart and the data resets
/// use it through [AppRestart.of].
class AppRestartScope extends StatefulWidget {
  const AppRestartScope({super.key, required this.builder});

  /// Builds the app; called again (with a new key) on each restart.
  final Widget Function(BuildContext context, Key key) builder;

  @override
  State<AppRestartScope> createState() => _AppRestartScopeState();
}

class _AppRestartScopeState extends State<AppRestartScope> {
  var _generation = 0;

  void _restart() => setState(() => _generation++);

  @override
  Widget build(BuildContext context) => AppRestart._(
    restart: _restart,
    child: widget.builder(context, ValueKey(_generation)),
  );
}

class AppRestart extends InheritedWidget {
  const AppRestart._({required this.restart, required super.child});

  final VoidCallback restart;

  static AppRestart of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppRestart>()!;

  @override
  bool updateShouldNotify(AppRestart old) => false;
}
