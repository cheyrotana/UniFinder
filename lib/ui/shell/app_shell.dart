import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_motion.dart';
import 'app_nav_bar.dart';

/// The three tabs under the floating nav bar. Content scrolls under the
/// glass (`extendBody`), and gets the bar's height in
/// `MediaQuery.padding.bottom`.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = [
    AppNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    AppNavItem(
      label: 'Explore',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
    ),
    AppNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  void _onSelected(int index) {
    if (index != shell.currentIndex) HapticFeedback.selectionClick();
    // Tapping the current tab again goes back to its first screen.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: AppNavBar(
        items: _items,
        currentIndex: shell.currentIndex,
        onSelected: _onSelected,
      ),
    );
  }
}

/// Switches tabs with a fade-through: the old tab fades out while the new
/// one fades in and rises a few pixels. Hidden tabs keep their state but
/// stop ticking, take no touches, and their heroes sit out (so two tabs
/// showing the same photo never clash).
class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final duration = context.motion(const Duration(milliseconds: 280));
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, child) in children.indexed)
          _Branch(
            active: i == currentIndex,
            duration: duration,
            child: child,
          ),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({
    required this.active,
    required this.duration,
    required this.child,
  });

  final bool active;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The fade runs outside TickerMode: muting the tab's tickers must not
    // freeze its own fade-out halfway (it would stay on top of the new tab).
    return IgnorePointer(
      ignoring: !active,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: duration,
        curve: active
            ? const Interval(0.25, 1, curve: Curves.easeOut)
            : const Interval(0, 0.6, curve: Curves.easeIn),
        child: AnimatedSlide(
          offset: active ? Offset.zero : const Offset(0, 0.015),
          duration: duration,
          curve: AppMotion.emphasized,
          child: AnimatedScale(
            scale: active ? 1 : 0.985,
            duration: duration,
            curve: AppMotion.emphasized,
            child: TickerMode(
              enabled: active,
              child: HeroMode(enabled: active, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
