import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/country/country_providers.dart';
import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import 'poll_models.dart';
import 'poll_providers.dart';

/// Durée restante en clair : « 2 j 9 h » ou « 3 h 12 min ».
String remainingLabel(BuildContext context, Duration d) {
  final l10n = context.l10n;
  if (d.inHours >= 24) return l10n.durationDaysHours(d.inDays, d.inHours % 24);
  return l10n.durationHoursMinutes(d.inHours, d.inMinutes % 60);
}

/// Surtitre du bandeau : le statut en une ligne, avec le temps restant.
String pollStatusLine(BuildContext context, WidgetRef ref, Poll poll) {
  final l10n = context.l10n;
  final lt = LocalTime(ref.watch(selectedCountryInfoProvider).fuseau);
  final now = DateTime.now().toUtc();
  return switch (poll.status) {
    PollStatus.ouvert => l10n.pollClosesIn(remainingLabel(context, poll.fermeture.difference(now)), lt.dateTime(poll.fermeture, context.localeName)),
    PollStatus.programme => l10n.pollOpensIn(remainingLabel(context, poll.ouverture.difference(now)), lt.dateTime(poll.ouverture, context.localeName)),
    _ => l10n.pollClosedAt(lt.date(poll.fermeture, context.localeName)),
  };
}

/// Le corps de la question : options et vote, ou résultats, selon l'état.
/// La question elle-même est le titre « poster » de l'écran.
class PollCard extends ConsumerWidget {
  const PollCard(this.poll, {super.key});
  final Poll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final myVote = ref.watch(myVoteProvider(poll.id)).value;
    final results = ref.watch(pollResultsProvider(poll.id));
    final status = poll.status;
    final canSeeResults = status == PollStatus.ferme || myVote != null;
    final lt = LocalTime(ref.watch(selectedCountryInfoProvider).fuseau);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (poll.suspect)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NoticeBanner(text: l10n.pollSuspect(poll.suspectMotif ?? ''), icon: Icons.warning_amber_outlined, color: scheme.error),
          ),
        if (status == PollStatus.programme) ...[
          for (final o in poll.options) OptionRow(label: o.libelle, neutral: o.neutre, selected: false, enabled: false),
          const SizedBox(height: 4),
          NoticeBanner(text: l10n.pollStatusScheduledNote(lt.dateTime(poll.ouverture, context.localeName)), icon: Icons.schedule),
        ] else if (!canSeeResults)
          VoteBox(poll)
        else
          SoftCard(
            child: results.when(
              data: (r) => r == null ? Text(l10n.pollNoResultsYet, style: TextStyle(color: t.muted)) : ResultsView(poll: poll, results: r, myOptionId: myVote),
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, _) => ErrorRetry(message: l10n.errorGeneric, onRetry: () => ref.invalidate(pollResultsProvider(poll.id))),
            ),
          ),
      ],
    );
  }
}

/// Une option : ligne pleine largeur, bord 2 px, case carrée. Choisie : fond
/// couleur de section, ombre dure. « Sans avis » : bord et texte désactivés.
class OptionRow extends StatelessWidget {
  const OptionRow({super.key, required this.label, required this.selected, this.neutral = false, this.enabled = true, this.onTap});
  final String label;
  final bool selected;
  final bool neutral;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final section = context.sectionColor;
    final fg = selected ? context.onSectionColor : (neutral || !enabled ? t.muted : t.ink);
    final borderColor = neutral && !selected ? t.disabled : t.border;
    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? section : t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        children: [
          SquareCheck(checked: selected, disabled: neutral, onDark: true),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: selected ? FontWeight.w800 : FontWeight.w700, color: fg))),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: selected
          ? HardShadow(offset: 4, radius: 16, color: t.isDark ? t.ink : t.hardShadow, onTap: enabled ? onTap : null, child: row)
          : GestureDetector(behavior: HitTestBehavior.opaque, onTap: enabled ? onTap : null, child: row),
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
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in widget.poll.options)
          OptionRow(
            label: o.libelle,
            neutral: o.neutre,
            selected: _selected == o.id,
            enabled: !_busy,
            onTap: () => setState(() => _selected = o.id),
          ),
        const SizedBox(height: 8),
        ActionButton(
          label: l10n.pollVote,
          busy: _busy,
          onPressed: _selected == null || _busy ? null : _vote,
        ),
        const SizedBox(height: 12),
        Text('${l10n.pollVoteFinal} · ${l10n.pollAlreadyAnswered(widget.poll.repondants)}', style: PalabreType.note(t.muted), textAlign: TextAlign.center),
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
    final t = context.tokens;
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

    final mine = widget.myOptionId == null ? null : widget.poll.option(widget.myOptionId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [AnimatedNumber(value: r.repondants, style: PalabreType.big(t.ink)), const SizedBox(width: 8), Text(l10n.pollRespondents(r.repondants).replaceFirst(RegExp(r'^\d+\s*'), ''), style: PalabreType.cardTitle(t.ink))]),
        const SizedBox(height: 4),
        Text(r.isFinal ? l10n.pollResultsFinal : l10n.pollResultsProvisional, style: PalabreType.note(t.muted)),
        const SizedBox(height: 4),
        Text(l10n.pollSample(r.repondants, country.nom), style: PalabreType.note(t.muted)),
        if (mine != null) ...[
          const SizedBox(height: 10),
          Pill(label: l10n.pollVoted(mine.libelle), icon: Icons.check),
        ],
        const CardDivider(space: 14),
        if (dims.length == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l10n.pollBreakdownNone(r.seuil), style: PalabreType.note(t.muted)),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in dims.entries) Pill(label: e.value, selected: _dimension == e.key, onTap: () => setState(() => _dimension = e.key)),
            ],
          ),
        const SizedBox(height: 8),
        if (cells.isEmpty)
          Text(l10n.pollNoResultsYet, style: TextStyle(color: t.muted))
        else
          for (final c in cells) ...[
            if (c.dimension != 'total')
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Row(
                  children: [
                    Text(cellLabel(c), style: TextStyle(fontWeight: FontWeight.w700, color: t.ink)),
                    const SizedBox(width: 8),
                    Text(l10n.pollRespondents(c.nCellule), style: PalabreType.note(t.muted)),
                  ],
                ),
              ),
            for (final o in widget.poll.options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(o.libelle,
                              style: TextStyle(fontSize: 13.5, color: o.neutre ? t.muted : t.ink, fontWeight: widget.myOptionId == o.id ? FontWeight.w700 : FontWeight.w500)),
                        ),
                        const SizedBox(width: 8),
                        BigPercent((c.fraction(o.id) * 100).round(), size: 22),
                        const SizedBox(width: 6),
                        Text('(${c.counts[o.id] ?? 0})', style: PalabreType.note(t.muted)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    PercentBar(fraction: c.fraction(o.id), color: o.neutre ? t.disabled : context.sectionColor),
                  ],
                ),
              ),
          ],
      ],
    );
  }
}

/// Contexte factuel court et ses sources, repliés par défaut, en ligne
/// « affiche ». Jamais le texte intégral.
class PollContextCard extends StatefulWidget {
  const PollContextCard(this.poll, {super.key, this.initiallyOpen = false});
  final Poll poll;
  final bool initiallyOpen;

  @override
  State<PollContextCard> createState() => _PollContextCardState();
}

class _PollContextCardState extends State<PollContextCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final poll = widget.poll;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PosterRow(
          icon: Icons.menu_book_outlined,
          label: l10n.pollContextSources(poll.sources.length),
          onTap: () => setState(() => _open = !_open),
          trailingWidget: AnimatedRotation(turns: _open ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: Icon(Icons.expand_more, size: 22, color: t.muted)),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 0, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(poll.contexte, style: TextStyle(height: 1.45, fontWeight: FontWeight.w500, color: t.ink)),
                if (poll.sources.isNotEmpty) ...[
                  const SizedBox(height: 10),
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
            ),
          ),
        ),
      ],
    );
  }
}

/// Une semaine passée : la question, le nombre de réponses, l'option la plus
/// choisie avec sa barre.
class ArchiveCard extends ConsumerWidget {
  const ArchiveCard(this.poll, {super.key});
  final Poll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final total = ref.watch(pollResultsProvider(poll.id)).value?.total;
    PollOption? top;
    if (total != null && total.nCellule > 0 && poll.options.isNotEmpty) {
      top = poll.options.reduce((a, b) => total.fraction(a.id) >= total.fraction(b.id) ? a : b);
    }
    return SoftCard(
      onTap: () => context.push(Routes.poll(poll.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.pollWeekOf(LocalTime.civil(poll.semaine, context.localeName)).toUpperCase(), style: PalabreType.eyebrow(t.muted)),
          const SizedBox(height: 6),
          Text(poll.question, style: PalabreType.label(t.ink).copyWith(fontSize: 14.5, height: 1.3)),
          const SizedBox(height: 10),
          if (top != null && total != null) ...[
            Row(
              children: [
                Expanded(child: Text(top.libelle, style: PalabreType.note(t.muted), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                BigPercent((total.fraction(top.id) * 100).round(), size: 20),
              ],
            ),
            const SizedBox(height: 5),
            PercentBar(fraction: total.fraction(top.id), height: 6, color: top.neutre ? t.disabled : context.sectionColor),
            const SizedBox(height: 6),
            Text(l10n.pollRespondents(total.nCellule), style: PalabreType.note(t.muted)),
          ] else
            Text(l10n.pollRespondents(poll.repondants), style: PalabreType.note(t.muted)),
        ],
      ),
    );
  }
}
