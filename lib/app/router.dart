import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/user/user_profile.dart';
import '../features/diary/presentation/diary_entry_screen.dart';
import '../features/diary/presentation/diary_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/signs/presentation/compat_screen.dart';
import '../features/signs/presentation/sign_profile_screen.dart';
import '../features/signs/presentation/signs_screen.dart';
import '../features/tests/data/tests_repository.dart';
import '../features/tests/presentation/magic_ball_screen.dart';
import '../features/tests/presentation/test_run_screen.dart';
import '../features/tests/presentation/tests_screen.dart';
import '../features/today/presentation/today_screen.dart';
import 'shell.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const today = '/today';
  static const signs = '/signs';
  static const compat = '/signs/compat';
  static const tests = '/tests';
  static const magicBall = '/tests/ball';
  static const diary = '/diary';
  static const diaryEntry = '/diary/entry';
  static const profile = '/profile';
}

/// Плавный переход без «шторок»: экраны проявляются поверх общего неба.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.today,
    redirect: (context, state) {
      final done = ref.read(userProfileProvider).onboardingDone;
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!done && !atOnboarding) return Routes.onboarding;
      if (done && atOnboarding) return Routes.today;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => _fadePage(state, const OnboardingScreen()),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => _fadePage(state, AppShell(navigationShell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.today, builder: (_, _) => const TodayScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.signs,
                builder: (_, _) => const SignsScreen(),
                routes: [
                  GoRoute(
                    path: 'compat',
                    builder: (_, state) => CompatScreen(
                      initialA: signFromName(state.uri.queryParameters['a']),
                      initialB: signFromName(state.uri.queryParameters['b']),
                    ),
                  ),
                  GoRoute(
                    path: ':sign',
                    redirect: (_, state) =>
                        signFromName(state.pathParameters['sign']) == null ? Routes.signs : null,
                    builder: (_, state) =>
                        SignProfileScreen(sign: signFromName(state.pathParameters['sign'])!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tests,
                builder: (_, _) => const TestsScreen(),
                routes: [
                  GoRoute(path: 'ball', builder: (_, _) => const MagicBallScreen()),
                  GoRoute(
                    path: ':test',
                    redirect: (_, state) =>
                        testById(state.pathParameters['test']) == null ? Routes.tests : null,
                    builder: (_, state) =>
                        TestRunScreen(test: testById(state.pathParameters['test'])!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.diary,
                builder: (_, _) => const DiaryScreen(),
                routes: [
                  GoRoute(
                    path: 'entry',
                    builder: (_, state) => DiaryEntryScreen(
                      entryId: state.uri.queryParameters['id'],
                      initialDate: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});
