import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/app_events.dart';
import '../../../Domain/model/Dream/dreams_model.dart';
import '../../../Domain/model/Major/major_model.dart';
import '../../../main.dart' show catalog, dreamService, userService;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_image.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';
import '../../widgets/pressable.dart';

/// Home: a greeting, the quiz call-to-action, the student's dreams (swipe
/// to delete, with undo) and a strip of popular majors.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Dream> _dreams = [];
  String _name = '';
  bool _loading = true;
  String _query = '';

  /// Majors to suggest: the first of each category.
  late final List<Major> _popular = [
    for (final c in catalog.categories) ...catalog.majorsIn(c.id).take(2),
  ];

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
    final dreams = await dreamService.getDreams();
    final user = await userService.getUser();
    if (!mounted) return;
    setState(() {
      _dreams = dreams
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
      _name = user?.name ?? '';
      _loading = false;
    });
  }

  Future<void> _delete(Dream dream) async {
    final index = _dreams.indexOf(dream);
    setState(() => _dreams.remove(dream));
    await dreamService.deleteDream(dream.id!);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('“${dream.title ?? 'Dream'}” deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await dreamService.saveDream(dream);
            if (!mounted) return;
            setState(
              () => _dreams.insert(index.clamp(0, _dreams.length), dream),
            );
          },
        ),
      ),
    );
  }

  List<Dream> get _visible {
    if (_query.isEmpty) return _dreams;
    final q = _query.toLowerCase();
    return _dreams.where((d) {
      final major = catalog.major(d.majorId)?.name ?? '';
      return (d.title ?? '').toLowerCase().contains(q) ||
          major.toLowerCase().contains(q);
    }).toList();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning'
        : h < 17
        ? 'Good afternoon'
        : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dreams = _visible;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    0,
                  ),
                  child: _Greeting(greeting: _greeting, name: _name),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.lg,
                  AppSpacing.gutter,
                  AppSpacing.xl,
                ),
                child: Entrance(
                  index: 1,
                  child: _QuizBanner(hasDreams: _dreams.isNotEmpty),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Your dreams',
                subtitle: _dreams.isEmpty
                    ? null
                    : '${_dreams.length} saved · swipe left to delete',
              ),
            ),
            if (_dreams.length >= 4)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.gutter,
                    0,
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search your dreams',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_dreams.isEmpty)
              const SliverToBoxAdapter(child: _NoDreams())
            else if (dreams.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No dreams match your search',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                sliver: SliverList.separated(
                  itemCount: dreams.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => Entrance(
                    key: ValueKey(dreams[i].id),
                    index: i + 2,
                    child: _DreamCard(
                      dream: dreams[i],
                      onDelete: () => _delete(dreams[i]),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Popular majors',
                subtitle: 'One tap to see where to study them',
                action: 'Explore',
                onAction: () => context.go('/explore'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  itemCount: _popular.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) => SizedBox(
                    width: 150,
                    child: MajorTile(major: _popular[i]),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: bottom + AppSpacing.xl)),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: context.text.labelMedium!.copyWith(
                  color: context.colors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name.isEmpty ? greeting : '$greeting, $name',
                style: context.text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Pressable(
          onTap: () => context.go('/profile'),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: context.colors.brandSoft,
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: context.text.titleMedium!.copyWith(
                color: context.scheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The brand-blue card that starts (or retakes) the quiz.
class _QuizBanner extends StatelessWidget {
  const _QuizBanner({required this.hasDreams});

  final bool hasDreams;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push('/quiz'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDreams ? 'Find another path' : 'Find your perfect major',
                    style: context.text.titleLarge!.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '10 questions · about 2 minutes',
                    style: context.text.bodySmall!.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasDreams ? 'Retake the quiz' : 'Start the quiz',
                          style: context.text.labelMedium!.copyWith(
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_alt_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDreams extends StatelessWidget {
  const _NoDreams();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const IconTile(icon: Icons.auto_awesome_outlined, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No dreams yet', style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Take the quiz and save a major you love. It shows up here.',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A saved dream: the major's photo (which flies to the dream screen),
/// title, major, universities and date. Swipe left to delete.
class _DreamCard extends StatelessWidget {
  const _DreamCard({required this.dream, required this.onDelete});

  final Dream dream;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final major = catalog.major(dream.majorId);
    final count = catalog.universityCount(dream.majorId);
    return Dismissible(
      key: ValueKey('dream-${dream.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.colors.danger,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AppCard(
        padding: EdgeInsets.zero,
        clip: true,
        onTap: () => context.push('/dream/${dream.id}', extra: dream),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 108,
                child: Hero(
                  tag: HeroTags.dream(dream.id),
                  child: major == null
                      ? const AppImage(null)
                      : MajorImage(major: major, cacheWidth: 330),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dream.title ?? 'Untitled dream',
                        style: context.text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        major?.name ?? 'Unknown major',
                        style: context.text.bodySmall!.copyWith(
                          color: context.scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 14,
                            color: context.colors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text('$count', style: context.text.bodySmall),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: context.colors.muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              DateFormat('d MMM yyyy').format(dream.createdAt),
                              style: context.text.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.subtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
