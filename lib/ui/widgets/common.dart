import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// A white (dark: slate) card with a hairline border, HRM style.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  /// Clip the content to the corners (cards with a photo on top).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.colors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? context.colors.hairline),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap, child: card);
  }
}

/// A section title with an optional subtitle and a "See all"-type action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: context.text.labelMedium,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action!),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A rounded square holding an icon on a soft tint.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.color,
    this.size = 40,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.scheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: context.isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: tint, size: size * 0.52),
    );
  }
}

/// A small pill: skills, degree types, match scores.
class Tag extends StatelessWidget {
  const Tag(
    this.label, {
    super.key,
    this.icon,
    this.color,
    this.filled = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final tint = color;
    final bg = filled
        ? (tint ?? context.scheme.primary)
        : tint?.withValues(alpha: context.isDark ? 0.18 : 0.10) ??
              context.colors.field;
    final fg = filled ? Colors.white : (tint ?? context.colors.ink);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// A round frosted button over photos (back, compare, share).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.onLight = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// On a light picture (a scene): a card-coloured disc with an ink icon.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final button = Pressable(
      onTap: onPressed,
      scale: 0.9,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onLight
                  ? context.colors.card.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.28),
              border: Border.all(
                color: onLight
                    ? context.colors.hairline
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              icon,
              color: onLight ? context.colors.ink : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// The back button for hero-photo headers.
class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key});

  @override
  Widget build(BuildContext context) => GlassIconButton(
    icon: Icons.arrow_back_rounded,
    tooltip: 'Back',
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

/// Centred illustration-less empty/error state.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTile(icon: icon, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: context.text.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              style: context.text.bodyMedium!.copyWith(
                color: context.colors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// A shaded strip over the bottom of a photo, so white text reads on it.
class PhotoScrim extends StatelessWidget {
  const PhotoScrim({super.key, this.strength = 0.7, this.top = false});

  final double strength;

  /// Also darken the top (for status bar and buttons).
  final bool top;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: top ? 0.35 : 0),
              Colors.transparent,
              Colors.black.withValues(alpha: strength),
            ],
            stops: const [0, 0.4, 1],
          ),
        ),
      ),
    );
  }
}
