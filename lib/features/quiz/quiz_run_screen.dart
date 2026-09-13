import 'dart:math' as math;

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

/// Une affirmation par carte : on glisse à droite (d'accord), à gauche (pas
/// d'accord) ou vers le haut (neutre). Rien d'autre à l'écran. Style affiche :
/// carte bordée, ombre dure.
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
      return BandScaffold(color: t.quiz, onColor: t.onQuiz, title: l10n.tabQuiz, children: [SoftCard(child: EmptyState(icon: Icons.checklist_outlined, title: l10n.quizNone))]);
    }
    final total = quiz.statements.length;
    final index = session.index.clamp(0, total - 1);
    final s = quiz.statements[index];
    final notifier = ref.read(quizSessionProvider.notifier);
    final wide = BandScaffold.isWide(context);

    void onAnswer(Answer a) {
      notifier.answer(s.id, a);
      if (index + 1 >= total) {
        context.pushReplacement(Routes.quizResult);
      } else {
        notifier.goTo(index + 1);
      }
    }

    Widget backCard() => Transform.translate(
          offset: const Offset(0, 10),
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Opacity(
              opacity: t.isDark ? 0.6 : 1,
              child: Container(
                decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: t.border, width: 2)),
              ),
            ),
          ),
        );

    Widget frontCard(Statement st, double cardHeight) => Container(
          height: cardHeight,
          decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: t.border, width: 2)),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [if (st.theme != null) Pill(label: st.theme!, color: t.quiz)]),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Text(st.texte, style: PalabreType.question(t.ink).copyWith(fontSize: wide ? 30 : (st.texte.length > 120 ? 23 : st.texte.length > 80 ? 26 : 28))),
                ),
              ),
            ],
          ),
        );

    // La carte du dessus donne sa taille à la pile ; la carte arrière la suit.
    Widget stack(double cardHeight) => Stack(
      clipBehavior: Clip.none,
      children: [
        if (index + 1 < total) Positioned.fill(child: backCard()),
        SwipeCard(
          key: ValueKey('statement-card-${s.id}'),
          controller: _controller,
          onAnswer: onAnswer,
          agreeLabel: l10n.quizAgree,
          disagreeLabel: l10n.quizDisagree,
          neutralLabel: l10n.quizNeutral,
          stampColor: t.quiz,
          onStampColor: t.onQuiz,
          child: _CardEntrance(
            key: ValueKey('entrance-${s.id}'),
            child: HardShadow(offset: 6, radius: 22, color: t.isDark ? t.quiz : t.hardShadow, child: frontCard(s, cardHeight)),
          ),
        ),
      ],
    );

    final counter = Text.rich(
      TextSpan(
        style: TextStyle(fontFamily: PalabreType.display, fontSize: 15, fontWeight: FontWeight.w800, color: t.ink),
        children: [
          TextSpan(text: '${index + 1}'),
          TextSpan(text: '/$total', style: TextStyle(color: t.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return BandScaffold(
      color: t.quiz,
      onColor: t.onQuiz,
      compact: true,
      title: l10n.tabQuiz,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        tooltip: l10n.close,
        onPressed: () => index > 0 ? notifier.goTo(index - 1) : context.pop(),
      ),
      actions: [counter],
      control: Row(
        children: [
          Expanded(flex: index + 1, child: Container(height: 5, decoration: BoxDecoration(color: t.quiz, borderRadius: BorderRadius.circular(3)))),
          if (index + 1 < total) ...[
            const SizedBox(width: 4),
            Expanded(flex: total - index - 1, child: Container(height: 5, decoration: BoxDecoration(color: t.track, borderRadius: BorderRadius.circular(3)))),
          ],
        ],
      ),
      // Pas de liste défilante : le geste vers le haut doit rester à la carte.
      // Rien d'autre à l'écran : la carte, centrée, prend toute la place.
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 760 : double.infinity),
          child: LayoutBuilder(builder: (context, c) {
            final cardHeight = (c.maxHeight - 56).clamp(300.0, 700.0);
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 32 : BandScaffold.side),
                child: SizedBox(height: cardHeight, child: stack(cardHeight)),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// La carte suivante arrive par un ressort depuis le bas.
class _CardEntrance extends StatelessWidget {
  const _CardEntrance({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 24),
        child: Transform.scale(scale: 0.96 + 0.04 * v, child: Opacity(opacity: v.clamp(0, 1), child: child)),
      ),
      child: child,
    );
  }
}
