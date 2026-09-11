import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/country/country_providers.dart';
import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import 'poll_models.dart';
import 'poll_providers.dart';

class PollStatusChip extends ConsumerWidget {
  const PollStatusChip(this.poll, {super.key});
  final Poll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final country = ref.watch(selectedCountryInfoProvider);
    final lt = LocalTime(country.fuseau);
    final (label, sub, color) = switch (poll.status) {
      PollStatus.ouvert => (l10n.pollStatusOpen, l10n.pollClosesAt(lt.dateTime(poll.fermeture, context.localeName)), scheme.primary),
      PollStatus.programme => (l10n.pollStatusScheduled, l10n.pollOpensAt(lt.dateTime(poll.ouverture, context.localeName)), scheme.onSurfaceVariant),
      _ => (l10n.pollStatusClosed, l10n.pollClosedAt(lt.date(poll.fermeture, context.localeName)), scheme.onSurfaceVariant),
    };
    return Row(
      children: [
        ColorDot(color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(child: Text(sub, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// Contexte factuel court et ses sources. Jamais le texte intégral.
class PollContext extends StatelessWidget {
  const PollContext(this.poll, {super.key});
  final Poll poll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(l10n.pollContext),
        Text(poll.contexte, style: const TextStyle(height: 1.45)),
        if (poll.sources.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final s in poll.sources) SourceLink(url: s.url, label: s.titre, dense: true),
        ],
        if (poll.personId != null)
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => context.push(Routes.person(poll.personId!)),
            icon: const Icon(Icons.person_outline, size: 16),
            label: Text(l10n.pollLinkedPerson),
          ),
        if (poll.organizationId != null)
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => context.push(Routes.party(poll.organizationId!)),
            icon: const Icon(Icons.account_balance_outlined, size: 16),
            label: Text(l10n.pollLinkedOrg),
          ),
      ],
    );
  }
}

/// Options et bouton de vote. Un vote, définitif.
class VoteBox extends ConsumerStatefulWidget {
  const VoteBox(this.poll, {super.key});
  final Poll poll;

  @override
  ConsumerState<VoteBox> createState() => _VoteBoxState();
}

class _VoteBoxState extends ConsumerState<VoteBox> {
  int? _selected;
  bool _busy = false;

  Future<void> _vote() async {
    final id = _selected;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(voteActionProvider).vote(widget.poll, id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.pollVoteError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in widget.poll.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: _busy ? null : () => setState(() => _selected = o.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _selected == o.id ? scheme.primary : scheme.outlineVariant, width: _selected == o.id ? 1 : 0.5),
                ),
                child: Row(
                  children: [
                    Icon(_selected == o.id ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 20, color: _selected == o.id ? scheme.primary : scheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(child: Text(o.libelle, style: TextStyle(color: o.neutre ? scheme.onSurfaceVariant : scheme.onSurface))),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        FilledButton(
          onPressed: _selected == null || _busy ? null : _vote,
          child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.pollVote),
        ),
        const SizedBox(height: 6),
        Text(l10n.pollVoteFinal, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
      ],
    );
  }
}

/// Résultats : trois éléments obligatoires, jamais omis — le nombre total de
/// répondants, la mention d'échantillon, les découpes disponibles.
class ResultsView extends ConsumerStatefulWidget {
  const ResultsView({super.key, required this.poll, required this.results, this.myOptionId});
  final Poll poll;
  final PollResults results;
  final int? myOptionId;

  @override
  ConsumerState<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends ConsumerState<ResultsView> {
  String _dimension = 'total';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final r = widget.results;
    final country = ref.watch(selectedCountryInfoProvider);
    final config = ref.watch(countryConfigOrFallbackProvider);
    final dims = <String, String>{
      'total': l10n.pollBreakdownTotal,
      if (r.dimension('pays').isNotEmpty) 'pays': l10n.pollBreakdownCountry,
      if (r.dimension('tranche_age').isNotEmpty) 'tranche_age': l10n.pollBreakdownAge,
      if (r.dimension('region').isNotEmpty) 'region': l10n.pollBreakdownRegion,
    };
    final cells = _dimension == 'total' ? [if (r.total != null) r.total!] : r.dimension(_dimension)
      ..sort((a, b) => b.nCellule.compareTo(a.nCellule));

    String cellLabel(ResultCell c) => switch (c.dimension) {
          'pays' => config.country(c.valeur)?.nom ?? c.valeur,
          'region' => config.region(int.tryParse(c.valeur))?.nom ?? c.valeur,
          _ => c.valeur,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(l10n.pollRespondents(r.repondants), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(r.isFinal ? l10n.pollResultsFinal : l10n.pollResultsProvisional,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant), textAlign: TextAlign.end),
          ],
        ),
        const SizedBox(height: 6),
        Text(l10n.pollSample(r.repondants, country.nom), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.35)),
        if (widget.myOptionId != null && widget.poll.option(widget.myOptionId) != null) ...[
          const SizedBox(height: 8),
          Text(l10n.pollVoted(widget.poll.option(widget.myOptionId)!.libelle), style: TextStyle(fontSize: 12, color: scheme.primary)),
        ],
        SectionTitle(l10n.pollBreakdowns),
        if (dims.length == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l10n.pollBreakdownNone(r.seuil), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          )
        else
          Wrap(
            spacing: 6,
            children: [
              for (final e in dims.entries)
                ChoiceChip(label: Text(e.value), selected: _dimension == e.key, onSelected: (_) => setState(() => _dimension = e.key)),
            ],
          ),
        const SizedBox(height: 8),
        if (cells.isEmpty)
          Text(l10n.pollNoResultsYet, style: TextStyle(color: scheme.onSurfaceVariant))
        else
          for (final c in cells) ...[
            if (c.dimension != 'total')
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Row(
                  children: [
                    Text(cellLabel(c), style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(l10n.pollRespondents(c.nCellule), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            for (final o in widget.poll.options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(o.libelle,
                              style: TextStyle(fontSize: 13, color: o.neutre ? scheme.onSurfaceVariant : scheme.onSurface,
                                  fontWeight: widget.myOptionId == o.id ? FontWeight.w600 : FontWeight.normal)),
                        ),
                        const SizedBox(width: 8),
                        Text('${(c.fraction(o.id) * 100).round()} %', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Text('(${c.counts[o.id] ?? 0})', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    PercentBar(fraction: c.fraction(o.id), color: o.neutre ? scheme.onSurfaceVariant : scheme.primary),
                  ],
                ),
              ),
          ],
      ],
    );
  }
}

/// Corps complet d'un sondage : contexte, puis vote ou résultats selon l'état.
class PollBody extends ConsumerWidget {
  const PollBody(this.poll, {super.key});
  final Poll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final myVote = ref.watch(myVoteProvider(poll.id)).value;
    final results = ref.watch(pollResultsProvider(poll.id));
    final status = poll.status;
    final canSeeResults = status == PollStatus.ferme || myVote != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (poll.suspect)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NoticeBanner(text: l10n.pollSuspect(poll.suspectMotif ?? ''), icon: Icons.warning_amber_outlined, color: scheme.error),
          ),
        PollContext(poll),
        const SizedBox(height: 20),
        if (status == PollStatus.programme)
          NoticeBanner(text: l10n.pollOpensAt(LocalTime(ref.watch(selectedCountryInfoProvider).fuseau).dateTime(poll.ouverture, context.localeName)), icon: Icons.schedule)
        else if (!canSeeResults) ...[
          Text(l10n.pollVoteBeforeResults, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          VoteBox(poll),
        ] else
          results.when(
            data: (r) => r == null
                ? Text(l10n.pollNoResultsYet, style: TextStyle(color: scheme.onSurfaceVariant))
                : ResultsView(poll: poll, results: r, myOptionId: myVote),
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, _) => ErrorRetry(message: l10n.errorGeneric, onRetry: () => ref.invalidate(pollResultsProvider(poll.id))),
          ),
      ],
    );
  }
}
