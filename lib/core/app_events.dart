import 'package:flutter/foundation.dart';

/// Signals between screens that outlive each other (tabs keep their state):
/// bump after changing the data, listen to reload.
abstract final class AppEvents {
  /// A dream was saved or deleted, or the user changed.
  static final dataChanged = ValueNotifier<int>(0);

  static void notifyDataChanged() => dataChanged.value++;
}
