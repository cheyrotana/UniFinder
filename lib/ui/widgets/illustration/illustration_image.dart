import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'illustration_cache.dart';

/// A Storyset scene as one still picture, in the theme's colours with its
/// accent in [accent] (cards and thumbnails; `AppIllustration` animates).
/// Fades in once loaded.
class IllustrationImage extends StatefulWidget {
  const IllustrationImage(
    this.asset, {
    super.key,
    required this.accent,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final Color accent;
  final BoxFit fit;

  @override
  State<IllustrationImage> createState() => _IllustrationImageState();
}

class _IllustrationImageState extends State<IllustrationImage> {
  String? _svg;
  String? _key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(IllustrationImage old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset || old.accent != widget.accent) _load();
  }

  void _load() {
    final key = IllustrationCache.keyOf(context, widget.asset, widget.accent);
    if (key == _key) return;
    _key = key;
    final now = IllustrationCache.themedNow(key);
    if (now != null) {
      _svg = now;
      return;
    }
    IllustrationCache.themed(context, widget.asset, widget.accent).then((svg) {
      if (mounted && _key == key) setState(() => _svg = svg);
    });
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svg;
    return AnimatedOpacity(
      opacity: svg == null ? 0 : 1,
      duration: const Duration(milliseconds: 250),
      child: svg == null
          ? const SizedBox.expand()
          : SvgPicture.string(
              svg,
              fit: widget.fit,
              excludeFromSemantics: true,
            ),
    );
  }
}
