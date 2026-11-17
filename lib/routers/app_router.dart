import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../Domain/model/Dream/dreams_model.dart';
import '../ui/screens/career/career_screen.dart';
import '../ui/screens/compare/compare_screen.dart';
import '../ui/screens/dream/dream_screen.dart';
import '../ui/screens/explore/explore_screen.dart';
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/major/major_screen.dart';
import '../ui/screens/onboarding/name_screen.dart';
import '../ui/screens/onboarding/onboarding_screen.dart';
import '../ui/screens/profile/profile_screen.dart';
import '../ui/screens/quiz/quiz_screen.dart';
import '../ui/screens/recommendation/recommendation_screen.dart';
import '../ui/screens/splash/splash_screen.dart';
import '../ui/screens/university/university_screen.dart';
import '../ui/shell/app_shell.dart';
import 'transitions.dart';

/// The app's routes.
///
/// - Launch flow (`/`, `/onboarding`, `/name`) fades.
/// - The three tabs (`/home`, `/explore`, `/profile`) live in a
///   [StatefulShellRoute]: each keeps its own stack and scroll position, and
///   switching cross-fades (see `AppShell`).
/// - Detail screens open by ID on the root navigator, over the tab bar, so
///   they work from anywhere (deep links, web refresh, dev tools) and their
///   photos fly in as heroes from the tab that opened them.
/// - The quiz is a modal flow: it rises from the bottom.
abstract final class AppRouter {
  /// The router of the running app (replaced on a dev-tools restart).
  static GoRouter? current;
  static GlobalKey<NavigatorState>? navigatorKey;
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static GoRouter create() {
    final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
    navigatorKey = rootKey;
    return current = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              fadePage(key: state.pageKey, child: const SplashScreen()),
        ),
        GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) =>
              fadePage(key: state.pageKey, child: const OnboardingScreen()),
        ),
        GoRoute(
          path: '/name',
          builder: (context, state) => const NameScreen(),
        ),
        GoRoute(
          path: '/quiz',
          pageBuilder: (context, state) =>
              bottomSlidePage(key: state.pageKey, child: const QuizScreen()),
        ),
        GoRoute(
          path: '/recommendation',
          pageBuilder: (context, state) => fadePage(
            key: state.pageKey,
            child: const RecommendationScreen(),
          ),
        ),
        StatefulShellRoute(
          builder: (context, state, shell) => AppShell(shell: shell),
          navigatorContainerBuilder: (context, shell, children) =>
              AnimatedBranchContainer(
                currentIndex: shell.currentIndex,
                children: children,
              ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/explore',
                  builder: (context, state) => ExploreScreen(
                    initialTab: ExploreTab.values.asNameMap()[
                        state.uri.queryParameters['tab']] ??
                        ExploreTab.majors,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/dream/:id',
          builder: (context, state) =>
DreamScreen(
            dreamId: state.pathParameters['id']!,
            dream: state.extra is Dream ? state.extra as Dream : null,
          ),
        ),
        GoRoute(
          path: '/major/:id',
          builder: (context, state) =>
              MajorScreen(majorId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/career/:id',
          builder: (context, state) =>
              CareerScreen(careerId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/university/:id',
          builder: (context, state) =>
              UniversityScreen(universityId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/compare',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return CompareScreen(
              majorId: q['major'] ?? '',
              firstId: q['a'] ?? '',
              secondId: q['b'] ?? '',
            );
          },
        ),
      ],
    );
  }
}
