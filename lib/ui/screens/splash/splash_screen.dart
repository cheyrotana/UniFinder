import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../main.dart' show userService;
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';

/// The logo pops in while the saved user loads, then fades to Home (or to
/// onboarding on first launch).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final minimum = Future<void>.delayed(const Duration(milliseconds: 1500));
    final user = await userService.getUser();
    await minimum;
    if (!mounted) return;
    context.go(user != null ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
    );
    final tagline = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.45, 1, curve: AppMotion.emphasized),
    );
    return Scaffold(
      backgroundColor: context.colors.card,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _c,
                curve: const Interval(0, 0.4),
              ),
              child: ScaleTransition(
                scale: Tween(begin: 0.7, end: 1.0).animate(logo),
                child: _Logo(dark: context.isDark),
              ),
            ),
            FadeTransition(
              opacity: tagline,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.6),
                  end: Offset.zero,
                ).animate(tagline),
                child: Text(
                  'Find your major. Plan your future.',
                  style: context.text.bodyMedium!.copyWith(
                    color: context.colors.muted,
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

/// The UniFinder logo (the bitmap has a white background, so dark mode
/// gets a white rounded card behind it).
class _Logo extends StatelessWidget {
  const _Logo({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset('assets/logo/test.png', width: 260);
    if (!dark) return image;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(color: Colors.white, child: image),
      ),
    );
  }
}
