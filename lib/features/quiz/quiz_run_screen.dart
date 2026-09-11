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

/// Une affirmation par carte : on glisse, ou on touche un bouton. Jusqu'à
/// cinq affirmations « importantes pour moi », qui comptent double. Style
/// affiche : carte bordée, ombre dure 6/6, quatre cercles de réponse.
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
    final important = session.important.contains(s.id);
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

    void toggleImportant() {
      if (!notifier.toggleImportant(s.id)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.quizImportantLimit(QuizEngine.maxImportant))));
      }
    }

    final cardHeight = wide ? 400.0 : 340.0;

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

    Widget frontCard(Statement st) => Container(
          decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: t.border, width: 2)),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [if (st.theme != null) Pill(label: st.theme!, color: t.quiz)]),
              const SizedBox(height: 16),
              Expanded(child: Text(st.texte, style: PalabreType.question(t.ink).copyWith(fontSize: wide ? 30 : 27))),
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line, width: 1.5))),
                child: Text(l10n.quizMethod2, style: TextStyle(fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w500, color: t.muted)),
              ),
            ],
          ),
        );

    final stack = SizedBox(
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          if (index + 1 < total) backCard(),
          Transform.translate(
            offset: const Offset(8, 0),
            child: Transform.rotate(
              angle: 2 * math.pi / 180,
              child: SwipeCard(
                key: ValueKey('statement-card-${s.id}'),
                controller: _controller,
                onAnswer: onAnswer,
                agreeLabel: l10n.quizAgree,
                disagreeLabel: l10n.quizDisagree,
                stampColor: t.quiz,
                onStampColor: t.onQuiz,
                child: _CardEntrance(
                  key: ValueKey('entrance-${s.id}'),
                  child: HardShadow(offset: 6, radius: 22, color: t.isDark ? t.quiz : t.hardShadow, child: frontCard(s)),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final buttons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Circle(key: const ValueKey('answer-desaccord'), icon: Icons.close, label: l10n.quizDisagree, bg: t.card, fg: t.ink, onTap: () => _controller.fling(Answer.desaccord)),
        const SizedBox(width: 14),
        _Circle(key: const ValueKey('answer-neutre'), icon: Icons.remove, label: l10n.quizNeutral, bg: t.card, fg: t.ink, onTap: () => _controller.fling(Answer.neutre)),
        const SizedBox(width: 14),
        _Circle(key: const ValueKey('answer-accord'), icon: Icons.check, label: l10n.quizAgree, bg: t.quiz, fg: t.onQuiz, shadow: t.isDark ? t.ink : null, onTap: () => _controller.fling(Answer.accord)),
        const SizedBox(width: 14),
        _Circle(key: const ValueKey('answer-important'), icon: important ? Icons.star : Icons.star_outline, label: l10n.quizImportant.split(' ').first, bg: t.accent, fg: t.onAccent, onTap: toggleImportant, selected: important),
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 760 : double.infinity),
          child: ListView(
            padding: EdgeInsets.fromLTRB(wide ? 32 : BandScaffold.side, 26, wide ? 32 : BandScaffold.side, 24),
            children: [
              stack,
              const SizedBox(height: 28),
              buttons,
              const SizedBox(height: 8),
              Center(child: Text(l10n.quizImportantCount(session.important.length, QuizEngine.maxImportant), style: PalabreType.note(t.muted))),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: t.muted),
                  onPressed: () => _controller.fling(Answer.passer),
                  child: Text(l10n.quizSkipStatement),
                ),
              ),
            ],
          ),
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

/// Cercle de réponse 62 px : bord 2 px, ombre dure 3/3, label dessous.
class _Circle extends StatelessWidget {
  const _Circle({super.key, required this.icon, required this.label, required this.bg, required this.fg, required this.onTap, this.shadow, this.selected = false});
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color? shadow;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: label,
            selected: selected,
            child: HardShadow(
              offset: 3,
              color: shadow,
              shape: BoxShape.circle,
              onTap: onTap,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: t.border, width: 2)),
                child: Icon(icon, size: 28, color: fg, weight: 600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.muted)),
        ],
      ),
    );
  }
}
