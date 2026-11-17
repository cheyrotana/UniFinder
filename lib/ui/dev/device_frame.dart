import 'package:flutter/material.dart';

import 'device_chrome.dart';
import 'device_preset.dart';

/// The app as [look]'s phone: its screen size and safe areas, its status
/// bar, cutout and system navigation drawn over it, and (with
/// [platform]) the phone's platform, so adaptive widgets (sheets, the nav
/// glass, page transitions) follow it.
///
/// [fill] uses the window's size instead (a narrow window, `?insets`).
/// Otherwise the phone is drawn at its size, scaled down when the window
/// is shorter, with rounded corners or a bezel.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    super.key,
    required this.look,
    required this.child,
    this.fill = false,
    this.platform = false,
    this.overlay,
  });

  final DeviceLook look;
  final Widget child;
  final bool fill;
  final bool platform;

  /// Drawn over the screen, inside its safe areas (the dev tools button).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = fill ? media.size : look.preset.size;
    final insets = look.insets;
    final theme = Theme.of(context);

    final Widget screen = MediaQuery(
      data: media.copyWith(size: size, padding: insets, viewPadding: insets),
      child: Theme(
        data: platform ? theme.copyWith(platform: look.preset.platform) : theme,
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Positioned.fill(child: DeviceChrome(look: look)),
            ?overlay,
          ],
        ),
      ),
    );
    if (fill) return screen;

    final radius = look.preset.radius;
    final display = SizedBox.fromSize(
      size: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: screen,
      ),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: look.bezel
              ? _Bezel(look: look, child: display)
              : DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: display,
                ),
        ),
      ),
    );
  }
}

/// A black body around the screen; the iPhone SE gets its chin and home
/// button.
class _Bezel extends StatelessWidget {
  const _Bezel({required this.look, required this.child});

  final DeviceLook look;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The iPhone SE's thick bezel; iPads have a slim one all round.
    final homeButton = look.preset.nav == DeviceNav.none && look.preset.isApple;
    final side = homeButton ? 18.0 : 12.0;
    final ends = homeButton ? 72.0 : 12.0;
    return Container(
      padding: EdgeInsets.fromLTRB(side, ends, side, ends),
      decoration: BoxDecoration(
        color: const Color(0xFF111316),
        borderRadius: BorderRadius.circular(
          homeButton ? 56 : look.preset.radius + 12,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 36,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (homeButton)
            Positioned(
              left: 0,
              right: 0,
              bottom: -60,
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3A3D42),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
