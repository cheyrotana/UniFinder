import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_events.dart';
import '../../../Domain/model/Dream/dreams_model.dart';
import '../../../Domain/model/Major/major_recommendation_model.dart';
import '../../../main.dart'
    show catalog, dreamService, recommendationService, userService;
import '../../../routers/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_image.dart';
import '../../widgets/category_style.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';
import '../../widgets/pressable.dart';

/// The quiz results: the top five majors with their match. Pick one and
/// save it as a dream.
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<MajorRecommendation> _recs = [];
  String _name = '';
  bool _loading = true;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await userService.getUser();
    final recs = user == null
        ? <MajorRecommendation>[]
        : await recommendationService.generateRecommendations(user.id ?? '');
    if (!mounted) return;
    setState(() {
      _name = user?.name ?? '';
      _recs = recs;
      _selected = recs.isEmpty ? null : 0;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final rec = _recs[_selected!];
    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NameDreamSheet(majorName: rec.major.name),
    );
    if (title == null || !mounted) return;
    final user = await userService.getUser();
    await dreamService.saveDream(
      Dream(
        id: const Uuid().v4(),
        title: title,
        userId: user?.id ?? '',
        majorId: rec.major.id ?? '',
      ),
    );
    AppEvents.notifyDataChanged();
    if (!mounted) return;
    context.go('/home');
    AppRouter.messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('“$title” saved to your dreams')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recs.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matches yet',
                message: 'Take the quiz to get majors matched to you.',
                action: FilledButton(
                  onPressed: () => context.go('/quiz'),
                  child: const Text('Take the quiz'),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverSafeArea(
                  bottom: false,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.lg,
                      AppSpacing.gutter,
                      AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Entrance(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tag(
                              'Quiz complete',
                              icon: Icons.check_circle_rounded,
                              color: context.colors.success,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _name.isEmpty
                                  ? 'Your top matches'
                                  : 'Your top matches, $_name',
                              style: context.text.headlineMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pick one to save as a dream. You can explore every major later.',
                              style: context.text.bodyMedium!.copyWith(
                                color: context.colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  sliver: SliverList.separated(
                    itemCount: _recs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => Entrance(
                      index: i + 1,
                      child: _MatchCard(
                        rec: _recs[i],
                        rank: i + 1,
                        selected: _selected == i,
                        onTap: () => setState(() => _selected = i),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 100 + bottom)),
              ],
            ),
      bottomNavigationBar: _recs.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.sm + bottom,
              ),
              decoration: BoxDecoration(
                color: context.colors.card,
                border: Border(top: BorderSide(color: context.colors.hairline)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Skip'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _selected == null ? null : _save,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Save as my dream'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.rec,
    required this.rank,
    required this.selected,
    required this.onTap,
  });

  final MajorRecommendation rec;
  final int rank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final major = rec.major;
    final style = CategoryStyle.of(major.categoryId);
    final primary = context.scheme.primary;
    final top = rank == 1;
    final count = catalog.universityCount(major.id ?? '');
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? primary : context.colors.hairline,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (top)
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MajorImage(major: major, cacheWidth: 800),
                      const PhotoScrim(strength: 0.55),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Tag(
                          'Best match',
                          icon: Icons.emoji_events_rounded,
                          filled: true,
                          color: context.colors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!top) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: SizedBox.square(
                          dimension: 52,
                          child: MajorImage(major: major, cacheWidth: 200),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(major.name, style: context.text.titleMedium),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Tag(style.short, icon: style.icon,
                                  color: style.color),
                              Tag(
                                '$count ${count == 1 ? 'university' : 'universities'}',
                                icon: Icons.account_balance_outlined,
                              ),
                            ],
                          ),
                          if (top || selected) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              major.description,
                              style: context.text.bodySmall,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ScoreRing(score: rec.matchScore),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The match % as a ring that fills when it appears.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 50
        ? context.colors.success
        : score >= 25
        ? context.scheme.primary
        : context.colors.warning;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 900),
      curve: AppMotion.emphasized,
      builder: (context, v, _) => SizedBox.square(
        dimension: 54,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: context.colors.field,
            ),
            Center(
              child: Text(
                '${(v * 100).round()}%',
                style: context.text.labelMedium!.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Names the new dream (prefilled) and returns it.
class _NameDreamSheet extends StatefulWidget {
  const _NameDreamSheet({required this.majorName});

  final String majorName;

  @override
  State<_NameDreamSheet> createState() => _NameDreamSheetState();
}

class _NameDreamSheetState extends State<_NameDreamSheet> {
  late final _controller = TextEditingController(
    text: 'Study ${widget.majorName}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    final title = _controller.text.trim();
    if (title.length >= 3) Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.gutter + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name your dream', style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'A short name helps you find it on Home.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _done(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.auto_awesome_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => FilledButton(
                onPressed: _controller.text.trim().length >= 3 ? _done : null,
                child: const Text('Save dream'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
