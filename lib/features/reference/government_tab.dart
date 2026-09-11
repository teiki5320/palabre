import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/country/country_models.dart';
import '../../core/country/country_providers.dart';
import '../../core/net/cached_notifier.dart';
import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import 'reference_models.dart';
import 'reference_providers.dart';

/// Onglet 3 : grille de portraits groupée par bloc, couleur par bloc, et le
/// curseur temporel. On fait glisser, la grille se recompose.
class GovernmentTab extends ConsumerWidget {
  const GovernmentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final code = ref.watch(selectedCountryProvider);
    final reference = ref.watch(referenceProvider(code));
    final module = ref.watch(moduleStateProvider(AppModule.government));
    final date = ref.watch(governmentDateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabGovernment), actions: const [SettingsAction()]),
      body: module != null && !module.actif
          ? ListView(padding: const EdgeInsets.all(16), children: [
              NoticeBanner(text: l10n.moduleSuspended, icon: Icons.pause_circle_outline),
              if (module.motif != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(l10n.moduleSuspendedReason(module.motif!), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
            ])
          : reference.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => ErrorRetry(message: e is NotConfiguredException ? l10n.notConfigured : l10n.errorGeneric, onRetry: () => ref.invalidate(referenceProvider(code))),
              data: (ref_) {
                if (ref_.governments.isEmpty) {
                  return Padding(padding: const EdgeInsets.all(16), child: NoticeBanner(text: l10n.govNoData));
                }
                final composition = ref_.governmentAt(date);
                return Column(
                  children: [
                    _TimeSlider(bundle: ref_, date: date),
                    Expanded(
                      child: composition == null
                          ? Padding(padding: const EdgeInsets.all(16), child: NoticeBanner(text: l10n.govNone))
                          : _CompositionGrid(composition: composition),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _TimeSlider extends ConsumerWidget {
  const _TimeSlider({required this.bundle, required this.date});
  final ReferenceBundle bundle;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final today = dayOnly(DateTime.now());
    final min = dayOnly(bundle.earliestDate ?? today);
    final span = today.difference(min).inDays;
    final value = date.difference(min).inDays.clamp(0, span).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.govAt(LocalTime.civil(date, context.localeName)), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.today_outlined, size: 20),
                tooltip: l10n.govAt(LocalTime.civil(today, context.localeName)),
                onPressed: () => ref.read(governmentDateProvider.notifier).set(today),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: span <= 0 ? 1 : span.toDouble(),
            onChanged: span <= 0 ? null : (v) => ref.read(governmentDateProvider.notifier).set(min.add(Duration(days: v.round()))),
          ),
          Row(
            children: [
              Text(LocalTime.civilShort(min, context.localeName), style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              const Spacer(),
              Text(LocalTime.civilShort(today, context.localeName), style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompositionGrid extends StatelessWidget {
  const _CompositionGrid({required this.composition});
  final GovernmentComposition composition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final g = composition.government;
    final blocs = composition.byBloc;
    const order = [null, 'regalien', 'economie', 'social', 'infrastructure'];
    final keys = [...order.where(blocs.containsKey), ...blocs.keys.where((k) => !order.contains(k))];
    final coverage = g.portefeuillesTotal == null
        ? l10n.govCoverageUnknown(composition.portefeuillesRenseignes)
        : l10n.govCoverage(composition.portefeuillesRenseignes, g.portefeuillesTotal!);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  g.fin == null
                      ? l10n.govSince(LocalTime.civil(g.debut, context.localeName))
                      : l10n.govFromTo(LocalTime.civil(g.debut, context.localeName), LocalTime.civil(g.fin!, context.localeName)),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: Text(coverage, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
                    SourceLink(url: g.sourceUrl, label: g.decretRef ?? l10n.source, dense: true),
                  ],
                ),
              ],
            ),
          ),
        ),
        for (final bloc in keys) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  ColorDot(bloc == null ? scheme.onSurface : blocColor(bloc)),
                  const SizedBox(width: 8),
                  Text((bloc == null ? l10n.govHead : blocLabel(context, bloc)).toUpperCase(),
                      style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.66),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _PortraitCell(blocs[bloc]![i], bloc == null ? scheme.onSurface : blocColor(bloc)),
                childCount: blocs[bloc]!.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _PortraitCell extends StatelessWidget {
  const _PortraitCell(this.entry, this.color);
  final GovernmentEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(Routes.person(entry.person.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(builder: (_, c) => PersonAvatar(nom: entry.person.nom, photoUrl: entry.person.photoUrl, size: c.maxWidth, color: color)),
          ),
          const SizedBox(height: 6),
          Text(entry.person.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
          const SizedBox(height: 2),
          Text(entry.intitule, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant, height: 1.2)),
        ],
      ),
    );
  }
}
