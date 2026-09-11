import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/profile/profile.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/poll/poll_detail_screen.dart';
import '../features/poll/poll_tab.dart';
import '../features/quiz/quiz_result_screen.dart';
import '../features/quiz/quiz_run_screen.dart';
import '../features/quiz/quiz_tab.dart';
import '../features/reference/assembly_tab.dart';
import '../features/reference/government_tab.dart';
import '../features/reference/party_screen.dart';
import '../features/reference/person_screen.dart';
import '../features/settings/settings_screen.dart';
import 'shell.dart';

class Routes {
  static const onboarding = '/bienvenue';
  static const question = '/question';
  static const quiz = '/test';
  static const quizRun = '/test/repondre';
  static const quizResult = '/test/resultat';
  static const government = '/gouvernement';
  static const assembly = '/assemblee';
  static const settings = '/parametres';
  static String poll(int id) => '/question/$id';
  static String person(int id) => '/personne/$id';
  static String party(int id) => '/parti/$id';
}

/// Fondu croisé avec léger glissement pour les écrans poussés.
CustomTransitionPage<void> fadePage(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved), child: child),
        );
      },
    );

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingDone = ref.watch(onboardingDoneProvider);
  return GoRouter(
    initialLocation: Routes.question,
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!onboardingDone && !atOnboarding) return Routes.onboarding;
      if (onboardingDone && atOnboarding) return Routes.question;
      return null;
    },
    routes: [
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.settings, pageBuilder: (_, s) => fadePage(s, const SettingsScreen())),
      GoRoute(path: '/personne/:id', pageBuilder: (_, s) => fadePage(s, PersonScreen(personId: int.parse(s.pathParameters['id']!)))),
      GoRoute(path: '/parti/:id', pageBuilder: (_, s) => fadePage(s, PartyScreen(orgId: int.parse(s.pathParameters['id']!)))),
      GoRoute(path: Routes.quizRun, pageBuilder: (_, s) => fadePage(s, const QuizRunScreen())),
      GoRoute(path: Routes.quizResult, pageBuilder: (_, s) => fadePage(s, const QuizResultScreen())),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.question,
              builder: (_, _) => const PollTab(),
              routes: [
                GoRoute(path: ':id', pageBuilder: (_, s) => fadePage(s, PollDetailScreen(pollId: int.parse(s.pathParameters['id']!)))),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.quiz, builder: (_, _) => const QuizTab())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.government, builder: (_, _) => const GovernmentTab())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.assembly, builder: (_, _) => const AssemblyTab())]),
        ],
      ),
    ],
  );
});

/// Bouton « paramètres » commun aux quatre onglets.
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.tune),
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        onPressed: () => context.push(Routes.settings),
      );
}
