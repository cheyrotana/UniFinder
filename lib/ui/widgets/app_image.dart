import 'package:flutter/material.dart';

import '../../Domain/model/Career/career_model.dart';
import '../../Domain/model/Major/major_model.dart';
import '../../Domain/model/University/university_model.dart';
import '../../main.dart' show catalog;
import '../theme/app_colors.dart';
import 'category_style.dart';
import 'illustration/app_illustration.dart';
import 'illustration/illustration_image.dart';

/// A bundled picture: a photo that fades in once decoded, or (for a `.svg`
/// path) a Storyset scene in the theme's colours on a soft tint of
/// [accent]. A missing file falls back to a soft gradient with
/// [fallbackIcon] (never the red error box).
///
/// Paths from the JSON may come without the `assets/` prefix (older data):
/// they're resolved here.
class AppImage extends StatelessWidget {
  const AppImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackColor,
    this.accent,
    this.alignment = Alignment.center,
    this.cacheWidth,
    this.animated = false,
  });

  final String? path;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color? fallbackColor;

  /// The colour a scene's accent takes, and its background's tint.
  final Color? accent;
  final Alignment alignment;

  /// Decode at this width (in physical pixels) for small thumbnails.
  final int? cacheWidth;

  /// Scenes only: let the people and plants move (detail headers).
  final bool animated;

  static String? resolve(String? path) {
    if (path == null || path.isEmpty) return null;
    return path.startsWith('assets/') ? path : 'assets/$path';
  }

  /// Whether [path] is a Storyset scene rather than a photo.
  static bool isScene(String? path) => path?.endsWith('.svg') ?? false;

  /// The soft background a scene sits on.
  static Color tintOf(BuildContext context, Color accent) => Color.alphaBlend(
    accent.withValues(alpha: context.isDark ? 0.16 : 0.10),
    context.colors.card,
  );

  @override
  Widget build(BuildContext context) {
    final resolved = resolve(path);
    final color = accent ?? fallbackColor ?? context.scheme.primary;
    final fallback = _Fallback(icon: fallbackIcon, color: color);
    if (resolved == null) return fallback;
    if (isScene(resolved)) {
      return SceneImage(resolved, accent: color, animated: animated);
    }
    return Image.asset(
      resolved,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => fallback,
      frameBuilder: (context, child, frame, sync) {
        if (sync) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }
}

/// A Storyset scene filling its box: a soft tint of [accent] with the
/// scene centred on it, still or [animated].
class SceneImage extends StatelessWidget {
  const SceneImage(
    this.asset, {
    super.key,
    required this.accent,
    this.animated = false,
  });

  final String asset;
  final Color accent;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppImage.tintOf(context, accent),
      child: LayoutBuilder(
        builder: (context, box) {
          final pad = box.biggest.shortestSide * 0.06;
          return Padding(
            padding: EdgeInsets.all(pad),
            child: animated
                ? Center(
                    child: AppIllustration(
                      asset,
                      height: box.maxHeight - pad * 2,
                      accent: accent,
                      intro: false,
                    ),
                  )
                : IllustrationImage(asset, accent: accent),
          );
        },
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.85),
            Color.lerp(color, Colors.black, 0.35)!,
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 36),
      ),
    );
  }
}

/// A major's picture in its category's colour.
class MajorImage extends StatelessWidget {
  const MajorImage({
    super.key,
    required this.major,
    this.cacheWidth,
    this.animated = false,
  });

  final Major major;
  final int? cacheWidth;
  final bool animated;

  static Color accentOf(Major major) =>
      CategoryStyle.of(major.categoryId).color;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(major.categoryId);
    return AppImage(
      major.imagePath,
      fallbackIcon: style.icon,
      accent: style.color,
      cacheWidth: cacheWidth,
      animated: animated,
    );
  }
}

/// A career's picture, in the colour of the field it belongs to (its
/// first major's category).
class CareerImage extends StatelessWidget {
  const CareerImage({
    super.key,
    required this.career,
    this.cacheWidth,
    this.animated = false,
  });

  final Career career;
  final int? cacheWidth;
  final bool animated;

  static Color accentOf(Career career) {
    final major = catalog.majorsForCareer(career.id ?? '').firstOrNull;
    return CategoryStyle.of(major?.categoryId).color;
  }

  @override
  Widget build(BuildContext context) => AppImage(
    career.imagePath,
    fallbackIcon: Icons.work_outline_rounded,
    accent: accentOf(career),
    cacheWidth: cacheWidth,
    animated: animated,
  );
}

/// A university's cover: its campus photo, or a campus scene.
class UniversityCover extends StatelessWidget {
  const UniversityCover({
    super.key,
    required this.university,
    this.cacheWidth,
    this.animated = false,
  });

  final University university;
  final int? cacheWidth;
  final bool animated;

  static const _palette = [
    Color(0xFF2563EB),
    Color(0xFF0E9F6E),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFD97706),
    Color(0xFF0891B2),
    Color(0xFFE11D48),
  ];

  /// A steady colour per university (monogram logo, scene accent).
  static Color accentOf(University u) =>
      _palette[(int.tryParse(u.id ?? '') ?? u.name.length) % _palette.length];

  @override
  Widget build(BuildContext context) => AppImage(
    university.coverImagePath,
    fallbackIcon: Icons.account_balance_outlined,
    accent: accentOf(university),
    cacheWidth: cacheWidth,
    animated: animated,
  );
}

/// Hero tags, in one place so the source and destination always match.
abstract final class HeroTags {
  static String major(String? id) => 'major-photo-$id';
  static String dream(String? id) => 'dream-photo-$id';
  static String career(String? id) => 'career-photo-$id';
  static String university(String? id) => 'university-cover-$id';
  static String universityLogo(String? id) => 'university-logo-$id';
}
