import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The dev tools' floating button: drag it anywhere, it settles against
/// the nearer side; tap it to open the tools. Fills its parent (a
/// `Positioned.fill`) but only the button takes touches.
class DevToolsBubble extends StatefulWidget {
  const DevToolsBubble({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<DevToolsBubble> createState() => _DevToolsBubbleState();
}

class _DevToolsBubbleState extends State<DevToolsBubble> {
  static const _size = 44.0;
  static const _margin = 8.0;

  /// Where the button is, as a fraction of the free space (0–1 each way).
  Offset _at = const Offset(1, 0.62);
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = safe.left + _margin;
        final top = safe.top + _margin;
        final freeW =
            constraints.maxWidth - left - safe.right - _margin - _size;
        final freeH =
            constraints.maxHeight - top - safe.bottom - _margin - _size;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: left + freeW * _at.dx,
              top: top + freeH * _at.dy,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _dragging = true),
                onPanUpdate: (d) => setState(() {
                  _at = Offset(
                    (_at.dx + d.delta.dx / freeW).clamp(0, 1),
                    (_at.dy + d.delta.dy / freeH).clamp(0, 1),
                  );
                }),
                onPanEnd: (_) => setState(() {
                  _dragging = false;
                  _at = Offset(_at.dx < 0.5 ? 0 : 1, _at.dy);
                }),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.72),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onTap();
                    },
                    child: const SizedBox.square(
                      dimension: _size,
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
