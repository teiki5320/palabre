// ignore_for_file: sort_child_properties_last
import 'dart:async';

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
import 'poll_models.dart';
import 'poll_providers.dart';
import 'poll_widgets.dart';
import 'refine_profile_card.dart';

/// Onglet 1 : la question de la semaine en une carte, le contexte replié
/// dessous, puis l'archive des semaines précédentes (sans elle, l'onglet est
/// vide six jours sur sept). Sur écran large, contexte et archive passent à
/// droite.
class PollTab extends ConsumerStatefulWidget {
  const PollTab({super.key});

  @override
  ConsumerState<PollTab> createState() => _PollTabState();
}

class _PollTabState extends ConsumerState<PollTab> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // Le compte à rebours du bandeau se rafraîchit chaque minute.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final code = ref.watch(selectedCountryProvider);
    final feed = ref.watch(pollFeedProvider(code));
    final module = ref.watch(moduleStateProvider(AppModule.poll));
    final offline = ref.watch(pollFeedProvider(code).notifier).offline;
    final current = feed.value?.current;

    final suspended = module != null && !module.actif;
    final eyebrow = suspended || current == null ? null : l10n.pollWeekOf(LocalTime.civil(current.semaine, context.localeName));
    final clock = suspended || current == null ? null : pollStatusLine(context, ref, current);
    final title = current == null ? l10n.tabQuestion : current.question;

    List<Widget> children;
    List<Widget> side = const [];
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
      final result = feed.when(
        loading: () => (const [SoftCard(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))))], const <Widget>[]),
        error: (e, _) => (
          [
            SoftCard(
              child: ErrorRetry(
                message: e is NotConfiguredException ? l10n.notConfigured : l10n.errorGeneric,
                onRetry: () => ref.invalidate(pollFeedProvider(code)),
              ),
            ),
          ],
          const <Widget>[]
        ),
        data: (f) {
          final voted = f.current == null ? false : ref.watch(myVoteProvider(f.current!.id)).value != null;
          final main = <Widget>[
            if (offline || !Env.isConfigured)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NoticeBanner(text: Env.isConfigured ? l10n.offlineNotice : l10n.notConfigured, icon: Icons.cloud_off_outlined),
              ),
            if (f.current == null)
              SoftCard(child: EmptyState(icon: Icons.forum_outlined, title: l10n.pollNoCurrent, subtitle: l10n.pollNoCurrentHint))
            else ...[
              PollCard(f.current!),
              RefineProfileCard(visible: voted),
            ],
          ];
          final sideList = <Widget>[
            const SizedBox(height: 4),
            PosterList(
              children: [
                if (f.current != null) PollContextCard(f.current!),
                _ArchiveRow(archive: f.archive),
              ],
            ),
          ];
          return (main, sideList);
        },
      );
      children = result.$1;
      side = result.$2;
    }

    return BandScaffold(
      brand: true,
      eyebrow: eyebrow,
      clock: clock,
      title: title,
      actions: const [SettingsAction()],
      onRefresh: () => ref.read(pollFeedProvider(code).notifier).refresh(),
      children: children,
      sideChildren: side,
    );
  }
}

/// « Semaines précédentes » : ligne affiche repliable qui liste l'archive.
class _ArchiveRow extends StatefulWidget {
  const _ArchiveRow({required this.archive});
  final List<Poll> archive;

  @override
  State<_ArchiveRow> createState() => _ArchiveRowState();
}

class _ArchiveRowState extends State<_ArchiveRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PosterRow(
          icon: Icons.history,
          label: l10n.pollArchive,
          onTap: () => setState(() => _open = !_open),
          trailingWidget: AnimatedRotation(turns: _open ? 0.25 : 0, duration: const Duration(milliseconds: 200), child: Icon(Icons.chevron_right, size: 22, color: t.muted)),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: widget.archive.isEmpty
                ? Padding(padding: const EdgeInsets.fromLTRB(30, 0, 0, 8), child: Text(l10n.pollArchiveEmpty, style: PalabreType.note(t.muted)))
                : Column(children: [for (final p in widget.archive) ArchiveCard(p)]),
          ),
        ),
      ],
    );
  }
}
