import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/theme/app_motion.dart';

/// Page transitions for routes that differ from the theme's default
/// parallax slide (pushed screens need nothing).

/// A modal flow you leave with ✕ (the quiz): rises from the bottom while
/// the page underneath recedes slightly.
CustomTransitionPage<T> bottomSlidePage<T>({
  required LocalKey key,
  required Widget child,
}) => CustomTransitionPage<T>(
  key: key,
  child: child,
  fullscreenDialog: true,
  transitionDuration: const Duration(milliseconds: 420),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  transitionsBuilder: (context, animation, secondary, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  },
);

/// Splash → onboarding → home and the other "fresh start" hops: a fade
/// with a slight zoom in.
CustomTransitionPage<T> fadePage<T>({
  required LocalKey key,
  required Widget child,
}) => CustomTransitionPage<T>(
  key: key,
  child: child,
  transitionDuration: const Duration(milliseconds: 450),
  transitionsBuilder: (context, animation, _, child) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 1.04, end: 1.0).animate(curved),
        child: child,
      ),
    );
  },
);
