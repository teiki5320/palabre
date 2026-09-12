import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/country/country_models.dart';
import '../../core/country/country_providers.dart';
import '../../core/net/cached_notifier.dart';
import '../../core/widgets/widgets.dart';
import 'reference_models.dart';
import 'reference_providers.dart';

/// Onglet 4 : recherche et filtres dans le bandeau, députés groupés par
/// groupe parlementaire. Aucun score, aucun classement.
class AssemblyTab extends ConsumerStatefulWidget {
  const AssemblyTab({super.key});

  @override
  ConsumerState<AssemblyTab> createState() => _AssemblyTabState();
}

class _AssemblyTabState extends ConsumerState<AssemblyTab> {
  String _query = '';
  int? _groupId;
  int? _regionId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final code = ref.watch(selectedCountryProvider);
    final reference = ref.watch(referenceProvider(code));
    final module = ref.watch(moduleStateProvider(AppModule.assembly));
    final config = ref.watch(countryConfigOrFallbackProvider);
    final suspended = module != null && !module.actif;
    final today = DateTime.now();
    final day = DateTime.utc(today.year, today.month, today.day);
    final b = reference.value;
    final legislature = suspended ? null : b?.legislatureAt(day);

    String? eyebrow;
    Widget? control;
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
    } else if (reference.isLoading && b == null) {
      children = const [SoftCard(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))))];
    } else if (b == null) {
      final e = reference.error;
      children = [
        SoftCard(child: ErrorRetry(message: e is NotConfiguredException ? l10n.notConfigured : l10n.errorGeneric, onRetry: () => ref.invalidate(referenceProvider(code)))),
      ];
    } else if (legislature == null) {
      children = [SoftCard(child: EmptyState(icon: Icons.groups_outlined, title: l10n.asmNoData, subtitle: l10n.asmNoDataHint))];
    } else {
      final all = b.deputiesAt(day);
      final groups = all.map((d) => d.group).whereType<Organization>().toSet().toList()..sort((a, b) => a.nom.compareTo(b.nom));
      final regionIds = all.map((d) => d.constituency.regionId).whereType<int>().toSet();
      final regions = config.regionsOf(code).where((r) => regionIds.contains(r.id)).toList();
      final q = _query.trim().toLowerCase();
      final filtered = all.where((d) {
        if (_groupId != null && d.group?.id != _groupId) return false;
        if (_regionId != null && d.constituency.regionId != _regionId) return false;
        if (q.isEmpty) return true;
        return d.person.nom.toLowerCase().contains(q) ||
            d.constituency.nom.toLowerCase().contains(q) ||
            (d.party?.nom.toLowerCase().contains(q) ?? false) ||
            (d.party?.sigle?.toLowerCase().contains(q) ?? false) ||
            (d.group?.nom.toLowerCase().contains(q) ?? false);
      }).toList();

      eyebrow = '${l10n.asmLegislature(legislature.numero)} · ${l10n.asmSeats(legislature.siegesTotal)}';
      final groupLabel = _groupId == null ? l10n.asmFilterGroup : (groups.firstWhere((g) => g.id == _groupId).sigle ?? groups.firstWhere((g) => g.id == _groupId).nom);
      control = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BandSearchField(hint: l10n.asmSearch, onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 10),
          Row(
            children: [
              _FilterMenu<int?>(
                label: groupLabel,
                active: _groupId != null,
                items: [MapEntry(null, l10n.asmAll), for (final g in groups) MapEntry(g.id, g.nom)],
                onSelected: (v) => setState(() => _groupId = v),
              ),
              const SizedBox(width: 8),
              _FilterMenu<int?>(
                label: _regionId == null ? l10n.asmFilterRegion : (config.region(_regionId)?.nom ?? ''),
                active: _regionId != null,
                items: [MapEntry(null, l10n.asmAll), for (final r in regions) MapEntry(r.id, r.nom)],
                onSelected: (v) => setState(() => _regionId = v),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.asmResults(filtered.length), textAlign: TextAlign.end, style: PalabreType.note(t.muted))),
            ],
          ),
        ],
      );

      // Groupés par groupe parlementaire, « sans groupe » en dernier.
      final byGroup = <int?, List<DeputyEntry>>{};
      for (final d in filtered) {
        byGroup.putIfAbsent(d.group?.id, () => []).add(d);
      }
      final groupKeys = [...groups.map((g) => g.id).where(byGroup.containsKey), if (byGroup.containsKey(null)) null];

      children = [
        if (!legislature.scrutinsNominatifs)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: NoticeBanner(text: l10n.asmNoRollCall, icon: Icons.how_to_vote_outlined)),
        if (legislature.sourceUrl != null)
          Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: SourceLink(url: legislature.sourceUrl, dense: true)),
        for (final key in groupKeys)
          Builder(builder: (context) {
            final org = key == null ? null : groups.firstWhere((g) => g.id == key);
            final color = parseHexColor(org?.couleur) ?? t.muted;
            final members = byGroup[key]!;
            return CardSection(
              title: org?.nom ?? l10n.asmNoGroup,
              leading: ColorDot(color, size: 10),
              trailing: Pill(label: '${members.length}'),
              children: [
                for (var i = 0; i < members.length; i++) ...[
                  if (i > 0) const CardDivider(space: 6),
                  _DeputyRow(members[i], color),
                ],
              ],
            );
          }),
      ];
    }

    return BandScaffold(
      color: t.assembly,
      onColor: t.onAssembly,
      brand: true,
      eyebrow: eyebrow,
      title: l10n.tabAssembly,
      actions: const [SettingsAction()],
      control: control,
      children: children,
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({required this.label, required this.active, required this.items, required this.onSelected});
  final String label;
  final bool active;
  final List<MapEntry<T, String>> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (_) => [for (final e in items) PopupMenuItem<T>(value: e.key, child: Text(e.value))],
      child: Pill(label: label, icon: active ? Icons.filter_alt : Icons.filter_alt_outlined, selected: active, trailing: Icon(Icons.expand_more, size: 14, color: active ? context.onSectionColor : context.tokens.ink)),
    );
  }
}

class _DeputyRow extends StatelessWidget {
  const _DeputyRow(this.d, this.color);
  final DeputyEntry d;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    // Les initiales prennent la couleur du parti ; à défaut celle du groupe.
    final avatarColor = parseHexColor(d.party?.couleur) ?? color;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(Routes.person(d.person.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            PersonAvatar(nom: d.person.nom, photoUrl: d.person.photoUrl, size: 40, color: avatarColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.person.nom, style: PalabreType.label(t.ink)),
                  const SizedBox(height: 2),
                  Text(
                    [d.constituency.nom, if (d.party != null) d.party!.sigle ?? d.party!.nom, if (d.mandate.qualite == 'suppleant') l10n.asmSubstitute].join(' · '),
                    style: PalabreType.note(t.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: t.muted),
          ],
        ),
      ),
    );
  }
}
