import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../main.dart' show catalog;
import '../../../Domain/model/University/university_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_image.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';
import '../../widgets/photo_header.dart';

/// A university: its campus photo, facts, about, contact, and every major
/// it teaches with price and length.
class UniversityScreen extends StatelessWidget {
  const UniversityScreen({super.key, required this.universityId});

  final String universityId;

  @override
  Widget build(BuildContext context) {
    final u = catalog.university(universityId);
    if (u == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: EmptyState(
            icon: Icons.account_balance_outlined,
            title: 'University not found',
          ),
        ),
      );
    }
    final offerings = catalog.offeringsAt(universityId);

    return PhotoHeaderScaffold(
      heroTag: HeroTags.university(universityId),
      photo: UniversityCover(university: u, animated: true),
      sceneAccent: AppImage.isScene(u.coverImagePath)
          ? UniversityCover.accentOf(u)
          : null,
      title: u.shortName ?? u.name,
      subtitle: u.shortName == null ? null : u.name,
      badge: UniversityLogo(university: u, size: 56, hero: true),
      expandedHeight: 300,
      slivers: [
        HeaderSection(
          top: AppSpacing.lg,
          child: Entrance(
            child: StatRow(
              stats: [
                (Icons.history_edu_outlined, '${u.establishedYear}', 'Founded'),
                (Icons.account_balance_outlined, u.type, 'Type'),
                (Icons.school_outlined, '${offerings.length}', 'Majors'),
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
                  ExpandableText(u.description),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, row) in _contacts(u).indexed)
                          _ContactRow(
                            icon: row.$1,
                            label: row.$2,
                            value: row.$3,
                            url: row.$4,
                            last: i == _contacts(u).length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        HeaderSection(
          child: SectionHeader(
            title: 'Majors offered',
            subtitle: '${offerings.length} programs · price per year',
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
              return MajorRow(
                major: o.major,
                subtitle: '${o.degreeType} · ${o.durationYears} years',
                onTap: () => context.push('/major/${o.major.id}'),
                trailing: Text(
                  '\$${o.universityMajor.pricePerYear.round()}',
                  style: context.text.titleSmall,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.url,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? url;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: url == null ? null : () => launchUrl(Uri.parse(url!)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: context.colors.hairline)),
        ),
        child: Row(
          children: [
            IconTile(icon: icon, size: 34),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.text.bodySmall),
                  Text(
                    value,
                    style: context.text.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (url != null)
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: context.colors.subtle,
              ),
          ],
        ),
      ),
    );
  }
}

/// Contact rows that have a value (icon, label, value, link).
List<(IconData, String, String, String?)> _contacts(University u) => [
  if (u.location.isNotEmpty)
    (Icons.location_on_outlined, 'Location', u.location, null),
  if (u.website.isNotEmpty)
    (Icons.language_rounded, 'Website', u.website, u.website),
  if (u.email.isNotEmpty)
    (Icons.mail_outline_rounded, 'Email', u.email, 'mailto:${u.email}'),
  if (u.phone.isNotEmpty)
    (Icons.call_outlined, 'Phone', u.phone, 'tel:${u.phone.replaceAll(' ', '')}'),
];
