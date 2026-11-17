import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_events.dart';
import '../../../Domain/model/Dream/dreams_model.dart';
import '../../../Domain/model/Major/major_model.dart';
import '../../../main.dart' show catalog, dreamService, userService;
import '../../../routers/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_image.dart';
import '../../widgets/cards.dart';
import '../../widgets/category_style.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';
import '../../widgets/photo_header.dart';
import '../compare/compare_sheet.dart';

/// A major: what it is, the skills it builds, the careers it leads to,
/// where it's taught (cheapest first) and related majors.
///
/// With [dream] it's that dream's screen: the dream's name on the header,
/// Compare and Delete actions, and its own hero tag (so the photo flies
/// from the dream card on Home).
class MajorScreen extends StatelessWidget {
  const MajorScreen({super.key, required this.majorId, this.dream});

  final String majorId;
  final Dream? dream;

  @override
  Widget build(BuildContext context) {
    final major = catalog.major(majorId);
    if (major == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: EmptyState(
            icon: Icons.school_outlined,
            title: 'Major not found',
          ),
        ),
      );
    }
    final dream = this.dream;
    final style = CategoryStyle.of(major.categoryId);
    final careers = catalog.careersForMajor(majorId);
    final offerings = catalog.offeringsOf(majorId);
    final related = catalog.relatedMajors(majorId);
    final tuition = catalog.tuitionRange(majorId);

    return PhotoHeaderScaffold(
      heroTag: dream == null
          ? HeroTags.major(majorId)
          : HeroTags.dream(dream.id),
      photo: MajorImage(major: major, animated: true),
      sceneAccent: AppImage.isScene(major.imagePath)
          ? MajorImage.accentOf(major)
          : null,
      overline: dream == null ? null : 'Your dream · ${dream.title ?? ''}',
      title: major.name,
      badge: Tag(
        catalog.category(major.categoryId)?.name ?? style.short,
        icon: style.icon,
        filled: true,
        color: style.color,
      ),
      actions: [
        if (offerings.length >= 2)
          HeaderAction(
            icon: Icons.compare_arrows_rounded,
            tooltip: 'Compare universities',
            onPressed: () => CompareSheet.show(context, majorId: majorId),
          ),
        if (dream != null)
          HeaderAction(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete dream',
            onPressed: () => _deleteDream(context, dream),
          ),
      ],
      bottomBar: dream == null
          ? FilledButton.icon(
              onPressed: () => _saveDream(context, major),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save as a dream'),
            )
          : offerings.length >= 2
          ? FilledButton.icon(
              onPressed: () => CompareSheet.show(context, majorId: majorId),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text('Compare universities'),
            )
          : null,
      slivers: [
        HeaderSection(
          top: AppSpacing.lg,
          child: Entrance(
            child: StatRow(
              stats: [
                (
                  Icons.account_balance_outlined,
                  '${offerings.length}',
                  'Universities',
                ),
                (
                  Icons.payments_outlined,
                  tuition?.replaceAll(' / yr', '') ?? '—',
                  'Tuition / year',
                ),
                (Icons.work_outline_rounded, '${careers.length}', 'Careers'),
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
                  Text('About', style: context.text.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  ExpandableText(major.description),
                  if (major.keySkills.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text("Skills you'll build", style: context.text.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in major.keySkills)
                          Tag(s, color: style.color),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (careers.isNotEmpty) ...[
          HeaderSection(
            child: SectionHeader(
              title: 'Careers',
              subtitle: 'Where this major can take you',
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: CareerCard.height + AppSpacing.sm,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.gutter,
                  0,
                ),
                itemCount: careers.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) =>
                    CareerCard(career: careers[i], width: 230),
              ),
            ),
          ),
        ],
        HeaderSection(
          child: SectionHeader(
            title: 'Where to study',
            subtitle: offerings.isEmpty
                ? 'No university in the app offers it yet'
                : 'Cheapest first · tap for details',
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
            itemCount: offerings.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final o = offerings[i];
              return UniversityRow(
                university: o.university,
                subtitle: '${o.degreeType} · ${o.durationYears} years',
                trailing: _Price(
                  amount: o.universityMajor.pricePerYear,
                  cheapest: i == 0 && offerings.length > 1,
                ),
              );
            },
          ),
        ),
        if (related.isNotEmpty) ...[
          HeaderSection(
            child: const SectionHeader(
              title: 'Related majors',
              subtitle: 'Similar subjects worth a look',
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.gutter,
                  0,
                ),
                itemCount: related.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) =>
                    SizedBox(width: 150, child: MajorTile(major: related[i])),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveDream(BuildContext context, Major major) async {
    final user = await userService.getUser();
    final dream = Dream(
      id: const Uuid().v4(),
      userId: user?.id ?? '',
      majorId: major.id ?? '',
      title: 'Study ${major.name}',
    );
    await dreamService.saveDream(dream);
    AppEvents.notifyDataChanged();
    AppRouter.messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${major.name} saved to your dreams'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => AppRouter.current?.go('/home'),
          ),
        ),
      );
  }

  Future<void> _deleteDream(BuildContext context, Dream dream) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this dream?'),
        content: Text('“${dream.title ?? 'Dream'}” will be removed from Home.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await dreamService.deleteDream(dream.id!);
    AppEvents.notifyDataChanged();
    if (context.mounted) context.pop();
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.amount, required this.cheapest});

  final double amount;
  final bool cheapest;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${amount.round()}',
          style: context.text.titleSmall!.copyWith(
            color: cheapest ? context.colors.success : null,
          ),
        ),
        Text(
          cheapest ? 'cheapest' : 'per year',
          style: context.text.bodySmall!.copyWith(
            fontSize: 11,
            color: cheapest ? context.colors.success : null,
          ),
        ),
      ],
    );
  }
}
