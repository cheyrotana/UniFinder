import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';

class _Page {
  const _Page(this.image, this.title, this.body, this.color);

  final String image;
  final String title;
  final String body;
  final Color color;
}

const _pages = [
  _Page(
    'assets/panels/student.png',
    'Welcome to UniFinder',
    'Find the university, major and career that fit you best, all offline.',
    Color(0xFF2563EB),
  ),
  _Page(
    'assets/panels/selection.png',
    'Discover your path',
    'Answer 10 quick questions about what you enjoy and get majors matched to you.',
    Color(0xFF7C3AED),
  ),
  _Page(
    'assets/panels/compared.png',
    'Compare universities',
    'See where each major is taught in Phnom Penh, what it costs, and compare side by side.',
    Color(0xFF0E9F6E),
  ),
  _Page(
    'assets/panels/recommended.png',
    'Plan your career',
    'Link the majors you love to real jobs, salaries and the skills they need.',
    Color(0xFFE11D48),
  ),
];

/// Four illustrated pages; the illustration drifts with the swipe
/// (parallax) and the backdrop blob takes each page's colour.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _last => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_last) {
      context.go('/name');
    } else {
      _controller.nextPage(
        duration: AppMotion.page * 1.5,
        curve: AppMotion.emphasized,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _pages[_index].color;
    return Scaffold(
      backgroundColor: context.colors.card,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _last ? 0 : 1,
                duration: AppMotion.medium,
                child: TextButton(
                  onPressed: _last ? null : () => context.go('/name'),
                  child: Text(
                    'Skip',
                    style: TextStyle(color: context.colors.muted),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final page = _controller.hasClients &&
                            _controller.position.haveDimensions
                        ? _controller.page ?? 0
                        : 0.0;
                    return _PageView(page: _pages[i], delta: i - page);
                  },
                ),
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
                spacing: 6,
                activeDotColor: color,
                dotColor: context.colors.hairline,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.xl,
                AppSpacing.gutter,
                AppSpacing.md,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: _next,
                  child: AnimatedSwitcher(
                    duration: AppMotion.medium,
                    child: Text(
                      _last ? 'Get started' : 'Next',
                      key: ValueKey(_last),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page, required this.delta});

  final _Page page;

  /// This page's distance from the current scroll position (-1…1).
  final double delta;

  @override
  Widget build(BuildContext context) {
    final fade = (1 - delta.abs()).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.8 + 0.2 * fade,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: page.color.withValues(
                        alpha: context.isDark ? 0.18 : 0.09,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  // The picture lags behind the swipe.
                  offset: Offset(delta * 120, 0),
                  child: _Illustration(page.image),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(delta * 40, 0),
              child: Column(
                children: [
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: context.text.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    page.body,
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge!.copyWith(
                      color: context.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// The panels are drawn on white; in dark mode they sit on a white card.
class _Illustration extends StatelessWidget {
  const _Illustration(this.path);

  final String path;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(path, height: 230, fit: BoxFit.contain);
    if (!context.isDark) return image;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: image,
    );
  }
}
