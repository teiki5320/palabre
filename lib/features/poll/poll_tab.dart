import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/config/env.dart';
import '../../core/country/country_models.dart';
import '../../core/country/country_providers.dart';
import '../../core/net/cached_notifier.dart';
import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import 'poll_providers.dart';
import 'poll_widgets.dart';
import 'refine_profile_card.dart';

/// Onglet 1 : la question de la semaine en une carte, le contexte replié
/// dessous, puis l'archive des semaines précédentes (sans elle, l'onglet est
/// vide six jours sur sept).
class PollTab extends ConsumerWidget {
  const PollTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final code = ref.watch(selectedCountryProvider);
    final feed = ref.watch(pollFeedProvider(code));
    final module = ref.watch(moduleStateProvider(AppModule.poll));
    final offline = ref.watch(pollFeedProvider(code).notifier).offline;
    final current = feed.value?.current;

    final suspended = module != null && !module.actif;
    final eyebrow = suspended || current == null ? null : pollStatusLine(context, ref, current);
    final title = current == null ? l10n.tabQuestion : l10n.pollWeekOf(LocalTime.civil(current.semaine, context.localeName));

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
    } else {
      children = feed.when(
        loading: () => const [SoftCard(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))))],
        error: (e, _) => [
          SoftCard(
            child: ErrorRetry(
              message: e is NotConfiguredException ? l10n.notConfigured : l10n.errorGeneric,
              onRetry: () => ref.invalidate(pollFeedProvider(code)),
            ),
          ),
        ],
        data: (f) {
          final voted = f.current == null ? false : ref.watch(myVoteProvider(f.current!.id)).value != null;
          return [
            if (offline || !Env.isConfigured)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NoticeBanner(text: Env.isConfigured ? l10n.offlineNotice : l10n.notConfigured, icon: Icons.cloud_off_outlined),
              ),
            if (f.current == null)
              SoftCard(child: Text(l10n.pollNoCurrent, style: TextStyle(color: t.muted, fontWeight: FontWeight.w600)))
            else ...[
              PollCard(f.current!),
              PollContextCard(f.current!),
              RefineProfileCard(visible: voted),
            ],
            SectionTitle(l10n.pollArchive),
            if (f.archive.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(l10n.pollArchiveEmpty, style: TextStyle(color: t.muted)))
            else
              for (final p in f.archive) ArchiveCard(p),
          ];
        },
      );
    }

    return BandScaffold(
      brand: true,
      eyebrow: eyebrow,
      title: title,
      actions: const [SettingsAction()],
      onRefresh: () => ref.read(pollFeedProvider(code).notifier).refresh(),
      children: children,
    );
  }
}
