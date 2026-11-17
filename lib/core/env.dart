import 'package:flutter/foundation.dart';

/// Build-time switches (`--dart-define`).
abstract final class Env {
  /// The dev tools: the device preview on web, the floating tools button on
  /// phones. On by default in debug builds; `--dart-define=DEV_TOOLS=false`
  /// turns them off, `=true` forces them on in profile/release.
  static const bool devTools = bool.fromEnvironment(
    'DEV_TOOLS',
    defaultValue: kDebugMode,
  );
}
