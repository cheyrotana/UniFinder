import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import 'app_image.dart';
import 'common.dart';

/// An action button in a [PhotoHeaderScaffold]'s bar.
class HeaderAction {
  const HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

/// A detail screen with a big photo on top (a [Hero], so it flies in from
/// the card that opened it). The photo stretches on overscroll and slides
/// away with a parallax as you scroll; once it's gone, the title fades into
/// the toolbar, the frosted buttons turn plain and the status bar icons
/// flip to match.
class PhotoHeaderScaffold extends StatefulWidget {
  const PhotoHeaderScaffold({
    super.key,
    required this.heroTag,
    required this.photo,
    required this.title,
    required this.slivers,
    this.overline,
    this.subtitle,
    this.actions = const [],
    this.bottomBar,
    this.expandedHeight = 320,
    this.badge,
    this.sceneAccent,
  });

  /// Set when [photo] is a Storyset scene in this colour: the header is
  /// then its soft tint, with the scene above an ink title (no photo scrim).
  final Color? sceneAccent;

  final Object heroTag;
  final Widget photo;
  final String title;
  final String? overline;
  final String? subtitle;

  /// Shown over the photo, above the title (a category tag, a logo).
  final Widget? badge;
  final List<HeaderAction> actions;
  final List<Widget> slivers;
  final Widget? bottomBar;
  final double expandedHeight;

  @override
  State<PhotoHeaderScaffold> createState() => _PhotoHeaderScaffoldState();
}

class _PhotoHeaderScaffoldState extends State<PhotoHeaderScaffold> {
  final _scroll = ScrollController();
  bool _collapsed = false;

  /// A scene sits above the title rather than behind it, so it needs room.
  double get _expandedHeight =>
      widget.expandedHeight + (widget.sceneAccent != null ? 110 : 0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final top = MediaQuery.paddingOf(context).top;
    final collapsed =
        _scroll.offset > _expandedHeight - kToolbarHeight - top - 24;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _button(IconData icon, String tooltip, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedSwitcher(
        duration: AppMotion.medium,
        child: _collapsed
            ? IconButton(
                key: const ValueKey('plain'),
                tooltip: tooltip,
                icon: Icon(icon),
                onPressed: onPressed,
              )
            : GlassIconButton(
                key: const ValueKey('glass'),
                onLight: widget.sceneAccent != null,
                icon: icon,
                tooltip: tooltip,
                onPressed: onPressed,
              ),
      ),
    );
  }

  Widget _titleBlock(BuildContext context, {required bool onPhoto}) {
    final strong = onPhoto ? Colors.white : context.colors.ink;
    final soft = onPhoto
        ? Colors.white.withValues(alpha: 0.85)
        : context.colors.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.badge != null) ...[
          widget.badge!,
          const SizedBox(height: AppSpacing.xs),
        ],
        if (widget.overline != null)
          Text(
            widget.overline!.toUpperCase(),
            style: context.text.labelSmall!.copyWith(
              color: soft,
              letterSpacing: 1.2,
            ),
          ),
        Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.headlineMedium!.copyWith(color: strong),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium!.copyWith(color: soft),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final scene = widget.sceneAccent != null;
    final overlay = ((_collapsed || scene) && !dark)
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: _expandedHeight,
            backgroundColor: context.colors.canvas,
            systemOverlayStyle: overlay.copyWith(
              statusBarColor: Colors.transparent,
            ),
            automaticallyImplyLeading: false,
            leadingWidth: 56,
            leading: canPop
                ? Center(
                    child: _button(
                      Icons.arrow_back_rounded,
                      'Back',
                      () => Navigator.of(context).maybePop(),
                    ),
                  )
                : null,
            title: AnimatedOpacity(
              opacity: _collapsed ? 1 : 0,
              duration: AppMotion.medium,
              child: AnimatedSlide(
                offset: _collapsed ? Offset.zero : const Offset(0, 0.4),
                duration: AppMotion.medium,
                curve: AppMotion.emphasized,
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            actions: [
              for (final a in widget.actions)
                Center(child: _button(a.icon, a.tooltip, a.onPressed)),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: scene
                  ? ColoredBox(
                      color: AppImage.tintOf(context, widget.sceneAccent!),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height:
                                MediaQuery.paddingOf(context).top +
                                kToolbarHeight -
                                AppSpacing.xs,
                          ),
                          Expanded(
                            child: Hero(
                              tag: widget.heroTag,
                              child: widget.photo,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.gutter,
                              AppSpacing.xs,
                              AppSpacing.gutter,
                              AppSpacing.lg,
                            ),
                            child: _titleBlock(context, onPhoto: false),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(tag: widget.heroTag, child: widget.photo),
                        const PhotoScrim(strength: 0.8, top: true),
                        Positioned(
                          left: AppSpacing.gutter,
                          right: AppSpacing.gutter,
                          bottom: AppSpacing.lg,
                          child: _titleBlock(context, onPhoto: true),
                        ),
                      ],
                    ),
            ),
          ),
          ...widget.slivers,
          SliverToBoxAdapter(
            child: SizedBox(
              height: widget.bottomBar == null
                  ? MediaQuery.paddingOf(context).bottom + AppSpacing.xxl
                  : AppSpacing.xl,
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomBar == null
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: context.colors.card,
                border: Border(top: BorderSide(color: context.colors.hairline)),
              ),
              child: widget.bottomBar,
            ),
    );
  }
}

/// Body padding for a [PhotoHeaderScaffold] section.
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key, required this.child, this.top = AppSpacing.xl});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.only(top: top),
    sliver: SliverToBoxAdapter(child: child),
  );
}

/// A row of small stat tiles under a header (universities, tuition, …).
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.stats});

  final List<(IconData, String, String)> stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        children: [
          for (final (i, (icon, value, label)) in stats.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: context.scheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: context.text.bodySmall!.copyWith(fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Text that shows [lines] lines with a "Read more" toggle that expands
/// smoothly.
class ExpandableText extends StatefulWidget {
  const ExpandableText(this.text, {super.key, this.lines = 3});

  final String text;
  final int lines;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyMedium!.copyWith(
      color: context.colors.muted,
      height: 1.6,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.lines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.emphasized,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: style,
                maxLines: _open ? null : widget.lines,
                overflow: _open ? null : TextOverflow.ellipsis,
              ),
            ),
            if (overflows || _open)
              GestureDetector(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _open ? 'Show less' : 'Read more',
                    style: context.text.labelMedium!.copyWith(
                      color: context.scheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
