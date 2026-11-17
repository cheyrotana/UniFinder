import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Pushed screens slide in from the right on the emphasized curve while the
/// screen underneath drifts a third of the way left and dims (parallax),
/// the way iOS and HRM do it. Set once in `pageTransitionsTheme`, so every
/// route gets it on Android, web and desktop; iOS keeps Cupertino with its
/// interactive swipe-back. A fling from the left edge goes back.
class ParallaxSlideTransitionsBuilder extends PageTransitionsBuilder {
  const ParallaxSlideTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(-0.3, 0),
      ).animate(outgoing),
      child: _Dim(
        animation: outgoing,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(incoming),
          child: DecoratedBox(
            // A soft edge shadow so the new page reads as "on top".
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 16,
                ),
              ],
            ),
            child: route.isFirst || route.fullscreenDialog
                ? child
                : _EdgeSwipeToPop(route: route, child: child),
          ),
        ),
      ),
    );
  }
}

/// Darkens the page underneath while another covers it.
class _Dim extends AnimatedWidget {
  const _Dim({required Animation<double> animation, required this.child})
    : super(listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    if (t == 0) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.12 * t)),
          ),
        ),
      ],
    );
  }
}

/// A strip on the left edge: a rightward fling pops the route (through
/// `maybePop`, so `PopScope` guards still ask first).
class _EdgeSwipeToPop extends StatelessWidget {
  const _EdgeSwipeToPop({required this.route, required this.child});

  final PageRoute<Object?> route;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: 24,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 250 && route.isCurrent) {
                route.navigator?.maybePop();
              }
            },
          ),
        ),
      ],
    );
  }
}
