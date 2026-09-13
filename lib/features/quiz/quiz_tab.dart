import 'dart:async';

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
import 'swipe_card.dart';

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
                  // Démonstration animée du geste, à la place d'un mode d'emploi.
                  const SwipeDemo(),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _hint(t, Icons.arrow_back, l10n.quizDisagree),
                      _hint(t, Icons.arrow_upward, l10n.quizNeutral),
                      _hint(t, Icons.arrow_forward, l10n.quizAgree),
                    ],
                  ),
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
            PosterList(children: [
              _MethodRow(title: l10n.quizIntro, lines: [l10n.quizMethod1, l10n.quizMethod2, l10n.quizMethod3]),
            ]),
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

Widget _hint(PalabreTokens t, IconData icon, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: t.muted),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.muted)),
      ],
    );

/// « Comment ça marche » : la méthode, repliée, toujours accessible.
class _MethodRow extends StatefulWidget {
  const _MethodRow({required this.title, required this.lines});
  final String title;
  final List<String> lines;

  @override
  State<_MethodRow> createState() => _MethodRowState();
}

class _MethodRowState extends State<_MethodRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PosterRow(icon: Icons.balance_outlined, label: l10n.quizMethodTitle, trailing: _open ? Icons.expand_less : Icons.expand_more, onTap: () => setState(() => _open = !_open)),
        AnimatedCrossFade(
          duration: Duration(milliseconds: reduceMotion(context) ? 0 : 200),
          crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: PalabreType.cardTitle(t.ink)),
                for (final line in widget.lines) Padding(padding: const EdgeInsets.only(top: 8), child: Text(line, style: TextStyle(height: 1.4, color: t.ink))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Trois petites cartes qui montrent le geste en boucle : à droite « d'accord »,
/// à gauche « pas d'accord », vers le haut « neutre ». Sans texte : une pastille
/// et des lignes, pour ne rien avoir à traduire. Image fixe si les animations
/// sont réduites.
class SwipeDemo extends StatefulWidget {
  const SwipeDemo({super.key});

  @override
  State<SwipeDemo> createState() => _SwipeDemoState();
}

class _SwipeDemoState extends State<SwipeDemo> {
  static const _period = Duration(milliseconds: 2200);
  // Deux tours complets, puis l'image fixe : la démonstration ne tourne pas sans fin.
  static const _tours = 2;
  int _phase = 0;
  int _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_period, (_) {
      if (!mounted) return;
      _step++;
      if (_step >= _tours * 3) {
        _timer?.cancel();
        setState(() => _phase = -1);
      } else {
        setState(() => _phase = _step % 3);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final still = reduceMotion(context);
    final labels = [l10n.quizAgree, l10n.quizDisagree, l10n.quizNeutral];
    final dirs = [const Offset(1, 0), const Offset(-1, 0), const Offset(0, -1)];
    return SizedBox(
      height: 190,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        Widget miniCard({double dx = 0, double dy = 0, double angle = 0, Widget? stamp}) => Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: w * 0.62,
                  height: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: t.border, width: 2), boxShadow: [PalabreTokens.hard(t.isDark ? t.quiz : t.hardShadow, 4)]),
                  child: Stack(children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 64, height: 16, decoration: BoxDecoration(border: Border.all(color: t.quiz, width: 1.5), borderRadius: BorderRadius.circular(8))),
                        const SizedBox(height: 14),
                        for (final f in [0.9, 0.75, 0.55]) Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(width: (w * 0.62 - 28) * f, height: 10, decoration: BoxDecoration(color: t.track, borderRadius: BorderRadius.circular(3)))),
                      ],
                    ),
                    if (stamp != null) Positioned(top: 0, right: 0, left: 0, child: stamp),
                  ]),
                ),
              ),
            );
        Widget stampFor(int phase, double opacity) {
          final label = labels[phase];
          final s = phase == 0
              ? SwipeStamp(label: label, bg: t.quiz, fg: t.onQuiz)
              : phase == 1
                  ? SwipeStamp(label: label, bg: t.ink, fg: t.card)
                  : SwipeStamp(label: label, bg: t.card, fg: t.ink, outlined: true);
          return Opacity(opacity: opacity, child: Align(alignment: phase == 2 ? Alignment.topCenter : Alignment.topRight, child: s));
        }

        final back = Transform.rotate(angle: -3 * 3.14159 / 180, child: Opacity(opacity: t.isDark ? 0.6 : 1, child: miniCard(dy: 8)));
        if (still || _phase < 0) {
          return Stack(alignment: Alignment.center, children: [back, miniCard(dx: 26, angle: 0.08, stamp: stampFor(0, 1))]);
        }
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            back,
            TweenAnimationBuilder<double>(
              key: ValueKey(_phase),
              tween: Tween(begin: 0, end: 1),
              duration: _period,
              curve: Curves.linear,
              builder: (_, v, _) {
                // 35 % d'attente, puis la carte part dans la direction du geste.
                final p = ((v - 0.35) / 0.55).clamp(0.0, 1.0);
                final eased = Curves.easeInCubic.transform(p);
                final d = dirs[_phase];
                final dx = d.dx * eased * w * 0.9;
                final dy = d.dy * eased * 220;
                final opacity = (p * 3).clamp(0.0, 1.0);
                return Opacity(
                  opacity: v > 0.9 ? ((1 - v) / 0.1).clamp(0.0, 1.0) : 1,
                  child: miniCard(dx: dx, dy: dy, angle: d.dx * eased * 0.25, stamp: stampFor(_phase, opacity)),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}
