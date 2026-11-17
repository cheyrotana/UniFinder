import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_events.dart';
import '../../../core/app_restart.dart';
import '../../../core/settings_controller.dart';
import '../../../Domain/model/User/user_model.dart';
import '../../../main.dart' show catalog, dreamService, questionService, userService;
import '../../dev/dev_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';

/// The student's profile and the app's settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  int _dreams = 0;
  int _quizzes = 0;

  @override
  void initState() {
    super.initState();
    AppEvents.dataChanged.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppEvents.dataChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final user = await userService.getUser();
    final dreams = await dreamService.getDreams();
    final submissions = await questionService.getSubmissionData();
    if (!mounted) return;
    setState(() {
      _user = user;
      _dreams = dreams.length;
      _quizzes = submissions.where((s) => s.userId == user?.id).length;
    });
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _user?.name ?? '');
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.gutter + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your name', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (name == null || name.length < 2) return;
    await userService.saveUser(User(id: _user?.id, name: name));
    AppEvents.notifyDataChanged();
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text(
          'This removes your name, quiz answers and every saved dream from this phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.danger,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final restart = AppRestart.of(context).restart;
    await DevData.resetAll();
    restart();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final name = _user?.name ?? '';
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          MediaQuery.paddingOf(context).top + AppSpacing.md,
          AppSpacing.gutter,
          bottom + AppSpacing.xl,
        ),
        children: [
          Text('Profile', style: context.text.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          Entrance(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: context.scheme.primary,
                        child: Text(
                          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                          style: context.text.headlineSmall!.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Student' : name,
                              style: context.text.titleLarge,
                            ),
                            Text(
                              'Planning a future in Phnom Penh',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit name',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _editName,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      _Stat(value: '$_dreams', label: 'Dreams'),
                      _Stat(value: '$_quizzes', label: 'Quizzes taken'),
                      _Stat(
                        value: '${catalog.majors.length}',
                        label: 'Majors to explore',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Label('Appearance'),
          Entrance(
            index: 1,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined),
                          label: Text('Auto'),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) => settings.setThemeMode(s.first),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Text('Text size', style: context.text.titleSmall),
                      const Spacer(),
                      Text(
                        '${(settings.textScale * 100).round()}%',
                        style: context.text.labelMedium!.copyWith(
                          color: context.scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.text_decrease_rounded,
                          size: 18, color: context.colors.muted),
                      Expanded(
                        child: Slider(
                          value: SettingsController.textScales
                              .indexOf(settings.textScale)
                              .clamp(0, 3)
                              .toDouble(),
                          max: 3,
                          divisions: 3,
                          onChanged: (v) => settings.setTextScale(
                            SettingsController.textScales[v.round()],
                          ),
                        ),
                      ),
                      Icon(Icons.text_increase_rounded,
                          size: 20, color: context.colors.muted),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Label('Your plan'),
          Entrance(
            index: 2,
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Row(
                    icon: Icons.psychology_alt_outlined,
                    title: 'Retake the quiz',
                    subtitle: 'Get fresh major matches',
                    onTap: () => context.push('/quiz'),
                  ),
                  _Row(
                    icon: Icons.emoji_events_outlined,
                    title: 'Last results',
                    subtitle: 'See your latest top matches',
                    onTap: _quizzes == 0
                        ? null
                        : () => context.push('/recommendation'),
                  ),
                  _Row(
                    icon: Icons.restart_alt_rounded,
                    title: 'Start over',
                    subtitle: 'Remove your data from this phone',
                    color: context.colors.danger,
                    onTap: _reset,
                    last: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Label('About'),
          Entrance(
            index: 3,
            child: AppCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      color: Colors.white,
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        'assets/logo/test.png',
                        fit: BoxFit.cover,
                        scale: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UniFinder 1.0', style: context.text.titleSmall),
                        Text(
                          'Works fully offline. Made by Man Arafat & Chey Rotana.',
                          style: context.text.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Illustrations by Storyset (storyset.com)',
                          style: context.text.bodySmall!.copyWith(
                            color: context.colors.subtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
    child: Text(
      text.toUpperCase(),
      style: context.text.labelSmall!.copyWith(
        color: context.colors.muted,
        letterSpacing: 1,
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        AnimatedSwitcher(
          duration: AppMotion.medium,
          child: Text(
            value,
            key: ValueKey(value),
            style: context.text.headlineSmall!.copyWith(
              color: context.scheme.primary,
            ),
          ),
        ),
        Text(
          label,
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? color;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: context.colors.hairline)),
          ),
          child: Row(
            children: [
              IconTile(icon: icon, color: color, size: 38),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleSmall!.copyWith(color: color),
                    ),
                    Text(subtitle, style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}
