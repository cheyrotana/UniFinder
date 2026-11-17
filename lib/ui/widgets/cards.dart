import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../Domain/model/Career/career_model.dart';
import '../../Domain/model/Major/major_model.dart';
import '../../Domain/model/University/university_model.dart';
import '../../main.dart' show catalog;
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_image.dart';
import 'category_style.dart';
import 'common.dart';
import 'pressable.dart';

/// A major as a photo tile (Explore grid, related majors): the photo with
/// the name over it, category and number of universities.
class MajorTile extends StatelessWidget {
  const MajorTile({super.key, required this.major, this.onTap});

  final Major major;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(major.categoryId);
    final count = catalog.universityCount(major.id ?? '');
    return Pressable(
      onTap: onTap ?? () => context.push('/major/${major.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.colors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: HeroTags.major(major.id),
                    child: MajorImage(major: major, cacheWidth: 500),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Tag(
                      style.short,
                      icon: style.icon,
                      filled: true,
                      color: style.color,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: SizedBox(
                height: 58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      major.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall!.copyWith(height: 1.2),
                    ),
                    const Spacer(),
                    Text(
                      count == 0
                          ? 'Not offered yet'
                          : '$count ${count == 1 ? 'university' : 'universities'}',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A major as a list row: thumbnail, name, a line of meta, chevron.
class MajorRow extends StatelessWidget {
  const MajorRow({
    super.key,
    required this.major,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.hero = true,
  });

  final Major major;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox.square(
        dimension: 56,
        child: MajorImage(major: major, cacheWidth: 200),
      ),
    );
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap ?? () => context.push('/major/${major.id}'),
      child: Row(
        children: [
          hero ? Hero(tag: HeroTags.major(major.id), child: thumb) : thumb,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  major.name,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? catalog.tuitionRange(major.id ?? '') ?? '',
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right_rounded, color: context.colors.subtle),
        ],
      ),
    );
  }
}

/// A career as a card: photo on top, name, one-liner and salary.
class CareerCard extends StatelessWidget {
  const CareerCard({super.key, required this.career, this.width});

  static const imageHeight = 120.0;

  /// The card's full height: lists and grids size their rows with it.
  static const height = 236.0;

  final Career career;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.zero,
        clip: true,
        onTap: () => context.push('/career/${career.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: CareerCard.imageHeight,
              width: double.infinity,
              child: Hero(
                tag: HeroTags.career(career.id),
                child: CareerImage(career: career, cacheWidth: 600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    career.name,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    career.shortDescription ?? '',
                    style: context.text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (career.salaryRange != null) ...[
                    const SizedBox(height: 8),
                    Tag(
                      career.salaryRange!,
                      icon: Icons.payments_outlined,
                      color: context.colors.success,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A university as a list row: logo, name, type · location, and an
/// optional trailing (a price).
class UniversityRow extends StatelessWidget {
  const UniversityRow({
    super.key,
    required this.university,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final University university;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap ?? () => context.push('/university/${university.id}'),
      child: Row(
        children: [
          UniversityLogo(university: university, size: 52, hero: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  university.shortName ?? university.name,
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? university.name,
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          trailing ??
              Icon(Icons.chevron_right_rounded, color: context.colors.subtle),
        ],
      ),
    );
  }
}

/// A university's logo on a white rounded square (logos are drawn for
/// white backgrounds, so this stays white in dark mode too).
class UniversityLogo extends StatelessWidget {
  const UniversityLogo({
    super.key,
    required this.university,
    this.size = 48,
    this.hero = false,
  });

  final University university;
  final double size;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: context.colors.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.16),
        child: university.logoPath.isEmpty
            ? _Monogram(university: university)
            : AppImage(
                university.logoPath,
                fit: BoxFit.contain,
                fallbackIcon: Icons.account_balance_outlined,
                cacheWidth: (size * 3).round(),
              ),
      ),
    );
    if (!hero) return logo;
    return Hero(tag: HeroTags.universityLogo(university.id), child: logo);
  }
}

/// A university without a logo: its short name on its colour.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.university});

  final University university;

  @override
  Widget build(BuildContext context) {
    final name = university.shortName ?? university.name;
    final label = name.length <= 5 ? name : name.substring(0, 1);
    return ColoredBox(
      color: UniversityCover.accentOf(university),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FittedBox(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}
