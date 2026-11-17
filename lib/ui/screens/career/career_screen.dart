import 'package:flutter/material.dart';

import '../../../main.dart' show catalog;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_image.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';
import '../../widgets/photo_header.dart';

/// A career: pay, what the job is, skills, how it grows (a timeline), and
/// the majors that lead to it.
class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key, required this.careerId});

  final String careerId;

  @override
  Widget build(BuildContext context) {
    final career = catalog.career(careerId);
    if (career == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: EmptyState(
            icon: Icons.work_outline_rounded,
            title: 'Career not found',
          ),
        ),
      );
    }
    final majors = catalog.majorsForCareer(careerId);
    final skills = career.skills ?? const <String>[];
    final steps = career.careerProgression?.entries.toList() ?? const [];

    return PhotoHeaderScaffold(
      heroTag: HeroTags.career(careerId),
      photo: CareerImage(career: career, animated: true),
      sceneAccent: AppImage.isScene(career.imagePath)
          ? CareerImage.accentOf(career)
          : null,
      overline: 'Career',
      title: career.name,
      subtitle: career.shortDescription,
      slivers: [
        HeaderSection(
          top: AppSpacing.lg,
          child: Entrance(
            child: StatRow(
              stats: [
                (
                  Icons.payments_outlined,
                  career.salaryRange?.replaceAll(' / month', '') ?? '—',
                  'Salary / month',
                ),
                (Icons.bolt_outlined, '${skills.length}', 'Key skills'),
                (Icons.school_outlined, '${majors.length}', 'Majors'),
              ],
            ),
          ),
        ),
        HeaderSection(
          child: Entrance(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About the job', style: context.text.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  ExpandableText(career.description, lines: 4),
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('Skills you need', style: context.text.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in skills)
                          Tag(s, icon: Icons.check_rounded,
                              color: context.scheme.primary),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (steps.isNotEmpty) ...[
          const HeaderSection(
            child: SectionHeader(
              title: 'How it grows',
              subtitle: 'A typical path from first job to senior',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              0,
            ),
            sliver: SliverList.builder(
              itemCount: steps.length,
              itemBuilder: (context, i) => Entrance(
                index: i + 2,
                child: _Step(
                  level: steps[i].key,
                  text: steps[i].value,
                  first: i == 0,
                  last: i == steps.length - 1,
                  progress: (i + 1) / steps.length,
                ),
              ),
            ),
          ),
        ],
        if (majors.isNotEmpty) ...[
          const HeaderSection(
            child: SectionHeader(
              title: 'Majors that lead here',
              subtitle: 'Study one of these to get started',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              0,
            ),
            sliver: SliverList.separated(
              itemCount: majors.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, i) => MajorRow(major: majors[i]),
            ),
          ),
        ],
      ],
    );
  }
}

/// One level of the career path, on a vertical line of dots that get
/// darker as you go up.
class _Step extends StatelessWidget {
  const _Step({
    required this.level,
    required this.text,
    required this.first,
    required this.last,
    required this.progress,
  });

  final String level;
  final String text;
  final bool first;
  final bool last;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final primary = context.scheme.primary;
    final dash = text.indexOf(' - ');
    final role = dash > 0 ? text.substring(0, dash) : text;
    final detail = dash > 0 ? text.substring(dash + 3) : null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 6,
                  color: first ? Colors.transparent : context.colors.hairline,
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      context.colors.brandSoft,
                      primary,
                      progress,
                    ),
                    border: Border.all(color: primary, width: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: last ? Colors.transparent : context.colors.hairline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.toUpperCase(),
                    style: context.text.labelSmall!.copyWith(
                      color: primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(role, style: context.text.titleSmall),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(detail, style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
