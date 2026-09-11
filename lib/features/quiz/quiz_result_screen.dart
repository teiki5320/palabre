import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/widgets.dart';
import 'quiz_engine.dart';
import 'quiz_models.dart';
import 'quiz_providers.dart';
import 'quiz_widgets.dart';

/// Concordance en pourcentage, tous les partis listés, puis le détail
/// affirmation par affirmation, ta réponse contre celle de chaque parti,
/// avec la source. Calculé ici, jamais stocké.
class QuizResultScreen extends ConsumerStatefulWidget {
  const QuizResultScreen({super.key});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  final _shareKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share(List<PartyScore> scores) async {
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
    final scheme = Theme.of(context).colorScheme;
    final quiz = ref.watch(currentQuizProvider).value;
    final scores = ref.watch(quizScoresProvider);
    final session = ref.watch(quizSessionProvider);
    if (quiz == null) return Scaffold(appBar: AppBar(), body: ErrorRetry(message: l10n.quizNone));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quizResultsTitle),
        actions: [
          IconButton(icon: _sharing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.ios_share), tooltip: l10n.share, onPressed: _sharing ? null : () => _share(scores)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l10n.quizAnswered(session.answers.values.where((a) => a != Answer.passer).length, quiz.statements.length), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(l10n.quizResultsAll, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 16),
          for (final s in scores) _ScoreRow(s),
          SectionTitle(l10n.quizDetail),
          for (final st in quiz.statements) _StatementDetail(quiz: quiz, statement: st, scores: scores, session: session),
          const SizedBox(height: 24),
          // Image partageable, rendue hors écran visible via un Offstage.
          Offstage(
            offstage: true,
            child: RepaintBoundary(key: _shareKey, child: ShareCard(scores: scores, title: quiz.titre)),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.s);
  final PartyScore s;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = partyColor(context, s.party);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ColorDot(color, size: 10),
              const SizedBox(width: 8),
              Expanded(child: Text(s.party.nom, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(s.concordance == null ? '—' : l10n.quizConcordance(s.concordance!), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          PercentBar(fraction: (s.concordance ?? 0) / 100, color: color),
          const SizedBox(height: 4),
          Text(
            s.concordance == null
                ? l10n.quizNotComparable
                : [l10n.quizCompared(s.compared), if (s.sansPosition > 0) l10n.quizNoPosition(s.sansPosition)].join(' · '),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final answer = session.answers[statement.id];
    final important = session.important.contains(statement.id);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text('${statement.ordre}. ${statement.texte}', style: const TextStyle(fontSize: 14, height: 1.3)),
      subtitle: Row(
        children: [
          Text('${l10n.quizYou} : ${answerLabel(context, answer)}', style: TextStyle(fontSize: 12, color: scheme.primary)),
          if (important) ...[
            const SizedBox(width: 8),
            Icon(Icons.star, size: 14, color: scheme.primary),
          ],
        ],
      ),
      children: [
        for (final s in scores) PositionTile(party: s.party, position: quiz.position(statement.id, s.party.id), dense: true),
      ],
    );
  }
}

/// Image de résultat partageable : sombre, plate, tous les partis, et la
/// mention que le calcul est local.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.scores, required this.title});
  final List<PartyScore> scores;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF111416),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Palabre', style: TextStyle(fontSize: 14, letterSpacing: 2, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),
          for (final s in scores)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  ColorDot(partyColor(context, s.party)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.party.shortName, style: const TextStyle(color: Colors.white, fontSize: 14))),
                  SizedBox(width: 120, child: PercentBar(fraction: (s.concordance ?? 0) / 100, color: partyColor(context, s.party))),
                  const SizedBox(width: 8),
                  SizedBox(width: 44, child: Text(s.concordance == null ? '—' : '${s.concordance} %', textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text(l10n.quizShareFooter, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
