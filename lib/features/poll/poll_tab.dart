import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/config/env.dart';
import '../../core/country/country_models.dart';
import '../../core/country/country_providers.dart';
import '../../core/net/cached_notifier.dart';
import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import 'poll_models.dart';
import 'poll_providers.dart';
import 'poll_widgets.dart';

/// Onglet 1 : la question de la semaine, puis l'archive des semaines
/// précédentes (sans elle, l'onglet est vide six jours sur sept).
class PollTab extends ConsumerWidget {
  const PollTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final code = ref.watch(selectedCountryProvider);
    final feed = ref.watch(pollFeedProvider(code));
    final module = ref.watch(moduleStateProvider(AppModule.poll));
    final offline = ref.watch(pollFeedProvider(code).notifier).offline;
    final country = ref.watch(selectedCountryInfoProvider);
    final lt = LocalTime(country.fuseau);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabQuestion), actions: const [SettingsAction()]),
      body: RefreshIndicator(
        onRefresh: () => ref.read(pollFeedProvider(code).notifier).refresh(),
        child: module != null && !module.actif
            ? ListView(padding: const EdgeInsets.all(16), children: [
                NoticeBanner(text: l10n.moduleSuspended, icon: Icons.pause_circle_outline),
                if (module.motif != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(l10n.moduleSuspendedReason(module.motif!), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
              ])
            : feed.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => ErrorRetry(
                  message: e is NotConfiguredException ? l10n.notConfigured : l10n.errorGeneric,
                  onRetry: () => ref.invalidate(pollFeedProvider(code)),
                ),
                data: (f) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (offline || !Env.isConfigured)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NoticeBanner(text: Env.isConfigured ? l10n.offlineNotice : l10n.notConfigured, icon: Icons.cloud_off_outlined),
                      ),
                    if (f.current == null)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text(l10n.pollNoCurrent, style: TextStyle(color: scheme.onSurfaceVariant)))
                    else
                      _CurrentPoll(f.current!),
                    SectionTitle(l10n.pollArchive),
                    if (f.archive.isEmpty)
                      Text(l10n.pollArchiveEmpty, style: TextStyle(color: scheme.onSurfaceVariant))
                    else
                      for (final p in f.archive) _ArchiveRow(p, lt),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CurrentPoll extends ConsumerWidget {
  const _CurrentPoll(this.poll);
  final Poll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pollWeekOf(LocalTime.civil(poll.semaine, context.localeName)), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(poll.question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3)),
        const SizedBox(height: 10),
        PollStatusChip(poll),
        const SizedBox(height: 4),
        PollBody(poll),
      ],
    );
  }
}

class _ArchiveRow extends ConsumerWidget {
  const _ArchiveRow(this.poll, this.lt);
  final Poll poll;
  final LocalTime lt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final results = ref.watch(pollResultsProvider(poll.id)).value;
    final total = results?.total;
    return InkWell(
      onTap: () => context.push(Routes.poll(poll.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pollWeekOf(LocalTime.civil(poll.semaine, context.localeName)), style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(poll.question, style: const TextStyle(fontWeight: FontWeight.w500, height: 1.3)),
            const SizedBox(height: 8),
            if (total != null && total.nCellule > 0) ...[
              for (final o in poll.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      SizedBox(width: 36, child: Text('${(total.fraction(o.id) * 100).round()} %', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      Expanded(child: PercentBar(fraction: total.fraction(o.id), height: 4, color: o.neutre ? scheme.onSurfaceVariant : scheme.primary)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(o.libelle, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(l10n.pollRespondents(total.nCellule), style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ] else
              Text(l10n.pollRespondents(poll.repondants), style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            const Hairline(),
          ],
        ),
      ),
    );
  }
}
