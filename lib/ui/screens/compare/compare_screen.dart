import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../Domain/model/University/university_major.dart';
import '../../../Domain/model/University/university_model.dart';
import '../../../main.dart' show catalog;
import '../../../service/catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';

/// Two universities side by side for one major: cost (with bars), program
/// and contact.
class CompareScreen extends StatelessWidget {
  const CompareScreen({
    super.key,
    required this.majorId,
    required this.firstId,
    required this.secondId,
  });

  final String majorId;
  final String firstId;
  final String secondId;

  @override
  Widget build(BuildContext context) {
    final major = catalog.major(majorId);
    final a = catalog.university(firstId);
    final b = catalog.university(secondId);
    final oa = catalog.offering(firstId, majorId);
    final ob = catalog.offering(secondId, majorId);
    if (major == null || a == null || b == null || oa == null || ob == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: EmptyState(
            icon: Icons.compare_arrows_rounded,
            title: "Can't compare these",
            message: 'One of the universities no longer offers this major.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compare'),
            Text(major.name, style: context.text.bodySmall),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xs,
          AppSpacing.gutter,
          AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Entrance(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Head(university: a)),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.field,
                      shape: BoxShape.circle,
                    ),
                    child: Text('VS', style: context.text.labelSmall),
                  ),
                ),
                Expanded(child: _Head(university: b)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Entrance(
            index: 1,
            child: _Card(
              icon: Icons.payments_outlined,
              title: 'Cost',
              children: [
                _PriceBars(
                  label: 'Per year',
                  a: oa.pricePerYear,
                  b: ob.pricePerYear,
                ),
                const SizedBox(height: AppSpacing.lg),
                _PriceBars(
                  label: 'Whole program',
                  a: oa.pricePerYear * oa.durationYears,
                  b: ob.pricePerYear * ob.durationYears,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Entrance(
            index: 2,
            child: _Card(
              icon: Icons.school_outlined,
              title: 'Program',
              children: _rows(context, oa, ob, a, b),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Entrance(
            index: 3,
            child: _Card(
              icon: Icons.contact_page_outlined,
              title: 'Contact',
              children: [
                _Pair(label: 'Website', a: _host(a.website), b: _host(b.website)),
                _Pair(label: 'Phone', a: a.phone, b: b.phone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _host(String url) =>
      Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;

  List<Widget> _rows(
    BuildContext context,
    UniversityMajor oa,
    UniversityMajor ob,
    University a,
    University b,
  ) => [
    _Pair(label: 'Degree', a: oa.degree, b: ob.degree),
    _Pair(
      label: 'Duration',
      a: '${oa.durationYears} years',
      b: '${ob.durationYears} years',
    ),
    _Pair(label: 'Type', a: a.type, b: b.type),
    _Pair(
      label: 'Founded',
      a: '${a.establishedYear}',
      b: '${b.establishedYear}',
    ),
  ];
}

class _Head extends StatelessWidget {
  const _Head({required this.university});

  final University university;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/university/${university.id}'),
      child: Column(
        children: [
          UniversityLogo(university: university, size: 72),
          const SizedBox(height: AppSpacing.xs),
          Text(
            university.shortName ?? university.name,
            style: context.text.titleSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            university.name,
            style: context.text.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(icon: icon, size: 32),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: context.text.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

/// A row of two values with the label between them.
class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.a, required this.b});

  final String label;
  final String a;
  final String b;

  @override
  Widget build(BuildContext context) {
    final same = a == b;
    Widget value(String v, TextAlign align) => Expanded(
      child: Text(
        v,
        textAlign: align,
        style: context.text.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          value(a, TextAlign.left),
          Container(
            width: 92,
            alignment: Alignment.center,
            child: Text(
              same ? '$label  =' : label,
              style: context.text.bodySmall,
            ),
          ),
          value(b, TextAlign.right),
        ],
      ),
    );
  }
}

/// Two bars scaled to the dearer price, the cheaper one in green.
class _PriceBars extends StatelessWidget {
  const _PriceBars({required this.label, required this.a, required this.b});

  final String label;
  final double a;
  final double b;

  @override
  Widget build(BuildContext context) {
    final max = math.max(a, b);
    final diff = (a - b).abs();
    Widget bar(double v, {required bool alignEnd}) {
      final cheaper = v < (v == a ? b : a);
      final color = cheaper ? context.colors.success : context.colors.warning;
      return Expanded(
        child: Column(
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              formatUsd(v),
              style: context.text.titleMedium!.copyWith(
                color: a == b ? context.colors.ink : color,
              ),
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: max == 0 ? 0 : v / max),
              duration: const Duration(milliseconds: 900),
              curve: AppMotion.emphasized,
              builder: (context, t, _) => Align(
                alignment: alignEnd
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: t.clamp(0.02, 1),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: a == b ? context.scheme.primary : color,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: context.text.bodySmall),
            const Spacer(),
            if (diff > 0)
              Tag(
                '${formatUsd(diff)} difference',
                color: context.colors.success,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            bar(a, alignEnd: false),
            const SizedBox(width: AppSpacing.md),
            bar(b, alignEnd: true),
          ],
        ),
      ],
    );
  }
}
