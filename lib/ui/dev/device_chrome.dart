import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'device_preset.dart';

/// The phone's status bar, cutout and system navigation, drawn over the
/// app in the web preview. Nothing here takes taps.
class DeviceChrome extends StatelessWidget {
  const DeviceChrome({super.key, required this.look});

  final DeviceLook look;

  @override
  Widget build(BuildContext context) {
    final preset = look.preset;
    final ink = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return IgnorePointer(
      // A plain text style: no Material above here, so Text would get the
      // yellow "missing Material" underline.
      child: DefaultTextStyle(
        style: TextStyle(
          color: ink,
          fontSize: preset.isApple ? 16 : 14,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
        child: Stack(
          children: [
            if (look.statusBar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: preset.statusBar,
                child: _StatusBar(look: look, ink: ink),
              ),
            _Cutout(look: look),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: math.max(look.navInset, 1),
              child: _SystemNav(nav: look.nav, ink: ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// The time (the real one, ticking) and the signal, Wi-Fi and battery
/// glyphs, laid out the iPhone or Android way.
class _StatusBar extends StatefulWidget {
  const _StatusBar({required this.look, required this.ink});

  final DeviceLook look;
  final Color ink;

  @override
  State<_StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<_StatusBar> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  String get _time {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    return '$hour:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look;
    final ink = widget.ink;
    final icons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.signal_cellular_alt_rounded, size: 17, color: ink),
        const SizedBox(width: 4),
        Icon(Icons.wifi_rounded, size: 17, color: ink),
        const SizedBox(width: 4),
        Icon(
          look.preset.isApple
              ? Icons.battery_full_rounded
              : Icons.battery_5_bar_rounded,
          size: 19,
          color: ink,
        ),
      ],
    );
    final time = Text(_time);

    if (!look.preset.isApple) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [time, const Spacer(), icons]),
      );
    }
    if (look.cutout == DeviceCutout.none) {
      // iPhone SE: a thin bar, the time in the middle.
      return DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(Icons.signal_cellular_alt_rounded, size: 13, color: ink),
              const Spacer(),
              time,
              const Spacer(),
              Icon(Icons.battery_full_rounded, size: 15, color: ink),
            ],
          ),
        ),
      );
    }
    // Time and glyphs centred in the "ears" either side of the cutout.
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(child: Center(child: time)),
          SizedBox(width: look.cutout == DeviceCutout.notch ? 162 : 126),
          Expanded(child: Center(child: icons)),
        ],
      ),
    );
  }
}

class _Cutout extends StatelessWidget {
  const _Cutout({required this.look});

  final DeviceLook look;

  @override
  Widget build(BuildContext context) {
    final bar = look.preset.statusBar;
    return switch (look.cutout) {
      DeviceCutout.none => const SizedBox.shrink(),
      DeviceCutout.island => Positioned(
        top: 11,
        left: 0,
        right: 0,
        child: Center(child: _black(126, 37, BorderRadius.circular(19))),
      ),
      DeviceCutout.notch => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Center(
          child: _black(
            162,
            32,
            const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
      ),
      DeviceCutout.punchHole => Positioned(
        top: (bar - 20) / 2,
        left: 0,
        right: 0,
        child: Center(child: _black(20, 20, BorderRadius.circular(10))),
      ),
    };
  }

  static Widget _black(double w, double h, BorderRadius radius) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: Colors.black, borderRadius: radius),
  );
}

class _SystemNav extends StatelessWidget {
  const _SystemNav({required this.nav, required this.ink});

  final DeviceNav nav;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return switch (nav) {
      DeviceNav.homeIndicator => _pill(140, 5, bottom: 8),
      DeviceNav.gestureBar => _pill(108, 4, bottom: 10),
      DeviceNav.threeButton => ColoredBox(
        // Edge-to-edge Android draws a light scrim behind the buttons.
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        child: CustomPaint(painter: _ThreeButtonPainter(ink)),
      ),
      DeviceNav.none => const SizedBox.shrink(),
    };
  }

  Widget _pill(double w, double h, {required double bottom}) => Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(h),
        ),
      ),
    ),
  );
}

/// ◁ ○ □, evenly spaced.
class _ThreeButtonPainter extends CustomPainter {
  _ThreeButtonPainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    final y = size.height / 2;
    final step = size.width / 4;
    const r = 8.0;
    final back = Offset(step, y);
    canvas.drawPath(
      Path()
        ..moveTo(back.dx - r, back.dy)
        ..lineTo(back.dx + r * 0.7, back.dy - r)
        ..lineTo(back.dx + r * 0.7, back.dy + r)
        ..close(),
      paint,
    );
    canvas.drawCircle(Offset(step * 2, y), r, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(step * 3, y), width: 15, height: 15),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ThreeButtonPainter old) => old.ink != ink;
}
