import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'illustration_motion.dart';
import 'illustration_cache.dart';
import 'illustration_scene.dart';

/// A Storyset scene (`AppAssets` illustrations) in the theme's colours,
/// alive: its pieces rise in one after another, then people breathe, plants
/// sway, bubbles drift, lamps swing, clearly enough to see at a glance.
///
/// The SVGs come from `tool/illustrations.py`: their coral accent becomes
/// the theme's primary (or [accent]) and, on a dark theme, their greys turn
/// round. Each top-level layer moves by its name (`motionFor`). With
/// reduced motion on, the scene stands still.
class AppIllustration extends StatefulWidget {
  const AppIllustration(
    this.asset, {
    super.key,
    required this.height,
    this.accent,
    this.intro = true,
  });

  /// Play the entrance (layers rise in). Off for a scene that lands from a
  /// hero flight already whole.
  final bool intro;

  final String asset;
  final double height;

  /// The colour the scene's accent takes; the theme's primary by default.
  final Color? accent;

  /// Whether scenes keep idling after their entrance. Widget tests turn it
  /// off (test/flutter_test_config.dart) so `pumpAndSettle` can settle.
  static bool idle = true;

  @override
  State<AppIllustration> createState() => _AppIllustrationState();
}

class _AppIllustrationState extends State<AppIllustration>
    with TickerProviderStateMixin {
  /// The entrance, once: every layer rises in, staggered (and the success
  /// badge pops, its check draws).
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  /// The idle motion, round and round.
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  IllustrationScene? _scene;
  String? _key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(AppIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset || oldWidget.accent != widget.accent) {
      _load();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _load() {
    final accent = widget.accent ?? Theme.of(context).colorScheme.primary;
    final key = IllustrationCache.keyOf(context, widget.asset, accent);
    if (key == _key) return _animate();
    _key = key;
    final ready = IllustrationCache.sceneNow(key);
    if (ready != null) {
      _scene = ready;
      return _animate(fromStart: true);
    }
    IllustrationCache.themed(context, widget.asset, accent).then((_) {
      if (!mounted || _key != key) return;
      setState(() => _scene = IllustrationCache.sceneNow(key));
      _animate(fromStart: true);
    });
  }

  void _animate({bool fromStart = false}) {
    final scene = _scene;
    if (scene == null) return;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still || !widget.intro) {
      _intro.value = 1;
    } else if (fromStart) {
      _intro.forward(from: 0);
    }
    if (still || !AppIllustration.idle) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    if (scene == null) return SizedBox(height: widget.height);
    final view = scene.viewBox;
    final scale = widget.height / view.height;
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: view.width * scale,
          height: widget.height,
          child: Stack(
            children: [
              for (final (i, layer) in scene.layers.indexed)
                Positioned.fill(
                  child: _Layer(
                    layer: layer,
                    index: i,
                    // The layer's box in this widget's pixels.
                    box: Rect.fromLTRB(
                      (layer.box.left - view.left) * scale,
                      (layer.box.top - view.top) * scale,
                      (layer.box.right - view.left) * scale,
                      (layer.box.bottom - view.top) * scale,
                    ),
                    scale: scale,
                    count: scene.layers.length,
                    intro: _intro,
                    loop: _loop,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Layer extends StatelessWidget {
  const _Layer({
    required this.layer,
    required this.index,
    required this.box,
    required this.scale,
    required this.count,
    required this.intro,
    required this.loop,
  });

  final IllustrationLayer layer;
  final int index;
  final Rect box;
  final double scale;
  final int count;
  final Animation<double> intro;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final picture = RepaintBoundary(
      child: SvgPicture.string(
        layer.svg,
        fit: BoxFit.fill,
        excludeFromSemantics: true,
      ),
    );
    final motion = motionFor(layer.name);
    return AnimatedBuilder(
      // Still layers only move while they enter.
      animation: motion == IllustrationMotion.still
          ? intro
          : Listenable.merge([intro, loop]),
      child: picture,
      builder: (context, child) => _enter(_move(motion, child!)),
    );
  }

  /// Each layer rises and fades in a little after the one under it, so the
  /// scene builds up rather than just appearing. Entrances of their own
  /// (pop, burst, draw) keep theirs.
  Widget _enter(Widget child) {
    final t = intro.value;
    if (t >= 1) return child;
    final start = count < 2 ? 0.0 : 0.45 * index / (count - 1);
    final u = _part(t, start, start + 0.55);
    if (u >= 1) return child;
    final rise = Curves.easeOutCubic.transform(u);
    return Opacity(
      opacity: Curves.easeOut.transform(u),
      child: Transform.translate(
        offset: Offset(0, (1 - rise) * 28 * scale),
        child: _scaled(0.9 + 0.1 * Curves.easeOutBack.transform(u), child),
      ),
    );
  }

  Widget _move(IllustrationMotion motion, Widget child) {
    // Layers move out of step with each other.
    final phase = loop.value * 2 * math.pi + index * 1.3;
    final t = intro.value;
    switch (motion) {
      case IllustrationMotion.still:
        return child;
      case IllustrationMotion.bob:
        // Breathing: up and down, and a little taller on the in-breath.
        final breath = math.sin(phase);
        return Transform.translate(
          offset: Offset(0, breath * 7 * scale),
          child: Transform(
            transform: Matrix4.diagonal3Values(1, 1 + 0.018 * breath, 1),
            origin: box.bottomCenter,
            child: child,
          ),
        );
      case IllustrationMotion.float:
        return Transform.translate(
          offset: Offset(
            math.cos(phase) * 4 * scale,
            math.sin(2 * phase) * 16 * scale,
          ),
          child: Transform.rotate(angle: math.sin(phase) * 0.04, child: child),
        );
      case IllustrationMotion.sway:
        return Transform(
          transform: Matrix4.rotationZ(math.sin(phase) * 0.09),
          origin: box.bottomCenter,
          child: child,
        );
      case IllustrationMotion.swing:
        return Transform(
          transform: Matrix4.rotationZ(math.sin(phase) * 0.14),
          origin: box.topCenter,
          child: child,
        );
      case IllustrationMotion.pulse:
        final s =
            Curves.easeOut.transform(t) * (1 + 0.12 * math.sin(2 * phase));
        return _scaled(s, child);
      case IllustrationMotion.pop:
        final s = Curves.easeOutBack.transform(_part(t, 0, 0.55));
        return _scaled(s, child);
      case IllustrationMotion.burst:
        final u = Curves.easeOut.transform(_part(t, 0.25, 0.9));
        return Opacity(opacity: u, child: _scaled(0.6 + 0.4 * u, child));
      case IllustrationMotion.draw:
        final u = Curves.easeInOut.transform(_part(t, 0.45, 1));
        // Past the box by the stroke's round caps.
        return ClipRect(
          clipper: _Reveal(box.inflate(8 * scale), u),
          child: child,
        );
    }
  }

  Widget _scaled(double s, Widget child) => Transform(
    transform: Matrix4.diagonal3Values(s, s, 1),
    origin: box.center,
    child: child,
  );

  static double _part(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);
}

/// Shows the part of the layer left of [progress] across its [box].
class _Reveal extends CustomClipper<Rect> {
  const _Reveal(this.box, this.progress);

  final Rect box;
  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, box.left + box.width * progress, size.height);

  @override
  bool shouldReclip(_Reveal old) => old.progress != progress || old.box != box;
}
