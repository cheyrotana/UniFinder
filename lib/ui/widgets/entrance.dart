import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Fades its child in and lifts it a few pixels when it first appears,
/// [index] × 50 ms after its siblings (a staggered list entrance). Plays
/// once per element; reduce-motion skips it.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 16,
  });

  final Widget child;
  final int index;

  /// How far below it starts, in pixels.
  final double offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: AppMotion.emphasized,
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 50 * widget.index.clamp(0, 10));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
