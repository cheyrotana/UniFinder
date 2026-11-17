import 'package:flutter/material.dart';

import '../../../Domain/model/Career/career_model.dart';
import '../../../Domain/model/Major/major_model.dart';
import '../../../Domain/model/University/university_model.dart';
import '../../../main.dart' show catalog;
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/cards.dart';
import '../../widgets/category_style.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';

enum ExploreTab { majors, careers, universities }

/// Browse everything in the app: majors (by category), careers and
/// universities, with one search box across them.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialTab = ExploreTab.majors});

  final ExploreTab initialTab;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late ExploreTab _tab = widget.initialTab;
  String? _category;
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String text) =>
      _query.isEmpty || text.toLowerCase().contains(_query.toLowerCase());

  List<Major> get _majors => [
    for (final m in catalog.majors)
      if ((_category == null || m.categoryId == _category) &&
          (_matches(m.name) || m.keySkills.any(_matches)))
        m,
  ];

  List<Career> get _careers => [
    for (final c in catalog.careers)
      if (_matches(c.name) || (c.skills ?? const []).any(_matches)) c,
  ];

  List<University> get _universities => [
    for (final u in catalog.universities)
      if (_matches(u.name) || _matches(u.shortName ?? '')) u,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.sm,
              ),
              child: Text('Explore', style: context.text.headlineMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: switch (_tab) {
                    ExploreTab.majors => 'Search majors or skills',
                    ExploreTab.careers => 'Search careers or skills',
                    ExploreTab.universities => 'Search universities',
                  },
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                0,
              ),
              child: _Segmented(
                selected: _tab,
                onSelected: (t) => setState(() => _tab = t),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.emphasized,
              child: _tab == ExploreTab.majors
                  ? _CategoryChips(
                      selected: _category,
                      onSelected: (id) => setState(() => _category = id),
                    )
                  : const SizedBox(width: double.infinity, height: 8),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.medium,
                switchInCurve: AppMotion.emphasized,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: switch (_tab) {
                    ExploreTab.majors => _MajorGrid(majors: _majors),
                    ExploreTab.careers => _CareerGrid(careers: _careers),
                    ExploreTab.universities => _UniversityList(
                      universities: _universities,
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three-way switch with a sliding thumb.
class _Segmented extends StatelessWidget {
  const _Segmented({required this.selected, required this.onSelected});

  final ExploreTab selected;
  final ValueChanged<ExploreTab> onSelected;

  static const _labels = {
    ExploreTab.majors: (Icons.school_outlined, 'Majors'),
    ExploreTab.careers: (Icons.work_outline_rounded, 'Careers'),
    ExploreTab.universities: (Icons.account_balance_outlined, 'Universities'),
  };

  @override
  Widget build(BuildContext context) {
    final n = ExploreTab.values.length;
    final i = selected.index;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.field,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 320),
            curve: AppMotion.emphasized,
            alignment: Alignment(-1 + 2 * i / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final tab in ExploreTab.values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: tab == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelected(tab),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _labels[tab]!.$1,
                            size: 16,
                            color: tab == selected
                                ? context.scheme.primary
                                : context.colors.muted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: AnimatedDefaultTextStyle(
                              duration: AppMotion.short,
                              style: context.text.labelMedium!.copyWith(
                                color: tab == selected
                                    ? context.colors.ink
                                    : context.colors.muted,
                              ),
                              child: Text(
                                _labels[tab]!.$2,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                              ),
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

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget chip(String? id, String label, IconData? icon, Color color) {
      final on = selected == id;
      return ChoiceChip(
        selected: on,
        onSelected: (_) => onSelected(on ? null : id),
        avatar: icon == null
            ? null
            : Icon(icon, size: 16, color: on ? Colors.white : color),
        label: Text(label),
        selectedColor: color,
        labelStyle: context.text.labelMedium!.copyWith(
          color: on ? Colors.white : context.colors.ink,
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: 10,
        ),
        children: [
          chip(null, 'All', null, context.scheme.primary),
          for (final c in catalog.categories) ...[
            const SizedBox(width: 6),
            Builder(
              builder: (context) {
                final style = CategoryStyle.of(c.id);
                return chip(c.id, style.short, style.icon, style.color);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment(0, -0.5),
    child: EmptyState(
      icon: Icons.search_off_rounded,
      title: 'Nothing found',
      message: 'Try another word or category.',
    ),
  );
}

class _MajorGrid extends StatelessWidget {
  const _MajorGrid({required this.majors});

  final List<Major> majors;

  @override
  Widget build(BuildContext context) {
    if (majors.isEmpty) return const _NoResults();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        bottom + AppSpacing.lg,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.82,
      ),
      itemCount: majors.length,
      itemBuilder: (context, i) => Entrance(
        key: ValueKey(majors[i].id),
        index: i,
        child: MajorTile(major: majors[i]),
      ),
    );
  }
}

class _CareerGrid extends StatelessWidget {
  const _CareerGrid({required this.careers});

  final List<Career> careers;

  @override
  Widget build(BuildContext context) {
    if (careers.isEmpty) return const _NoResults();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        bottom + AppSpacing.lg,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisExtent: CareerCard.height,
      ),
      itemCount: careers.length,
      itemBuilder: (context, i) => Entrance(
        key: ValueKey(careers[i].id),
        index: i,
        child: CareerCard(career: careers[i]),
      ),
    );
  }
}

class _UniversityList extends StatelessWidget {
  const _UniversityList({required this.universities});

  final List<University> universities;

  @override
  Widget build(BuildContext context) {
    if (universities.isEmpty) return const _NoResults();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        bottom + AppSpacing.lg,
      ),
      itemCount: universities.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, i) {
        final u = universities[i];
        final majors = catalog.offeringsAt(u.id ?? '').length;
        return Entrance(
          key: ValueKey(u.id),
          index: i,
          child: UniversityRow(
            university: u,
            subtitle: '${u.type} · est. ${u.establishedYear} · $majors majors',
          ),
        );
      },
    );
  }
}
