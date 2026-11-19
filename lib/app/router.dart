import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/user/user_profile.dart';
import '../features/diary/presentation/diary_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/signs/presentation/signs_screen.dart';
import '../features/tests/presentation/tests_screen.dart';
import '../features/today/presentation/today_screen.dart';
import 'shell.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const today = '/today';
  static const signs = '/signs';
  static const tests = '/tests';
  static const diary = '/diary';
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
            routes: [GoRoute(path: Routes.signs, builder: (_, _) => const SignsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.tests, builder: (_, _) => const TestsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.diary, builder: (_, _) => const DiaryScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});
