import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'illustration_palette.dart';
import 'illustration_scene.dart';

/// Loads, themes and splits Storyset scenes once per asset, accent colour
/// and brightness, shared by every screen: a tile's still picture and the
/// detail header's animated scene read the same entry, so the header is
/// ready on its first frame (the hero flight needs that).
abstract final class IllustrationCache {
  static final _themed = <String, String>{};
  static final _loading = <String, Future<String>>{};
  static final _scenes = <String, IllustrationScene>{};

  static String keyOf(BuildContext context, String asset, Color accent) =>
      '$asset|${accent.toARGB32()}|${Theme.of(context).brightness.name}';

  /// The themed SVG, if it's already loaded.
  static String? themedNow(String key) => _themed[key];

  /// The scene split into layers, if its SVG is already loaded.
  static IllustrationScene? sceneNow(String key) {
    final svg = _themed[key];
    if (svg == null) return null;
    return _scenes[key] ??= IllustrationScene.parse(svg);
  }

  static Future<String> themed(
    BuildContext context,
    String asset,
    Color accent,
  ) {
    final key = keyOf(context, asset, accent);
    if (_themed[key] case final svg?) return Future.value(svg);
    final brightness = Theme.of(context).brightness;
    final colors = context.colors;
    final bundle = DefaultAssetBundle.of(context);
    return _loading[key] ??= bundle.loadString(asset).then((raw) {
      final svg = themeIllustration(
        raw,
        accent: accent,
        brightness: brightness,
        paper: colors.field,
        ink: colors.ink,
      );
      _themed[key] = svg;
      _loading.remove(key);
      return svg;
    });
  }
}
