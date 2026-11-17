import 'package:flutter/material.dart';

import '../../core/app_restart.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import 'dev_tools_controller.dart';
import 'dev_tools_panel.dart';

/// The web preview's dev tools: a full-height card floating against one
/// edge of the window. Drag its header to the other side; it settles on the
/// nearer one. Tabs Device / App. (Ported from PhumiYerng.)
///
/// Fills its parent (a `Positioned.fill`) but only the card takes touches.
/// It has its own navigator, so its dropdowns open inside it, not in the
/// phone.
class DevToolsSidebar extends StatefulWidget {
  const DevToolsSidebar({super.key, required this.controller});

  final DevToolsController controller;

  static const width = 320.0;

  /// The gap between the card and the window's edges.
  static const margin = 12.0;

  @override
  State<DevToolsSidebar> createState() => _DevToolsSidebarState();
}

class _DevToolsSidebarState extends State<DevToolsSidebar> {
  /// The card's left edge while it's being dragged.
  double? _dragLeft;

  DevToolsController get _controller => widget.controller;

  void _onDragUpdate(DragUpdateDetails details, double max) => setState(() {
    _dragLeft = ((_dragLeft ?? 0) + details.delta.dx).clamp(
      DevToolsSidebar.margin,
      max,
    );
  });

  /// Also the drag's cancel, which a plain tap on the header fires without
  /// a start: then nothing moved.
  void _onDragEnd(double width, double windowWidth) {
    final left = _dragLeft;
    if (left == null) return;
    final center = left + width / 2;
    setState(() => _dragLeft = null);
    _controller.setSidebarRight(center > windowWidth / 2);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const width = DevToolsSidebar.width;
        final windowWidth = constraints.maxWidth;
        final rightLeft = windowWidth - width - DevToolsSidebar.margin;
        final restingLeft = _controller.sidebarRight
            ? rightLeft
            : DevToolsSidebar.margin;
        final dragging = _dragLeft != null;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: dragging ? Duration.zero : AppMotion.page,
              curve: AppMotion.emphasized,
              top: DevToolsSidebar.margin,
              bottom: DevToolsSidebar.margin,
              left: _dragLeft ?? restingLeft,
              width: width,
              child: AnimatedScale(
                duration: AppMotion.short,
                scale: dragging ? 0.985 : 1,
                child: _Card(
                  lifted: dragging,
                  child: Column(
                    children: [
                      _Header(
                        controller: _controller,
                        onDragStart: () =>
                            setState(() => _dragLeft = restingLeft),
                        onDragUpdate: (d) => _onDragUpdate(d, rightLeft),
                        onDragEnd: () => _onDragEnd(width, windowWidth),
                      ),
                      Expanded(child: _navigator(context)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The window's size and safe areas are swapped for the card's, so
  /// dropdowns fit inside it.
  Widget _navigator(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: constraints.biggest,
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: ClipRect(
          child: Navigator(
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => _ToolsPage(controller: _controller),
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating card.
class _Card extends StatelessWidget {
  const _Card({required this.lifted, required this.child});

  final bool lifted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.short,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl - 4),
        border: Border.all(color: context.colors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.5 : 0.10),
            blurRadius: lifted ? 40 : 24,
            offset: Offset(0, lifted ? 16 : 8),
          ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Grip (drag to move the card), title, move-to-other-side.
class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final DevToolsController controller;
  final VoidCallback onDragStart;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final colors = context.colors;
    final text = context.text;
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => onDragStart(),
        onHorizontalDragUpdate: onDragUpdate,
        onHorizontalDragEnd: (_) => onDragEnd(),
        onHorizontalDragCancel: onDragEnd,
        child: Container(
          height: 52,
          padding: const EdgeInsets.only(left: 10, right: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.hairline)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: colors.subtle,
              ),
              const SizedBox(width: 4),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Dev tools', style: text.titleSmall)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.field,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'offline · local data',
                  style: text.labelSmall!.copyWith(
                    color: colors.muted,
                    fontSize: 10,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                icon: Icon(
                  controller.sidebarRight
                      ? Icons.keyboard_double_arrow_left_rounded
                      : Icons.keyboard_double_arrow_right_rounded,
                  color: colors.muted,
                  semanticLabel:
                      'Move to the ${controller.sidebarRight ? 'left' : 'right'}',
                ),
                onPressed: () =>
                    controller.setSidebarRight(!controller.sidebarRight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Tab { device, app }

/// Device / App tabs over their controls, and the footer restart.
class _ToolsPage extends StatefulWidget {
  const _ToolsPage({required this.controller});

  final DevToolsController controller;

  @override
  State<_ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<_ToolsPage> {
  var _tab = _Tab.app;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final colors = context.colors;
    return Material(
      color: colors.card,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xxs,
            ),
            child: _Tabs(
              selected: _tab,
              onSelected: (tab) => setState(() => _tab = tab),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.standard,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(
                      child.key == const ValueKey(_Tab.app) ? 0.04 : -0.04,
                      0,
                    ),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: SingleChildScrollView(
                key: ValueKey(_tab),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: DevToolsPanel(
                  controller: controller,
                  parts: switch (_tab) {
                    _Tab.device => const [DevToolsPart.device],
                    _Tab.app => const [
                      DevToolsPart.preferences,
                      DevToolsPart.routes,
                      DevToolsPart.data,
                      DevToolsPart.motion,
                    ],
                  },
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.hairline)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Restart app'),
                onPressed: () => AppRestart.of(context).restart(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A two-way switch with a sliding thumb.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});

  final _Tab selected;
  final ValueChanged<_Tab> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final colors = context.colors;
    final text = context.text;
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.field,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            alignment: selected == _Tab.app
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (tab, icon, label) in const [
                (_Tab.app, Icons.apps_rounded, 'App'),
                (_Tab.device, Icons.smartphone_rounded, 'Device'),
              ])
                Expanded(
                  child: Semantics(
                    selected: tab == selected,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: () => onSelected(tab),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: tab == selected
                                ? scheme.primary
                                : colors.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: text.labelMedium!.copyWith(
                              color: tab == selected
                                  ? scheme.onSurface
                                  : colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
