import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import 'quiz_models.dart';
import 'quiz_providers.dart';

String positionLabel(BuildContext context, Position p) => switch (p) {
      Position.accord => context.l10n.quizPositionAgree,
      Position.desaccord => context.l10n.quizPositionDisagree,
      Position.neutre => context.l10n.quizPositionNeutral,
      Position.sansPosition => context.l10n.quizPositionNone,
    };

String answerLabel(BuildContext context, Answer? a) => switch (a) {
      Answer.accord => context.l10n.quizAgree,
      Answer.desaccord => context.l10n.quizDisagree,
      Answer.neutre => context.l10n.quizNeutral,
      Answer.passer => context.l10n.quizYouSkipped,
      null => context.l10n.quizYouSkipped,
    };

String sourceTypeLabel(BuildContext context, SourceType t) => switch (t) {
      SourceType.reponseDirecte => context.l10n.quizSourceDirect,
      SourceType.documentPublic => context.l10n.quizSourceDocument,
      SourceType.aucune => context.l10n.quizSourceNone,
    };

Color positionColor(BuildContext context, Position p) {
  final scheme = Theme.of(context).colorScheme;
  return switch (p) {
    Position.accord => BlocColors.social,
    Position.desaccord => BlocColors.infrastructure,
    Position.neutre => scheme.onSurfaceVariant,
    Position.sansPosition => scheme.outline,
  };
}

Color partyColor(BuildContext context, Party p) => parseHexColor(p.couleur) ?? Theme.of(context).colorScheme.primary;

/// Une position d'un parti, avec son niveau de source, sa citation courte,
/// son lien et la date de correction. C'est cet affichage qui rend le
/// module inattaquable.
class PositionTile extends StatelessWidget {
  const PositionTile({super.key, required this.party, required this.position, this.dense = false});
  final Party party;
  final PartyPosition? position;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final p = position;
    final pos = p?.position ?? Position.sansPosition;
    final st = p?.sourceType ?? SourceType.aucune;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 6 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ColorDot(partyColor(context, party)),
              const SizedBox(width: 8),
              Expanded(child: Text(party.nom, style: const TextStyle(fontWeight: FontWeight.w500))),
              const SizedBox(width: 8),
              Text(positionLabel(context, pos), style: TextStyle(color: positionColor(context, pos), fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                switch (st) {
                  SourceType.reponseDirecte => Icons.mark_email_read_outlined,
                  SourceType.documentPublic => Icons.description_outlined,
                  SourceType.aucune => Icons.help_outline,
                },
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(sourceTypeLabel(context, st), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              if (p?.dateSource != null) ...[
                Text(' · ', style: TextStyle(color: scheme.onSurfaceVariant)),
                Text(LocalTime.civilShort(p!.dateSource!, context.localeName), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
              if (p?.corrigeLe != null) ...[
                Text(' · ', style: TextStyle(color: scheme.onSurfaceVariant)),
                Text(l10n.quizCorrectedOn(LocalTime.civilShort(p!.corrigeLe!, context.localeName)), style: TextStyle(fontSize: 12, color: scheme.primary)),
              ],
            ],
          ),
          if (p?.sourceExtrait != null && p!.sourceExtrait!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(border: Border(left: BorderSide(color: scheme.outlineVariant, width: 1))),
                child: Text('« ${p.sourceExtrait} »', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant, height: 1.35)),
              ),
            ),
          Row(
            children: [
              if (p?.sourceUrl != null) SourceLink(url: p!.sourceUrl, dense: true),
              const Spacer(),
              if (p != null)
                TextButton(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32), textStyle: const TextStyle(fontSize: 12)),
                  onPressed: () => showContestationSheet(context, p, party),
                  child: Text(l10n.quizContest),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formulaire de contestation, accessible depuis chaque position.
Future<void> showContestationSheet(BuildContext context, PartyPosition position, Party party) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ContestationSheet(position: position, party: party),
  );
}

class _ContestationSheet extends ConsumerStatefulWidget {
  const _ContestationSheet({required this.position, required this.party});
  final PartyPosition position;
  final Party party;

  @override
  ConsumerState<_ContestationSheet> createState() => _ContestationSheetState();
}

class _ContestationSheetState extends ConsumerState<_ContestationSheet> {
  final _argument = TextEditingController();
  final _piece = TextEditingController();
  final _auteur = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _argument.dispose();
    _piece.dispose();
    _auteur.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    if (_argument.text.trim().length < 20) {
      setState(() => _error = l10n.quizContestTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(contestationActionProvider).send(
            positionId: widget.position.id,
            argument: _argument.text,
            pieceUrl: _piece.text,
            auteur: _auteur.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.quizContestSent)));
    } catch (_) {
      setState(() {
        _busy = false;
        _error = l10n.quizContestError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.quizContest, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${widget.party.nom} · ${positionLabel(context, widget.position.position)}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          Text(l10n.quizContestIntro, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 16),
          TextField(controller: _argument, maxLines: 4, minLines: 3, decoration: InputDecoration(labelText: l10n.quizContestArgument, errorText: _error)),
          const SizedBox(height: 10),
          TextField(controller: _piece, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l10n.quizContestPiece)),
          const SizedBox(height: 10),
          TextField(controller: _auteur, decoration: InputDecoration(labelText: l10n.quizContestAuthor)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _send, child: Text(l10n.send)),
        ],
      ),
    );
  }
}
