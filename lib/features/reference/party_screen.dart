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
    final scheme = Theme.of(context).colorScheme;
    final reference = ref.watch(currentReferenceProvider);
    final b = reference.value;
    final org = b?.organization(orgId);
    if (b == null || org == null) {
      return Scaffold(appBar: AppBar(), body: reference.isLoading ? const Center(child: CircularProgressIndicator(strokeWidth: 2)) : ErrorRetry(message: l10n.errorGeneric));
    }
    final locale = context.localeName;
    final color = parseHexColor(org.couleur) ?? scheme.primary;
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

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Row(
            children: [
              Container(width: 6, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(org.nom, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.2)),
                    Text([typeLabel, if (org.sigle != null) org.sigle!].join(' · '), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (org.fondation != null) Text(l10n.partyFounded(LocalTime.civil(org.fondation!, locale)), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          if (org.dissolution != null) Text(l10n.partyDissolved(LocalTime.civil(org.dissolution!, locale)), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          SourceLink(url: org.sourceUrl, dense: true),
          if (relations.isNotEmpty) ...[
            SectionTitle(l10n.partyHistory),
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
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: other == null ? null : () => context.push(Routes.party(other.id)),
                  title: Text('$label ${other?.nom ?? '?'}'),
                  subtitle: Row(children: [
                    if (r.date != null) Text(LocalTime.civil(r.date!, locale), style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    SourceLink(url: r.sourceUrl, dense: true),
                  ]),
                );
              }),
          ],
          SectionTitle(l10n.partyMembers),
          if (members.isEmpty) Text(l10n.personNoData, style: TextStyle(color: scheme.onSurfaceVariant)),
          for (final p in members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: PersonAvatar(nom: p.nom, photoUrl: p.photoUrl, size: 36, color: color),
              title: Text(p.nom),
              onTap: () => context.push(Routes.person(p.id)),
            ),
          if (org.isParty) ...[
            SectionTitle(l10n.partyPositions),
            if (positions.isEmpty || quiz == null)
              Text(l10n.partyPositionsNone, style: TextStyle(color: scheme.onSurfaceVariant))
            else
              for (final s in quiz.statements)
                if (quiz.position(s.id, org.id) != null) ...[
                  Text(s.texte, style: const TextStyle(fontSize: 13, height: 1.3)),
                  PositionTile(party: quiz.party(org.id)!, position: quiz.position(s.id, org.id), dense: true),
                  const Hairline(),
                ],
          ],
        ],
      ),
    );
  }
}
