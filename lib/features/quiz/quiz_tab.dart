import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
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
    final t = context.tokens;
    final code = ref.watch(selectedCountryProvider);
    final quiz = ref.watch(quizProvider(code));
    final module = ref.watch(moduleStateProvider(AppModule.quiz));
    final session = ref.watch(quizSessionProvider);
    final q = quiz.value;

    Widget method(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: t.card, shape: BoxShape.circle, border: Border.all(color: t.border, width: 2)),
                child: Icon(icon, size: 16, color: t.quiz),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: TextStyle(height: 1.4, color: t.ink))),
            ],
          ),
        );

    final suspended = module != null && !module.actif;
    List<Widget> children;
    if (suspended) {
      children = [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NoticeBanner(text: l10n.moduleSuspended, icon: Icons.pause_circle_outline),
              if (module.motif != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(l10n.moduleSuspendedReason(module.motif!), style: PalabreType.note(t.muted))),
            ],
          ),
        ),
      ];
    } else {
      children = quiz.when(
        loading: () => const [SoftCard(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))))],
        error: (e, _) => [
          SoftCard(child: ErrorRetry(message: e is NotConfiguredException ? l10n.notConfigured : l10n.errorGeneric, onRetry: () => ref.invalidate(quizProvider(code)))),
        ],
        data: (q) {
          final inProgress = q != null && session.quizId == q.id && session.started;
          final complete = inProgress && session.answers.length >= q.statements.length;
          return [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.quizIntro, style: PalabreType.question(t.ink).copyWith(fontSize: 17)),
                  const SizedBox(height: 12),
                  method(Icons.balance_outlined, l10n.quizMethod1),
                  method(Icons.block_outlined, l10n.quizMethod2),
                  method(Icons.phone_android_outlined, l10n.quizMethod3),
                  const SizedBox(height: 14),
                  if (q == null)
                    EmptyState(icon: Icons.checklist_outlined, title: l10n.quizNone)
                  else ...[
                    Text('${q.titre} · ${l10n.quizStatements(q.statements.length)} · ${l10n.quizParties(q.parties.length)}', style: PalabreType.note(t.muted)),
                    const SizedBox(height: 12),
                    if (inProgress && !complete) ...[
                      ActionButton(
                        label: '${l10n.quizResume} (${l10n.quizProgress(session.answers.length, q.statements.length)})',
                        onPressed: () => context.push(Routes.quizRun),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.read(quizSessionProvider.notifier).reset();
                          context.push(Routes.quizRun);
                        },
                        child: Text(l10n.quizRestart),
                      ),
                    ] else if (complete)
                      ActionButton(
                        label: l10n.quizRestart,
                        outlined: true,
                        onPressed: () {
                          ref.read(quizSessionProvider.notifier).reset();
                          context.push(Routes.quizRun);
                        },
                      )
                    else
                      ActionButton(
                        label: l10n.start,
                        onPressed: () {
                          ref.read(quizSessionProvider.notifier).start(q.id);
                          context.push(Routes.quizRun);
                        },
                      ),
                  ],
                ],
              ),
            ),
            if (complete)
              SoftCard(
                onTap: () => context.push(Routes.quizResult),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.border, width: 2)),
                      child: Icon(Icons.bar_chart_rounded, color: t.quiz),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.quizLastResult, style: PalabreType.cardTitle(t.ink)),
                          const SizedBox(height: 2),
                          Text(l10n.quizAnswered(session.answers.length, q.statements.length), style: PalabreType.note(t.muted)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: t.muted),
                  ],
                ),
              ),
          ];
        },
      );
    }

    return BandScaffold(
      color: t.quiz,
      onColor: t.onQuiz,
      brand: true,
      title: l10n.tabQuiz,
      eyebrow: q == null ? null : l10n.quizEstimate(q.statements.length),
      actions: const [SettingsAction()],
      children: children,
    );
  }
}
