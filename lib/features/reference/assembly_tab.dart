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

/// Onglet 4 : recherche par nom, circonscription ou parti ; filtres par
/// groupe et par région. Aucun score, aucun classement.
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
    final scheme = Theme.of(context).colorScheme;
    final code = ref.watch(selectedCountryProvider);
    final reference = ref.watch(referenceProvider(code));
    final module = ref.watch(moduleStateProvider(AppModule.assembly));
    final config = ref.watch(countryConfigOrFallbackProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabAssembly), actions: const [SettingsAction()]),
      body: module != null && !module.actif
          ? ListView(padding: const EdgeInsets.all(16), children: [
              NoticeBanner(text: l10n.moduleSuspended, icon: Icons.pause_circle_outline),
              if (module.motif != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(l10n.moduleSuspendedReason(module.motif!), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
            ])
          : reference.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => ErrorRetry(message: e is NotConfiguredException ? l10n.notConfigured : l10n.errorGeneric, onRetry: () => ref.invalidate(referenceProvider(code))),
              data: (b) {
                final today = DateTime.now();
                final legislature = b.legislatureAt(DateTime.utc(today.year, today.month, today.day));
                if (legislature == null) {
                  return Padding(padding: const EdgeInsets.all(16), child: NoticeBanner(text: l10n.asmNoData));
                }
                final all = b.deputiesAt(DateTime.utc(today.year, today.month, today.day));
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

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(l10n.asmLegislature(legislature.numero), style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Text('· ${l10n.asmSeats(legislature.siegesTotal)}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                              const Spacer(),
                              SourceLink(url: legislature.sourceUrl, dense: true),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (!legislature.scrutinsNominatifs) NoticeBanner(text: l10n.asmNoRollCall, icon: Icons.how_to_vote_outlined),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(hintText: l10n.asmSearch, prefixIcon: const Icon(Icons.search, size: 20), isDense: true),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterMenu<int?>(
                                  label: _groupId == null ? l10n.asmFilterGroup : (groups.firstWhere((g) => g.id == _groupId).sigle ?? groups.firstWhere((g) => g.id == _groupId).nom),
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
                                const SizedBox(width: 12),
                                Text(l10n.asmResults(filtered.length), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const CardDivider(),
                        itemBuilder: (_, i) => _DeputyRow(filtered[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
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
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        avatar: Icon(active ? Icons.filter_alt : Icons.filter_alt_outlined, size: 16),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _DeputyRow extends StatelessWidget {
  const _DeputyRow(this.d);
  final DeputyEntry d;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = parseHexColor(d.group?.couleur) ?? scheme.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push(Routes.person(d.person.id)),
      leading: PersonAvatar(nom: d.person.nom, photoUrl: d.person.photoUrl, size: 44, color: color),
      title: Text(d.person.nom, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text([d.constituency.nom, if (d.party != null) d.party!.sigle ?? d.party!.nom].join(' · '), style: const TextStyle(fontSize: 12)),
          Row(
            children: [
              ColorDot(color, size: 6),
              const SizedBox(width: 6),
              Text(d.group?.sigle ?? d.group?.nom ?? l10n.asmNoGroup, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              if (d.mandate.qualite == 'suppleant') ...[
                const SizedBox(width: 8),
                Text(l10n.asmSubstitute, style: TextStyle(fontSize: 11, color: scheme.primary)),
              ],
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }
}
