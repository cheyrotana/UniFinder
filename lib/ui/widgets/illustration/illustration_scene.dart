import 'dart:ui' show Rect;

/// One layer of a scene: a standalone SVG that draws only this layer, on
/// the scene's whole view box, so the layers stack back into the scene.
class IllustrationLayer {
  const IllustrationLayer({
    required this.name,
    required this.box,
    required this.svg,
  });

  /// The layer's id: `character`, `plant`, `speech-bubble`…
  final String name;

  /// Where the layer is drawn, in the scene's units.
  final Rect box;
  final String svg;
}

/// A scene from `tool/illustrations.py`, split into its top-level layers.
class IllustrationScene {
  const IllustrationScene({required this.viewBox, required this.layers});

  factory IllustrationScene.parse(String svg) {
    final open = RegExp(r'<svg\b[^>]*>').firstMatch(svg)!;
    final numbers = RegExp(
      r'viewBox="([^"]+)"',
    ).firstMatch(open.group(0)!)!.group(1)!.split(RegExp(r'[\s,]+'));
    final v = numbers.map(double.parse).toList();
    final viewBox = Rect.fromLTWH(v[0], v[1], v[2], v[3]);
    final defs = RegExp(r'<defs>.*?</defs>', dotAll: true).firstMatch(svg);
    final head = '${open.group(0)}${defs?.group(0) ?? ''}';

    final layers = <IllustrationLayer>[];
    var depth = 0;
    var start = 0;
    for (final tag in RegExp(r'<(/?)g\b[^>]*?(/?)>').allMatches(svg)) {
      if (tag.group(2)!.isNotEmpty) continue;
      if (tag.group(1)!.isEmpty) {
        if (depth++ == 0) start = tag.start;
      } else if (--depth == 0) {
        final g = svg.substring(start, tag.end);
        final opening = RegExp(r'^<g\b[^>]*>').firstMatch(g)!.group(0)!;
        final box = RegExp(r'data-box="([^"]+)"').firstMatch(opening);
        final b = box?.group(1)!.split(' ').map(double.parse).toList();
        layers.add(
          IllustrationLayer(
            name: RegExp(r'\bid="([^"]+)"').firstMatch(opening)?.group(1) ?? '',
            box: b == null ? viewBox : Rect.fromLTWH(b[0], b[1], b[2], b[3]),
            svg: '$head$g</svg>',
          ),
        );
      }
    }
    return IllustrationScene(viewBox: viewBox, layers: layers);
  }

  final Rect viewBox;
  final List<IllustrationLayer> layers;
}
