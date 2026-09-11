import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../core/widgets/widgets.dart';
import 'quiz_engine.dart';
import 'quiz_models.dart';
import 'quiz_providers.dart';
import 'quiz_widgets.dart';

/// Concordance en pourcentage, tous les partis listés du plus proche au plus
/// éloigné, sans rang ni médaille ; puis le détail affirmation par
/// affirmation, ta réponse contre celle de chaque parti, avec la source.
/// Calculé ici, jamais stocké.
class QuizResultScreen extends ConsumerStatefulWidget {
  const QuizResultScreen({super.key});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  final _shareKey = GlobalKey();
  bool _sharing = false;
  bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/palabre.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'image/png')], text: context.l10n.quizShareText));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final quiz = ref.watch(currentQuizProvider).value;
    final scores = ref.watch(quizScoresProvider);
    final session = ref.watch(quizSessionProvider);
    if (quiz == null) {
      return BandScaffold(title: l10n.quizResultsTitle, children: [SoftCard(child: ErrorRetry(message: l10n.quizNone))]);
    }
    final answered = session.answers.values.where((a) => a != Answer.passer).length;

    return BandScaffold(
      color: t.quiz,
      onColor: t.onQuiz,
      eyebrow: l10n.quizResultsSubtitle(answered),
      title: l10n.quizResultsAllTitle,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < scores.length; i++) ...[
                if (i > 0) const CardDivider(space: 12),
                _PartyRow(scores[i]),
              ],
            ],
          ),
        ),
      ],
      sideChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Text(l10n.quizResultsNote, style: PalabreType.note(t.muted)),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showDetail = !_showDetail),
                icon: Icon(_showDetail ? Icons.expand_less : Icons.list_alt_outlined, size: 18),
                label: Text(l10n.quizDetailShort),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.ios_share, size: 18),
                label: Text(l10n.share),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_showDetail)
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                for (final st in quiz.statements) _StatementDetail(quiz: quiz, statement: st, scores: scores, session: session),
              ],
            ),
          ),
        // Image partageable, rendue hors écran visible via un Offstage.
        Offstage(
          offstage: true,
          child: RepaintBoundary(key: _shareKey, child: ShareCard(scores: scores, title: quiz.titre)),
        ),
      ],
    );
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow(this.s);
  final PartyScore s;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final color = partyColor(context, s.party);
    final meta = s.concordance == null
        ? l10n.quizNotComparable
        : [l10n.quizCompared(s.compared), if (s.sansPosition > 0) l10n.quizNoPosition(s.sansPosition)].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(width: 10, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.party.nom, style: PalabreType.label(t.ink)),
                  const SizedBox(height: 2),
                  Text(meta, style: PalabreType.note(t.muted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (s.concordance == null)
              Text(l10n.quizNotComputable, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.muted))
            else
              AnimatedNumber(value: s.concordance!, suffix: ' %', style: PalabreType.big(t.ink)),
          ],
        ),
        const SizedBox(height: 8),
        PercentBar(fraction: (s.concordance ?? 0) / 100, color: color),
      ],
    );
  }
}

class _StatementDetail extends StatelessWidget {
  const _StatementDetail({required this.quiz, required this.statement, required this.scores, required this.session});
  final QuizBundle quiz;
  final Statement statement;
  final List<PartyScore> scores;
  final QuizSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final answer = session.answers[statement.id];
    final important = session.important.contains(statement.id);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      title: Text('${statement.ordre}. ${statement.texte}', style: TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w600, color: t.ink)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text('${l10n.quizYou} : ${answerLabel(context, answer)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.primary)),
            if (important) ...[
              const SizedBox(width: 8),
              Icon(Icons.star_rounded, size: 16, color: t.accent),
            ],
          ],
        ),
      ),
      children: [
        for (final s in scores) PositionTile(party: s.party, position: quiz.position(statement.id, s.party.id), dense: true),
      ],
    );
  }
}

/// Image de résultat partageable : bandeau Lagune, liste complète des partis
/// avec leur pourcentage, et la mention que le calcul est local. Aucun rang.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.scores, required this.title});
  final List<PartyScore> scores;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const t = PalabreTokens.light;
    return Theme(
      data: PalabreTheme.light(),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: t.primary,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Palabre', style: PalabreType.wordmark(t.onPrimary)),
                  const SizedBox(height: 10),
                  Text(l10n.quizResultsTitle.toUpperCase(), style: PalabreType.eyebrow(t.onPrimary.withValues(alpha: 0.85))),
                  const SizedBox(height: 4),
                  Text(title, style: PalabreType.title(t.onPrimary)),
                ],
              ),
            ),
            Container(
              color: t.card,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in scores)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(width: 8, height: 26, decoration: BoxDecoration(color: partyColor(context, s.party), borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.party.shortName, style: TextStyle(fontFamily: PalabreType.body, color: t.ink, fontSize: 14, fontWeight: FontWeight.w700))),
                          SizedBox(width: 110, child: PercentBar(fraction: (s.concordance ?? 0) / 100, color: partyColor(context, s.party), track: t.line)),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 52,
                            child: Text(
                              s.concordance == null ? '—' : '${s.concordance} %',
                              textAlign: TextAlign.end,
                              style: TextStyle(fontFamily: PalabreType.display, color: t.ink, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(l10n.quizShareFooter, style: PalabreType.note(t.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
