import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/country/country_models.dart';
import '../../core/country/country_providers.dart';
import '../../core/net/cached_notifier.dart';
import '../../core/widgets/widgets.dart';
import 'quiz_providers.dart';

/// Onglet 2 : le principe, la méthode, et le bouton pour commencer.
class QuizTab extends ConsumerWidget {
  const QuizTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final code = ref.watch(selectedCountryProvider);
    final quiz = ref.watch(quizProvider(code));
    final module = ref.watch(moduleStateProvider(AppModule.quiz));
    final session = ref.watch(quizSessionProvider);

    Widget method(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabQuiz), actions: const [SettingsAction()]),
      body: module != null && !module.actif
          ? ListView(padding: const EdgeInsets.all(16), children: [
              NoticeBanner(text: l10n.moduleSuspended, icon: Icons.pause_circle_outline),
              if (module.motif != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(l10n.moduleSuspendedReason(module.motif!), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
            ])
          : quiz.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => ErrorRetry(message: e is NotConfiguredException ? l10n.notConfigured : l10n.errorGeneric, onRetry: () => ref.invalidate(quizProvider(code))),
              data: (q) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(l10n.quizIntro, style: const TextStyle(fontSize: 17, height: 1.4)),
                  const SizedBox(height: 16),
                  method(Icons.balance_outlined, l10n.quizMethod1),
                  method(Icons.block_outlined, l10n.quizMethod2),
                  method(Icons.phone_android_outlined, l10n.quizMethod3),
                  const SizedBox(height: 24),
                  if (q == null)
                    Text(l10n.quizNone, style: TextStyle(color: scheme.onSurfaceVariant))
                  else ...[
                    Text('${q.titre} · ${l10n.quizStatements(q.statements.length)} · ${l10n.quizParties(q.parties.length)}',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    if (session.quizId == q.id && session.started) ...[
                      Text(l10n.quizAnswered(session.answers.length, q.statements.length), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => context.push(session.answers.length >= q.statements.length ? Routes.quizResult : Routes.quizRun),
                        child: Text(session.answers.length >= q.statements.length ? l10n.quizSeeResults : l10n.quizResume),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(quizSessionProvider.notifier).reset();
                          context.push(Routes.quizRun);
                        },
                        child: Text(l10n.quizRestart),
                      ),
                    ] else
                      FilledButton(
                        onPressed: () {
                          ref.read(quizSessionProvider.notifier).start(q.id);
                          context.push(Routes.quizRun);
                        },
                        child: Text(l10n.start),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
