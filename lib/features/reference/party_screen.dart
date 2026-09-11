import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import '../quiz/quiz_providers.dart';
import '../quiz/quiz_widgets.dart';
import 'reference_providers.dart';

/// Fiche parti : identité, histoire (scissions, fusions…), élus en exercice,
/// et positions déclarées, sourcées.
class PartyScreen extends ConsumerWidget {
  const PartyScreen({super.key, required this.orgId});
  final int orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final reference = ref.watch(currentReferenceProvider);
    final b = reference.value;
    final org = b?.organization(orgId);
    if (b == null || org == null) {
      return BandScaffold(
        title: '',
        children: [
          SoftCard(child: reference.isLoading ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))) : ErrorRetry(message: l10n.errorGeneric)),
        ],
      );
    }
    final locale = context.localeName;
    final color = parseHexColor(org.couleur) ?? t.primary;
    final members = b.membersOf(org.id, dayOnly(DateTime.now()));
    final relations = b.orgRelations.where((r) => r.fromId == org.id || r.toId == org.id).toList();
    final quiz = ref.watch(currentQuizProvider).value;
    final positions = quiz?.positionsOf(org.id) ?? const [];
    final typeLabel = switch (org.type) {
      'parti' => l10n.orgParti,
      'coalition' => l10n.orgCoalition,
      'gouvernement' => l10n.orgGouvernement,
      'assemblee' => l10n.orgAssemblee,
      _ => l10n.orgGroupe,
    };

    return BandScaffold(
      eyebrow: [typeLabel, if (org.sigle != null) org.sigle!].join(' · '),
      title: org.nom,
      children: [
        SoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 10, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (org.fondation != null) Text(l10n.partyFounded(LocalTime.civil(org.fondation!, locale)), style: PalabreType.note(t.muted)),
                    if (org.dissolution != null) Text(l10n.partyDissolved(LocalTime.civil(org.dissolution!, locale)), style: PalabreType.note(t.muted)),
                    SourceLink(url: org.sourceUrl, dense: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (relations.isNotEmpty)
          CardSection(
            title: l10n.partyHistory,
            children: [
              for (final r in relations)
                Builder(builder: (context) {
                  final isFrom = r.fromId == org.id;
                  final other = b.organization(isFrom ? r.toId : r.fromId);
                  final label = switch (r.type) {
                    'scission' => l10n.relScission,
                    'fusion' => l10n.relFusion,
                    'renommage' => l10n.relRenommage,
                    'coalition_membre' => l10n.relCoalitionMembre,
                    _ => l10n.relAbsorption,
                  };
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: other == null ? null : () => context.push(Routes.party(other.id)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$label ${other?.nom ?? '?'}', style: TextStyle(fontWeight: FontWeight.w700, color: t.ink)),
                          Row(children: [
                            if (r.date != null) Text(LocalTime.civil(r.date!, locale), style: PalabreType.note(t.muted)),
                            const SizedBox(width: 8),
                            SourceLink(url: r.sourceUrl, dense: true),
                          ]),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        CardSection(
          title: l10n.partyMembers,
          trailing: members.isEmpty ? null : Pill(label: '${members.length}'),
          children: [
            if (members.isEmpty) Text(l10n.personNoData, style: TextStyle(color: t.muted)),
            for (var i = 0; i < members.length; i++) ...[
              if (i > 0) const CardDivider(space: 6),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.push(Routes.person(members[i].id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      PersonAvatar(nom: members[i].nom, photoUrl: members[i].photoUrl, size: 36, color: color),
                      const SizedBox(width: 12),
                      Expanded(child: Text(members[i].nom, style: PalabreType.label(t.ink))),
                      Icon(Icons.chevron_right, size: 18, color: t.muted),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (org.isParty)
          CardSection(
            title: l10n.partyPositions,
            children: [
              if (positions.isEmpty || quiz == null)
                Text(l10n.partyPositionsNone, style: TextStyle(color: t.muted))
              else
                for (final s in quiz.statements)
                  if (quiz.position(s.id, org.id) != null) ...[
                    Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.texte, style: TextStyle(fontSize: 13.5, height: 1.3, fontWeight: FontWeight.w600, color: t.ink))),
                    PositionTile(party: quiz.party(org.id)!, position: quiz.position(s.id, org.id), dense: true),
                  ],
            ],
          ),
      ],
    );
  }
}
