import 'package:flutter/widgets.dart';

/// Every duration and curve in the app (shared with PhumiYerng / HRM).
abstract final class AppMotion {
  /// Cross-fades, chip select, press feedback.
  static const short = Duration(milliseconds: 150);

  /// Expand/collapse, tab switch, state change.
  static const medium = Duration(milliseconds: 250);

  /// Route transitions.
  static const page = Duration(milliseconds: 320);

  /// Material 3 "emphasized" (HRM's page curve).
  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const standard = Curves.easeOutCubic;
}

extension MotionContext on BuildContext {
  /// [duration], or zero when the OS asks to reduce motion.
  Duration motion(Duration duration) =>
      MediaQuery.disableAnimationsOf(this) ? Duration.zero : duration;
}
