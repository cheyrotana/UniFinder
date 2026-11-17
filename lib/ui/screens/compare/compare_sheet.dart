import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../Domain/model/Major/major_model.dart';
import '../../../main.dart' show catalog;
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/cards.dart';
import '../../widgets/pressable.dart';

/// Pick a major (this one or a related one) and two universities that
/// teach it, then open the side-by-side comparison.
class CompareSheet extends StatefulWidget {
  const CompareSheet({super.key, required this.majorId});

  final String majorId;

  static Future<void> show(BuildContext context, {required String majorId}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => CompareSheet(majorId: majorId),
      );

  @override
  State<CompareSheet> createState() => _CompareSheetState();
}

class _CompareSheetState extends State<CompareSheet> {
  late String _majorId = widget.majorId;
  final List<String> _picked = [];

  /// This major and its related ones, where at least two places teach it.
  late final List<Major> _majors = [
    for (final m in [
      ?catalog.major(widget.majorId),
      ...catalog.relatedMajors(widget.majorId),
    ])
      if (catalog.offeringsOf(m.id ?? '').length >= 2) m,
  ];

  void _toggle(String universityId) => setState(() {
    if (_picked.remove(universityId)) return;
    if (_picked.length == 2) _picked.removeAt(0);
    _picked.add(universityId);
  });

  @override
  Widget build(BuildContext context) {
    final offerings = catalog.offeringsOf(_majorId);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              children: [
                Text('Compare universities', style: context.text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Choose a major, then two places that teach it.',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in _majors)
                      ChoiceChip(
                        label: Text(m.name),
                        selected: m.id == _majorId,
                        labelStyle: context.text.labelMedium!.copyWith(
                          color: m.id == _majorId
                              ? Colors.white
                              : context.colors.ink,
                        ),
                        onSelected: (_) => setState(() {
                          _majorId = m.id ?? '';
                          _picked.clear();
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Universities · ${_picked.length}/2 picked',
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final o in offerings) ...[
                  _PickRow(
                    key: ValueKey('${_majorId}_${o.university.id}'),
                    order: _picked.indexOf(o.university.id ?? '') + 1,
                    title: o.university.shortName ?? o.university.name,
                    subtitle:
                        '\$${o.universityMajor.pricePerYear.round()} / year · ${o.durationYears} years',
                    logo: UniversityLogo(university: o.university, size: 40),
                    onTap: () => _toggle(o.university.id ?? ''),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.colors.hairline)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _picked.length == 2
                    ? () {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        router.push(
                          '/compare?major=$_majorId&a=${_picked[0]}&b=${_picked[1]}',
                        );
                      }
                    : null,
                icon: const Icon(Icons.compare_arrows_rounded),
                label: const Text('Compare'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    super.key,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.logo,
    required this.onTap,
  });

  /// 1 or 2 when picked, else 0.
  final int order;
  final String title;
  final String subtitle;
  final Widget logo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = order > 0;
    final primary = context.scheme.primary;
    return Pressable(
      onTap: onTap,
      haptic: true,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: on ? context.colors.brandSoft : context.colors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: on ? primary : context.colors.hairline,
            width: on ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            logo,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  Text(subtitle, style: context.text.bodySmall),
                ],
              ),
            ),
            AnimatedContainer(
              duration: AppMotion.medium,
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? primary : Colors.transparent,
                border: Border.all(
                  color: on ? primary : context.colors.hairline,
                  width: 2,
                ),
              ),
              child: AnimatedScale(
                scale: on ? 1 : 0,
                duration: AppMotion.medium,
                curve: Curves.easeOutBack,
                child: Text(
                  on ? '$order' : '',
                  style: context.text.labelSmall!.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
