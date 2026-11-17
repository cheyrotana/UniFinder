import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// One tab of an [AppNavBar].
class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The floating "liquid glass" capsule from PhumiYerng: blur and a little
/// extra saturation over the content behind it, a bright rim, and a lens
/// that slides (with a small overshoot) behind the current tab. The current
/// tab's icon swaps to its filled form and its label grows in.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _height = 64.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final colors = context.colors;
    final dark = context.isDark;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        bottom > 0 ? bottom : AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.45 : 0.10),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_height / 2),
          child: BackdropFilter(
            filter: ImageFilter.compose(
              outer: const ColorFilter.matrix(_saturate),
              inner: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            ),
            child: CustomPaint(
              foregroundPainter: _RimPainter(dark: dark),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.glassBar.withValues(alpha: dark ? 0.72 : 0.78),
                      colors.glassBar.withValues(alpha: dark ? 0.58 : 0.66),
                    ],
                  ),
                ),
                child: SizedBox(
                  height: _height,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final slot = constraints.maxWidth / items.length;
                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutBack,
                            left: slot * currentIndex + 6,
                            width: slot - 12,
                            top: 6,
                            bottom: 6,
                            child: _Lens(dark: dark),
                          ),
                          Row(
                            children: [
                              for (final (i, item) in items.indexed)
                                Expanded(
                                  child: _NavTab(
                                    item: item,
                                    selected: i == currentIndex,
                                    onTap: () => onSelected(i),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Saturation 1.4.
  static const _saturate = <double>[
    1.2864, -0.2576, -0.0288, 0, 0, //
    -0.0856, 1.1424, -0.0568, 0, 0, //
    -0.0856, -0.2576, 1.3432, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

/// The brighter drop of tinted glass behind the current tab.
class _Lens extends StatelessWidget {
  const _Lens({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final primary = context.scheme.primary;
    return CustomPaint(
      foregroundPainter: _RimPainter(dark: dark, strength: 0.6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: primary.withValues(alpha: dark ? 0.22 : 0.11),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.scheme.primary : context.colors.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  key: ValueKey(selected),
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: context.text.labelSmall!.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// A light rim along the top edge and a faint one along the bottom: glass
/// catching the light.
class _RimPainter extends CustomPainter {
  _RimPainter({required this.dark, this.strength = 1});

  final bool dark;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      Radius.circular(size.height / 2),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: (dark ? 0.22 : 0.9) * strength),
          Colors.white.withValues(alpha: (dark ? 0.04 : 0.25) * strength),
          Colors.white.withValues(alpha: (dark ? 0.10 : 0.5) * strength),
        ],
        stops: const [0, 0.55, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect, paint);
    if (!dark) {
      canvas.drawRRect(
        rrect.inflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = Colors.black.withValues(alpha: 0.06 * strength),
      );
    }
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.dark != dark || old.strength != strength;
}
