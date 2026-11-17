import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routers/app_router.dart';
import '../theme/app_motion.dart';
import 'dev_tools_bubble.dart';
import 'dev_tools_controller.dart';
import 'dev_tools_panel.dart';
import 'dev_tools_sidebar.dart';
import 'device_frame.dart';
import 'device_preset.dart';

/// Wraps the whole app (`MaterialApp.builder`). Ported from PhumiYerng.
///
/// Without [enabled] (`Env.devTools` off) this is just [child]: the app
/// lays itself out for the real window.
///
/// With it, a desktop browser draws the app as the chosen device in the
/// window (`DeviceFrame`), and a narrow window gets the fake safe areas
/// with `?insets`. The tools are a floating sidebar against the left or
/// right edge when there's room (the device centres in the rest), else a
/// floating button that opens them in a sheet (always the button on
/// phones). `?clean` hides the tools but keeps the frame, for screenshots.
class DevTools extends StatefulWidget {
  const DevTools({
    super.key,
    required this.enabled,
    required this.prefs,
    required this.child,
  });

  final bool enabled;
  final SharedPreferences prefs;
  final Widget child;

  @override
  State<DevTools> createState() => _DevToolsState();
}

class _DevToolsState extends State<DevTools> {
  static final _query = Uri.base.queryParameters;

  /// The device scales down to fit beside the sidebar, but no narrower
  /// than this.
  static const _minDeviceWidth = 360.0;

  late final DevToolsController? _controller = _enabled
      ? (DevToolsController(widget.prefs)..applySlowMotion())
      : null;

  bool get _enabled => widget.enabled && !_query.containsKey('clean');

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!widget.enabled) return widget.child;
    if (controller == null) return _frame(context, DeviceLook.standard);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _frame(context, controller.look),
    );
  }

  Widget _frame(BuildContext context, DeviceLook look) {
    final controller = _controller;
    final width = MediaQuery.sizeOf(context).width;
    final framed = kIsWeb && width >= 600;
    final insets = kIsWeb && _query.containsKey('insets');
    // Narrower windows get the button.
    final sidebar =
        controller != null &&
        framed &&
        width >=
            _minDeviceWidth +
                DevToolsSidebar.width +
                4 * DevToolsSidebar.margin;
    final bubble = controller != null && !sidebar
        ? Positioned.fill(
            child: DevToolsBubble(
              onTap: () => _openSheet(controller, device: framed),
            ),
          )
        : null;

    if (!framed && !insets) {
      // Phones (and a plain narrow browser window): the app as it is.
      if (bubble == null) return widget.child;
      return Stack(children: [widget.child, bubble]);
    }

    final phone = DeviceFrame(
      look: look,
      fill: !framed,
      platform: controller != null,
      overlay: bubble,
      child: widget.child,
    );
    if (!framed) return phone;

    const reserve = DevToolsSidebar.width + DevToolsSidebar.margin;
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF070B14)
          : const Color(0xFFE6EBF2),
      child: !sidebar
          ? phone
          : Stack(
              children: [
                // The phone moves over when the sidebar changes side.
                Positioned.fill(
                  child: AnimatedPadding(
                    duration: AppMotion.page,
                    curve: AppMotion.emphasized,
                    padding: EdgeInsets.only(
                      left: controller.sidebarRight ? 0 : reserve,
                      right: controller.sidebarRight ? reserve : 0,
                    ),
                    child: phone,
                  ),
                ),
                Positioned.fill(child: DevToolsSidebar(controller: controller)),
              ],
            ),
    );
  }

  /// [device]: the phone is drawn by the preview (a wide web window too
  /// narrow for the sidebar), so its settings apply. Never on a phone.
  void _openSheet(DevToolsController controller, {required bool device}) {
    final context = AppRouter.navigatorKey?.currentContext;
    if (context == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: DevToolsPanel(
            controller: controller,
            parts: [
              DevToolsPart.routes,
              DevToolsPart.data,
              DevToolsPart.preferences,
              if (device) DevToolsPart.device,
              DevToolsPart.motion,
            ],
            onDone: () => Navigator.of(sheet).pop(),
          ),
        ),
      ),
    );
  }
}
