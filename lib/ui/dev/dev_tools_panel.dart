import 'package:flutter/material.dart';

import '../../core/app_restart.dart';
import '../../core/settings_controller.dart';
import '../../routers/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import 'dev_data.dart';
import 'dev_tools_controller.dart';
import 'device_preset.dart';

/// A group of dev tools controls.
enum DevToolsPart { preferences, data, routes, device, motion }

/// The dev tools controls (developer-only, so English): the app's
/// preferences, its local data, jumps to any screen, the web preview's
/// phone, and slow motion. Built from [parts], so the web sidebar's tabs and
/// the phone's sheet share it. (Ported from PhumiYerng.)
///
/// The dropdowns need a navigator above: the sidebar has its own, the
/// sheet is on the app's.
class DevToolsPanel extends StatelessWidget {
  const DevToolsPanel({
    super.key,
    required this.controller,
    required this.parts,
    this.onDone,
  });

  final DevToolsController controller;
  final List<DevToolsPart> parts;

  /// Called before an action navigates or restarts (closes the phone's
  /// sheet).
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, AppSettings.read(context)]),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final part in parts)
            switch (part) {
              DevToolsPart.preferences => const _PreferencesPart(),
              DevToolsPart.data => _DataPart(onDone: onDone),
              DevToolsPart.routes => _RoutesPart(onDone: onDone),
              DevToolsPart.device => _DevicePart(controller: controller),
              DevToolsPart.motion => _MotionPart(controller: controller),
            },
        ],
      ),
    );
  }
}

class _PreferencesPart extends StatelessWidget {
  const _PreferencesPart();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    return _Group(
      title: 'Preferences',
      children: [
        _SelectRow<ThemeMode>(
          label: 'Theme',
          values: const [ThemeMode.light, ThemeMode.dark, ThemeMode.system],
          selected: settings.themeMode,
          icon: (m) => switch (m) {
            ThemeMode.light => Icons.light_mode_outlined,
            ThemeMode.dark => Icons.dark_mode_outlined,
            ThemeMode.system => Icons.brightness_auto_outlined,
          },
          name: (m) => switch (m) {
            ThemeMode.light => 'Light',
            ThemeMode.dark => 'Dark',
            ThemeMode.system => 'System',
          },
          onSelected: settings.setThemeMode,
        ),
        _SelectRow<double>(
          label: 'Text size',
          values: SettingsController.textScales,
          selected: settings.textScale,
          name: (scale) => '${(scale * 100).round()}%',
          onSelected: settings.setTextScale,
        ),
      ],
    );
  }
}

class _MotionPart extends StatelessWidget {
  const _MotionPart({required this.controller});

  final DevToolsController controller;

  @override
  Widget build(BuildContext context) => _Group(
    title: 'Animations',
    note: 'Slow motion stretches every page, tab and hero transition 5×.',
    children: [
      _SwitchRow(
        label: 'Slow motion',
        value: controller.slowMotion,
        onChanged: controller.setSlowMotion,
      ),
    ],
  );
}

/// The app's local data (shared preferences): sample dreams, resets.
class _DataPart extends StatelessWidget {
  const _DataPart({this.onDone});

  final VoidCallback? onDone;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    required String done,
  }) async {
    final restart = AppRestart.of(context).restart;
    onDone?.call();
    await action();
    restart();
    final messenger = AppRouter.messengerKey.currentState;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => messenger?.showSnackBar(SnackBar(content: Text(done))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Group(
      title: 'Data',
      note: 'Each action restarts the app.',
      plain: true,
      children: [
        _ActionTile(
          icon: Icons.auto_awesome_outlined,
          label: 'Seed sample profile',
          hint: 'A user, a finished quiz and 3 dreams',
          onTap: () => _run(context, DevData.seed, done: 'Sample data added'),
        ),
        _ActionTile(
          icon: Icons.layers_clear_outlined,
          label: 'Clear dreams',
          hint: 'Keeps the user and the quiz',
          onTap: () =>
              _run(context, DevData.clearDreams, done: 'Dreams cleared'),
        ),
        _ActionTile(
          icon: Icons.restart_alt_rounded,
          label: 'Reset to first launch',
          hint: 'Removes the user, quiz and dreams',
          danger: true,
          onTap: () =>
              _run(context, DevData.resetAll, done: 'Back to first launch'),
        ),
      ],
    );
  }
}

/// Jumps straight to any screen.
class _RoutesPart extends StatelessWidget {
  const _RoutesPart({this.onDone});

  final VoidCallback? onDone;

  static const _routes = [
    ('Splash', '/', Icons.water_drop_outlined),
    ('Onboarding', '/onboarding', Icons.view_carousel_outlined),
    ('Your name', '/name', Icons.badge_outlined),
    ('Quiz', '/quiz', Icons.quiz_outlined),
    ('Results', '/recommendation', Icons.emoji_events_outlined),
    ('Home', '/home', Icons.home_outlined),
    ('Explore', '/explore', Icons.explore_outlined),
    ('Profile', '/profile', Icons.person_outline),
    ('Major · CS', '/major/1', Icons.school_outlined),
    ('Career · Dev', '/career/1', Icons.work_outline),
    ('University · RUPP', '/university/1', Icons.account_balance_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return _Group(
      title: 'Go to',
      plain: true,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (label, path, icon) in _routes)
              ActionChip(
                avatar: Icon(icon, size: 16),
                label: Text(label, style: text.labelSmall),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  onDone?.call();
                  AppRouter.current?.go(path);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _DevicePart extends StatelessWidget {
  const _DevicePart({required this.controller});

  final DevToolsController controller;

  @override
  Widget build(BuildContext context) {
    final look = controller.look;
    final size = look.preset.size;
    final changed =
        look.cutout != look.preset.cutout || look.nav != look.preset.nav;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (title, tablets) in const [
          ('Phones', false),
          ('Tablets', true),
        ])
          _Group(
            title: title,
            plain: true,
            children: [
              _DeviceGrid(
                presets: [
                  for (final preset in devicePresets)
                    if (preset.isTablet == tablets) preset,
                ],
                look: look,
                onSelected: controller.setPreset,
              ),
            ],
          ),
        _Group(
          title: 'Screen',
          action: changed
              ? _GroupAction(
                  label: 'Reset',
                  onTap: () => controller.setPreset(look.preset),
                )
              : null,
          note:
              '${size.width.round()} × ${size.height.round()} · '
              '${look.preset.isApple ? 'iOS' : 'Android'} widgets · safe areas '
              '${look.insets.top.round()} / ${look.insets.bottom.round()}',
          children: [
            _SelectRow<DeviceCutout>(
              label: 'Cutout',
              values: DeviceCutout.values,
              selected: look.cutout,
              name: (c) => switch (c) {
                DeviceCutout.none => 'None',
                DeviceCutout.notch => 'Notch',
                DeviceCutout.island => 'Dynamic Island',
                DeviceCutout.punchHole => 'Punch hole',
              },
              onSelected: controller.setCutout,
            ),
            _SelectRow<DeviceNav>(
              label: 'Navigation',
              values: DeviceNav.values,
              selected: look.nav,
              name: (n) => switch (n) {
                DeviceNav.homeIndicator => 'Home indicator',
                DeviceNav.gestureBar => 'Gesture bar',
                DeviceNav.threeButton => '3 buttons',
                DeviceNav.none => 'Home button',
              },
              onSelected: controller.setNav,
            ),
            _SwitchRow(
              label: 'Status bar',
              value: look.statusBar,
              onChanged: controller.setStatusBar,
            ),
            _SwitchRow(
              label: 'Bezel',
              value: look.bezel,
              onChanged: controller.setBezel,
            ),
          ],
        ),
      ],
    );
  }
}

/// Three tiles a row.
class _DeviceGrid extends StatelessWidget {
  const _DeviceGrid({
    required this.presets,
    required this.look,
    required this.onSelected,
  });

  final List<DevicePreset> presets;
  final DeviceLook look;
  final ValueChanged<DevicePreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.xs;
        final width = (constraints.maxWidth - 2 * gap) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final preset in presets)
              SizedBox(
                width: width,
                child: _DeviceTile(
                  preset: preset,
                  look: preset == look.preset ? look : null,
                  onTap: () => onSelected(preset),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A device in the preview grid: its outline to scale, name and size.
/// [look] is set on the chosen one, which draws its current cutout and
/// navigation.
class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.preset, required this.onTap, this.look});

  final DevicePreset preset;
  final DeviceLook? look;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final colors = context.colors;
    final selected = look != null;
    final text = context.text;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: AppMotion.short,
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.08)
                  : colors.field,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? scheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Center(
                    child: CustomPaint(
                      size: Size(56 * preset.size.aspectRatio, 56),
                      painter: _MiniPhonePainter(
                        preset: preset,
                        cutout: look?.cutout ?? preset.cutout,
                        nav: look?.nav ?? preset.nav,
                        outline: selected ? scheme.primary : colors.muted,
                        fill: selected
                            ? scheme.primary.withValues(alpha: 0.10)
                            : colors.card,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Two lines for every name, so the tiles line up.
                SizedBox(
                  height: 30,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      preset.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall!.copyWith(
                        height: 1.2,
                        color: selected ? scheme.primary : null,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${preset.size.width.round()}×${preset.size.height.round()}',
                  style: text.labelSmall!.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A phone's outline at tile size: corners, cutout and system navigation.
class _MiniPhonePainter extends CustomPainter {
  _MiniPhonePainter({
    required this.preset,
    required this.cutout,
    required this.nav,
    required this.outline,
    required this.fill,
  });

  final DevicePreset preset;
  final DeviceCutout cutout;
  final DeviceNav nav;
  final Color outline;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / preset.size.height;
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular((preset.radius * scale).clamp(2, 12)),
    );
    canvas.drawRRect(body, Paint()..color = fill);
    canvas.drawRRect(
      body.deflate(0.75),
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final ink = Paint()..color = outline;
    final cx = size.width / 2;
    switch (cutout) {
      case DeviceCutout.island:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, 5),
              width: size.width * 0.32,
              height: 3.5,
            ),
            const Radius.circular(2),
          ),
          ink,
        );
      case DeviceCutout.notch:
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - size.width * 0.2, 0, size.width * 0.4, 4.5),
            bottomLeft: const Radius.circular(2.5),
            bottomRight: const Radius.circular(2.5),
          ),
          ink,
        );
      case DeviceCutout.punchHole:
        canvas.drawCircle(Offset(cx, 5), 1.8, ink);
      case DeviceCutout.none:
        break;
    }

    final bar = Paint()
      ..color = outline
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final y = size.height - 4;
    switch (nav) {
      case DeviceNav.homeIndicator || DeviceNav.gestureBar:
        final half = size.width * (nav == DeviceNav.homeIndicator ? 0.2 : 0.14);
        canvas.drawLine(Offset(cx - half, y), Offset(cx + half, y), bar);
      case DeviceNav.threeButton:
        for (final dx in [-size.width * 0.22, 0.0, size.width * 0.22]) {
          canvas.drawCircle(Offset(cx + dx, y), 1.1, ink);
        }
      case DeviceNav.none:
        canvas.drawCircle(
          Offset(cx, size.height - 5),
          2.4,
          Paint()
            ..color = outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
    }
  }

  @override
  bool shouldRepaint(_MiniPhonePainter old) =>
      old.preset != preset ||
      old.cutout != cutout ||
      old.nav != nav ||
      old.outline != outline ||
      old.fill != fill;
}

class _GroupAction {
  const _GroupAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// A titled group: its rows in a tinted card ([plain]: no card), an
/// optional small action beside the title, and a [note] under it.
class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.children,
    this.note,
    this.action,
    this.plain = false,
  });

  final String title;
  final List<Widget> children;
  final String? note;
  final _GroupAction? action;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0 && !plain)
            Divider(height: 1, thickness: 1, color: colors.hairline),
          if (i > 0 && plain) const SizedBox(height: 6),
          child,
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: text.labelSmall!.copyWith(
                      color: colors.muted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (action case final action?)
                  TextButton(
                    onPressed: action.onTap,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: text.labelMedium,
                    ),
                    child: Text(action.label),
                  ),
              ],
            ),
          ),
          if (plain)
            rows
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.field,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: rows,
              ),
            ),
          if (note case final note?)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                note,
                style: text.bodySmall!.copyWith(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

/// A tappable row with an icon, a label and a hint (data actions).
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = danger ? colors.danger : context.scheme.primary;
    return Material(
      color: colors.field,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 20, color: tint),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.text.labelMedium!.copyWith(
                        color: danger ? colors.danger : null,
                      ),
                    ),
                    Text(
                      hint,
                      style: context.text.bodySmall!.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: colors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

/// A label (and small [hint]) with a compact dropdown on the right.
class _SelectRow<T> extends StatelessWidget {
  const _SelectRow({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.name,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final List<T> values;
  final T selected;

  /// Each choice's text.
  final String Function(T) name;
  final IconData Function(T)? icon;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final colors = context.colors;
    final text = context.text;
    Widget choice(T value) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon case final icon?) ...[
          Icon(icon(value), size: 16),
          const SizedBox(width: 6),
        ],
        Flexible(child: Text(name(value), overflow: TextOverflow.ellipsis)),
      ],
    );
    return _Row(
      label: label,
      trailing: Container(
        height: 32,
        width: 148,
        padding: const EdgeInsets.only(left: 10, right: 4),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: colors.hairline),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: values.contains(selected) ? selected : null,
            isExpanded: true,
            isDense: true,
            borderRadius: BorderRadius.circular(AppRadius.md),
            dropdownColor: colors.card,
            icon: Icon(
              Icons.unfold_more_rounded,
              size: 16,
              color: colors.muted,
            ),
            style: text.labelMedium!.copyWith(color: scheme.onSurface),
            items: [
              for (final value in values)
                DropdownMenuItem(value: value, child: choice(value)),
            ],
            onChanged: (value) {
              if (value != null) onSelected(value);
            },
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _Row(
    label: label,
    onTap: () => onChanged(!value),
    trailing: SizedBox(
      height: 32,
      child: FittedBox(
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ),
  );
}

/// One line of a group: the label on the left, the control on the right.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.trailing, this.onTap});

  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(child: Text(label, style: context.text.bodyMedium)),
            const SizedBox(width: AppSpacing.xs),
            trailing,
          ],
        ),
      ),
    );
  }
}
