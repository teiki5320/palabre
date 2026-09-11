import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/widgets/widgets.dart';
import 'quiz_engine.dart';
import 'quiz_models.dart';
import 'quiz_providers.dart';

/// Une affirmation à la fois : d'accord, pas d'accord, neutre, passer.
/// Jusqu'à cinq affirmations « importantes pour moi », qui comptent double.
class QuizRunScreen extends ConsumerWidget {
  const QuizRunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final quiz = ref.watch(currentQuizProvider).value;
    final session = ref.watch(quizSessionProvider);
    if (quiz == null || quiz.statements.isEmpty) {
      return Scaffold(appBar: AppBar(), body: ErrorRetry(message: l10n.quizNone));
    }
    final total = quiz.statements.length;
    final index = session.index.clamp(0, total - 1);
    final s = quiz.statements[index];
    final answer = session.answers[s.id];
    final important = session.important.contains(s.id);
    final notifier = ref.read(quizSessionProvider.notifier);

    void next() {
      if (index + 1 >= total) {
        context.pushReplacement(Routes.quizResult);
      } else {
        notifier.goTo(index + 1);
      }
    }

    void choose(Answer a) {
      notifier.answer(s.id, a);
      next();
    }

    Widget answerButton(Answer a, String label, IconData icon) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: answer == a ? scheme.primary : scheme.onSurface,
              side: BorderSide(color: answer == a ? scheme.primary : scheme.outlineVariant, width: answer == a ? 1 : 0.5),
            ),
            onPressed: () => choose(a),
            icon: Icon(icon, size: 20),
            label: Text(label),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quizProgress(index + 1, total)),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          if (index > 0) IconButton(icon: const Icon(Icons.chevron_left), tooltip: l10n.back, onPressed: () => notifier.goTo(index - 1)),
          if (answer != null && index + 1 < total) IconButton(icon: const Icon(Icons.chevron_right), tooltip: l10n.next, onPressed: next),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (index + 1) / total, minHeight: 2, backgroundColor: scheme.outlineVariant.withValues(alpha: 0.4)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                if (s.theme != null)
                  Text(s.theme!.toUpperCase(), style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(s.texte, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.35)),
                const SizedBox(height: 28),
                answerButton(Answer.accord, l10n.quizAgree, Icons.thumb_up_outlined),
                answerButton(Answer.desaccord, l10n.quizDisagree, Icons.thumb_down_outlined),
                answerButton(Answer.neutre, l10n.quizNeutral, Icons.remove_circle_outline),
                answerButton(Answer.passer, l10n.quizSkip, Icons.skip_next_outlined),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: important,
                  title: Text(l10n.quizImportant),
                  subtitle: Text(l10n.quizImportantCount(session.important.length, QuizEngine.maxImportant), style: const TextStyle(fontSize: 12)),
                  onChanged: (_) {
                    if (!notifier.toggleImportant(s.id)) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.quizImportantLimit(QuizEngine.maxImportant))));
                    }
                  },
                ),
              ],
            ),
          ),
          if (index + 1 >= total && answer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: FilledButton(onPressed: () => context.pushReplacement(Routes.quizResult), child: Text(l10n.quizSeeResults)),
            ),
        ],
      ),
    );
  }
}
