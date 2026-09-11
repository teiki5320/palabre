import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/widgets/widgets.dart';
import 'quiz_engine.dart';
import 'quiz_models.dart';
import 'quiz_providers.dart';
import 'quiz_widgets.dart';
import 'swipe_card.dart';

/// Une affirmation par carte : on glisse, ou on touche un bouton. Jusqu'à
/// cinq affirmations « importantes pour moi », qui comptent double. Sur écran
/// large, la carte est à gauche et les commandes à droite.
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
      return BandScaffold(title: l10n.tabQuiz, children: [SoftCard(child: EmptyState(icon: Icons.checklist_outlined, title: l10n.quizNone))]);
    }
    final total = quiz.statements.length;
    final index = session.index.clamp(0, total - 1);
    final s = quiz.statements[index];
    final important = session.important.contains(s.id);
    final notifier = ref.read(quizSessionProvider.notifier);
    final wide = BandScaffold.isWide(context);
    final accent = themeColor(context, s.theme);

    void onAnswer(Answer a) {
      notifier.answer(s.id, a);
      if (index + 1 >= total) {
        context.pushReplacement(Routes.quizResult);
      } else {
        notifier.goTo(index + 1);
      }
    }

    Widget cardBody(Statement st) => Container(
          constraints: BoxConstraints(minHeight: wide ? 300 : 220),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (st.theme != null) ThemePill(st.theme!),
              const SizedBox(height: 14),
              Text(st.texte, style: PalabreType.question(t.ink).copyWith(fontSize: wide ? 24 : 20)),
              const SizedBox(height: 6),
            ],
          ),
        );

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        if (index + 2 < total)
          Positioned.fill(top: 14, bottom: -14, left: 12, right: 12, child: SoftCard(margin: EdgeInsets.zero, child: const SizedBox.expand())),
        if (index + 1 < total)
          Positioned.fill(top: 7, bottom: -7, left: 6, right: 6, child: SoftCard(margin: EdgeInsets.zero, child: const SizedBox.expand())),
        // Halo de la couleur du thème derrière la carte du dessus.
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(SoftCard.radius), boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 40, offset: const Offset(0, 14))])),
        ),
        SwipeCard(
          key: ValueKey('statement-card-${s.id}'),
          controller: _controller,
          onAnswer: onAnswer,
          agreeLabel: l10n.quizAgree,
          disagreeLabel: l10n.quizDisagree,
          child: _CardEntrance(
            key: ValueKey('entrance-${s.id}'),
            child: SoftCard(margin: EdgeInsets.zero, padding: EdgeInsets.zero, child: cardBody(s)),
          ),
        ),
      ],
    );

    final buttons = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundButton(key: const ValueKey('answer-desaccord'), icon: Icons.close_rounded, label: l10n.quizDisagree, color: t.ink, onTap: () => _controller.fling(Answer.desaccord)),
        _RoundButton(key: const ValueKey('answer-neutre'), icon: Icons.remove_rounded, label: l10n.quizNeutral, color: t.muted, onTap: () => _controller.fling(Answer.neutre)),
        _RoundButton(key: const ValueKey('answer-accord'), icon: Icons.check_rounded, label: l10n.quizAgree, color: t.primary, onTap: () => _controller.fling(Answer.accord)),
      ],
    );

    final importantRow = SoftCard(
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
    );

    final skip = TextButton(
      style: TextButton.styleFrom(foregroundColor: t.muted),
      onPressed: () => _controller.fling(Answer.passer),
      child: Text(l10n.quizSkipStatement),
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
      body: wide
          ? Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: stack),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        buttons,
                        const SizedBox(height: 26),
                        importantRow,
                        const SizedBox(height: 8),
                        skip,
                      ],
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [stack, const SizedBox(height: 26), buttons, const SizedBox(height: 18), importantRow, const SizedBox(height: 6), skip],
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
        PressScale(
          onTap: onTap,
          scale: 0.86,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: t.card, shape: BoxShape.circle, boxShadow: [t.cardShadow]),
            child: Icon(icon, size: 30, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.muted)),
      ],
    );
  }
}
