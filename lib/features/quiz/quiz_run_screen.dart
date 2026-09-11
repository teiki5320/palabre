import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/widgets/widgets.dart';
import 'quiz_engine.dart';
import 'quiz_models.dart';
import 'quiz_providers.dart';
import 'swipe_card.dart';

/// Une affirmation par carte : on glisse, ou on touche un bouton. Jusqu'à
/// cinq affirmations « importantes pour moi », qui comptent double.
class QuizRunScreen extends ConsumerStatefulWidget {
  const QuizRunScreen({super.key});

  @override
  ConsumerState<QuizRunScreen> createState() => _QuizRunScreenState();
}

class _QuizRunScreenState extends ConsumerState<QuizRunScreen> {
  final _controller = SwipeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final quiz = ref.watch(currentQuizProvider).value;
    final session = ref.watch(quizSessionProvider);
    if (quiz == null || quiz.statements.isEmpty) {
      return BandScaffold(title: l10n.tabQuiz, children: [SoftCard(child: ErrorRetry(message: l10n.quizNone))]);
    }
    final total = quiz.statements.length;
    final index = session.index.clamp(0, total - 1);
    final s = quiz.statements[index];
    final important = session.important.contains(s.id);
    final notifier = ref.read(quizSessionProvider.notifier);

    void onAnswer(Answer a) {
      notifier.answer(s.id, a);
      if (index + 1 >= total) {
        context.pushReplacement(Routes.quizResult);
      } else {
        notifier.goTo(index + 1);
      }
    }

    Widget cardBody(Statement st) => Container(
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (st.theme != null) Pill(label: st.theme!),
              const SizedBox(height: 14),
              Text(st.texte, style: PalabreType.question(t.ink).copyWith(fontSize: 20)),
              const SizedBox(height: 6),
            ],
          ),
        );

    return BandScaffold(
      title: l10n.tabQuiz,
      eyebrow: l10n.quizSwipeHint,
      leading: IconButton(icon: const Icon(Icons.close), tooltip: l10n.close, onPressed: () => context.pop()),
      actions: [
        if (index > 0) IconButton(icon: const Icon(Icons.chevron_left), tooltip: l10n.back, onPressed: () => notifier.goTo(index - 1)),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 4),
          child: Pill(label: l10n.quizProgress(index + 1, total), onBand: true),
        ),
      ],
      control: PercentBar(fraction: (index + 1) / total, color: t.onPrimary, track: t.onPrimary.withValues(alpha: 0.25), height: 4),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Stack(
            children: [
              if (index + 2 < total)
                Positioned.fill(
                  top: 14,
                  left: 12,
                  right: 12,
                  child: SoftCard(margin: EdgeInsets.zero, child: const SizedBox.expand()),
                ),
              if (index + 1 < total)
                Positioned.fill(
                  top: 7,
                  left: 6,
                  right: 6,
                  child: SoftCard(margin: EdgeInsets.zero, child: const SizedBox.expand()),
                ),
              SwipeCard(
                key: ValueKey('statement-card-${s.id}'),
                controller: _controller,
                onAnswer: onAnswer,
                agreeLabel: l10n.quizAgree,
                disagreeLabel: l10n.quizDisagree,
                child: SoftCard(margin: EdgeInsets.zero, padding: EdgeInsets.zero, child: cardBody(s)),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(key: const ValueKey('answer-desaccord'), icon: Icons.close_rounded, label: l10n.quizDisagree, color: t.ink, onTap: () => _controller.fling(Answer.desaccord)),
              _RoundButton(key: const ValueKey('answer-neutre'), icon: Icons.remove_rounded, label: l10n.quizNeutral, color: t.muted, onTap: () => _controller.fling(Answer.neutre)),
              _RoundButton(key: const ValueKey('answer-accord'), icon: Icons.check_rounded, label: l10n.quizAgree, color: t.primary, onTap: () => _controller.fling(Answer.accord)),
            ],
          ),
          const SizedBox(height: 18),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.quizImportant, style: PalabreType.label(t.ink)),
                      Text(l10n.quizImportantCount(session.important.length, QuizEngine.maxImportant), style: PalabreType.note(t.muted)),
                    ],
                  ),
                ),
                Switch(
                  value: important,
                  onChanged: (_) {
                    if (!notifier.toggleImportant(s.id)) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.quizImportantLimit(QuizEngine.maxImportant))));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: t.muted),
            onPressed: () => _controller.fling(Answer.passer),
            child: Text(l10n.quizSkipStatement),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: t.card,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [t.cardShadow]),
              child: Icon(icon, size: 30, color: color),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.muted)),
      ],
    );
  }
}
