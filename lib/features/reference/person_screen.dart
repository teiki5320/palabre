import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import '../quiz/quiz_providers.dart';
import '../quiz/quiz_widgets.dart';
import 'reference_models.dart';
import 'reference_providers.dart';

String confidenceLabel(BuildContext context, String c) => switch (c) {
      'journal_officiel' => context.l10n.confidenceJournalOfficiel,
      'communique' => context.l10n.confidenceCommunique,
      'agence' => context.l10n.confidenceAgence,
      'wikidata' => context.l10n.confidenceWikidata,
      _ => context.l10n.confidencePresse,
    };

String motifLabel(BuildContext context, String? m) => switch (m) {
      'fin_gouvernement' => context.l10n.motifFinGouvernement,
      'remaniement' => context.l10n.motifRemaniement,
      'demission' => context.l10n.motifDemission,
      'revocation' => context.l10n.motifRevocation,
      'deces' => context.l10n.motifDeces,
      'nomination_gouvernement' => context.l10n.motifNominationGouvernement,
      'fin_legislature' => context.l10n.motifFinLegislature,
      'invalidation' => context.l10n.motifInvalidation,
      _ => context.l10n.motifAutre,
    };

/// Fiche personne : identité, mandats, affiliations, parcours. Chaque ligne
/// renvoie à sa source. Les positions affichées sont celles de son parti.
class PersonScreen extends ConsumerWidget {
  const PersonScreen({super.key, required this.personId});
  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final reference = ref.watch(currentReferenceProvider);
    final b = reference.value;
    final person = b?.person(personId);
    if (b == null || person == null) {
      return BandScaffold(
        title: '',
        children: [
          SoftCard(child: reference.isLoading ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))) : ErrorRetry(message: l10n.personNoData)),
        ],
      );
    }
    final today = dayOnly(DateTime.now());
    final mandates = b.mandatesOf(personId);
    final affiliations = b.affiliationsOf(personId);
    final career = b.careerOf(personId);
    final party = b.affiliationAt(personId, today, (o) => o.isParty) ??
        (affiliations.isEmpty ? null : b.organizations.where((o) => o.isParty && affiliations.any((a) => a.organizationId == o.id)).firstOrNull);
    final quiz = ref.watch(currentQuizProvider).value;
    final partyPositions = party == null || quiz == null ? const <dynamic>[] : quiz.positionsOf(party.id);
    final locale = context.localeName;
    final current = mandates.where((m) => m.fin == null).firstOrNull;
    final role = current == null ? null : (b.portfolio(current.portfolioId)?.intitule ?? b.role(current.roleId)?.intitule);

    return BandScaffold(
      eyebrow: role ?? party?.nom,
      title: person.nom,
      children: [
        SoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonAvatar(nom: person.nom, photoUrl: person.photoUrl, size: 84, color: parseHexColor(party?.couleur)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (person.naissance != null) Text(l10n.personBorn(LocalTime.civil(person.naissance!, locale)), style: PalabreType.note(t.muted)),
                    if (party != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Pill(label: party.nom, icon: Icons.account_balance_outlined, onTap: () => context.push(Routes.party(party.id))),
                      ),
                    if (person.photoSource != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${l10n.source} : ${person.photoSource}${person.photoLicence != null ? ' · ${person.photoLicence}' : ''}', style: TextStyle(fontSize: 10.5, color: t.muted)),
                      ),
                    if (person.wikidataId != null) SourceLink(url: 'https://www.wikidata.org/wiki/${person.wikidataId}', label: 'Wikidata', dense: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        CardSection(
          title: l10n.personMandates,
          children: [
            if (mandates.isEmpty) Text(l10n.personNoData, style: TextStyle(color: t.muted)),
            for (final m in mandates) _MandateRow(bundle: b, mandate: m),
          ],
        ),
      ],
      sideChildren: [
        if (affiliations.isNotEmpty)
          CardSection(title: l10n.personAffiliations, children: [for (final a in affiliations) _AffiliationRow(bundle: b, affiliation: a)]),
        if (career.isNotEmpty)
          CardSection(
            title: l10n.personCareer,
            children: [
              for (final c in career)
                _TimelineRow(title: c.fonction, subtitle: [c.periode, if (c.organisation != null) c.organisation!].join(' · '), sourceUrl: c.sourceUrl),
            ],
          ),
        if (party != null && partyPositions.isNotEmpty && quiz != null)
          CardSection(
            title: l10n.personPartyPositions,
            children: [
              Text(l10n.personPartyPositionsNote, style: PalabreType.note(t.muted)),
              const SizedBox(height: 8),
              for (final s in quiz.statements)
                if (quiz.position(s.id, party.id) != null) ...[
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.texte, style: TextStyle(fontSize: 13.5, height: 1.3, fontWeight: FontWeight.w600, color: t.ink))),
                  PositionTile(party: quiz.party(party.id)!, position: quiz.position(s.id, party.id), dense: true),
                ],
            ],
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.title, required this.subtitle, this.sourceUrl, this.sourceLabel, this.color, this.trailing});
  final String title;
  final String subtitle;
  final String? sourceUrl;
  final String? sourceLabel;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 6), child: ColorDot(color ?? t.line, size: 9)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, height: 1.3, color: t.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: PalabreType.note(t.muted)),
                ?trailing,
                SourceLink(url: sourceUrl, label: sourceLabel, dense: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MandateRow extends StatelessWidget {
  const _MandateRow({required this.bundle, required this.mandate});
  final ReferenceBundle bundle;
  final Mandate mandate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final role = bundle.role(mandate.roleId);
    final portfolio = bundle.portfolio(mandate.portfolioId);
    final government = bundle.government(mandate.governmentId);
    final constituency = bundle.constituency(mandate.constituencyId);
    final replaced = bundle.mandate(mandate.remplaceMandateId);
    final title = [
      portfolio?.intitule ?? role?.intitule ?? '',
      if (constituency != null) constituency.nom,
      if (mandate.qualite == 'suppleant') l10n.asmSubstitute,
    ].join(' · ');
    final period = mandate.fin == null
        ? l10n.govSince(LocalTime.civil(mandate.debut, locale))
        : '${l10n.govFromTo(LocalTime.civil(mandate.debut, locale), LocalTime.civil(mandate.fin!, locale))} · ${motifLabel(context, mandate.motifFin)}';
    return _TimelineRow(
      title: title,
      subtitle: [if (government != null) government.nom, period, confidenceLabel(context, mandate.confiance)].join('\n'),
      sourceUrl: mandate.sourceUrl,
      sourceLabel: mandate.acteRef,
      color: portfolio != null ? BlocColors.of(portfolio.bloc) : null,
      trailing: replaced == null
          ? null
          : TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28), textStyle: const TextStyle(fontSize: 12)),
              onPressed: () => context.push(Routes.person(replaced.personId)),
              child: Text(l10n.asmReplaces(bundle.person(replaced.personId)?.nom ?? '')),
            ),
    );
  }
}

class _AffiliationRow extends StatelessWidget {
  const _AffiliationRow({required this.bundle, required this.affiliation});
  final ReferenceBundle bundle;
  final Affiliation affiliation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final org = bundle.organization(affiliation.organizationId);
    if (org == null) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: org.isParty ? () => context.push(Routes.party(org.id)) : null,
      child: _TimelineRow(
        title: org.nom,
        subtitle: affiliation.fin == null
            ? l10n.govSince(LocalTime.civil(affiliation.debut, locale))
            : l10n.govFromTo(LocalTime.civil(affiliation.debut, locale), LocalTime.civil(affiliation.fin!, locale)),
        sourceUrl: affiliation.sourceUrl,
        color: parseHexColor(org.couleur),
      ),
    );
  }
}

/// Indicateurs d'activité publiés d'un mandat de député. « non publié »
/// plutôt que zéro.
class ActivityBlock extends StatelessWidget {
  const ActivityBlock({super.key, required this.activities});
  final List<DeputyActivity> activities;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    String v(int? n) => n == null ? l10n.asmNotPublished : '$n';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in activities) ...[
          Text(a.periode, style: TextStyle(fontWeight: FontWeight.w700, color: t.ink)),
          const SizedBox(height: 4),
          if (!a.hasAny)
            Text(l10n.asmActivityNone, style: PalabreType.note(t.muted))
          else
            Table(
              columnWidths: const {1: IntrinsicColumnWidth()},
              children: [
                for (final row in [
                  (l10n.asmPresence, a.seancesPresentes == null ? l10n.asmNotPublished : '${a.seancesPresentes}${a.seancesTotal != null ? ' / ${a.seancesTotal}' : ''}'),
                  (l10n.asmWrittenQuestions, v(a.questionsEcrites)),
                  (l10n.asmOralQuestions, v(a.questionsOrales)),
                  (l10n.asmProposals, v(a.propositions)),
                  (l10n.asmCommittees, v(a.commissions)),
                ])
                  TableRow(children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(row.$1, style: TextStyle(fontSize: 13, color: t.muted))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(row.$2, textAlign: TextAlign.end, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.ink))),
                  ]),
              ],
            ),
          SourceLink(url: a.sourceUrl, dense: true),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
