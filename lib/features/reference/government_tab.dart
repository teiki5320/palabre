import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/country/country_models.dart';
import '../../core/country/country_providers.dart';
import '../../core/net/cached_notifier.dart';
import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import 'reference_models.dart';
import 'reference_providers.dart';

/// Onglet 3 : le curseur temporel dans le bandeau, les points marquent les
/// remaniements ; en dessous, une carte par bloc, couleur par bloc. On fait
/// glisser, la grille se recompose.
class GovernmentTab extends ConsumerWidget {
  const GovernmentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final code = ref.watch(selectedCountryProvider);
    final reference = ref.watch(referenceProvider(code));
    final module = ref.watch(moduleStateProvider(AppModule.government));
    final date = ref.watch(governmentDateProvider);
    final today = dayOnly(DateTime.now());
    final isToday = !date.isBefore(today);
    final bundle = reference.value;
    final suspended = module != null && !module.actif;

    final dateLabel = l10n.govAt(LocalTime.civil(date, context.localeName));
    final title = isToday ? '$dateLabel · ${l10n.govToday}' : dateLabel;

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
      children = reference.when(
        loading: () => const [SoftCard(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))))],
        error: (e, _) => [
          SoftCard(child: ErrorRetry(message: e is NotConfiguredException ? l10n.notConfigured : l10n.errorGeneric, onRetry: () => ref.invalidate(referenceProvider(code)))),
        ],
        data: (b) {
          if (b.governments.isEmpty) return [SoftCard(child: EmptyState(icon: Icons.account_balance_outlined, title: l10n.govNoData, subtitle: l10n.govNoDataHint))];
          final composition = b.governmentAt(date);
          return [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(a), child: child)),
              layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
              child: Column(
                key: ValueKey(composition?.government.id ?? -1),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: composition == null ? [SoftCard(child: EmptyState(icon: Icons.history, title: l10n.govNone))] : _compositionCards(context, composition),
              ),
            ),
          ];
        },
      );
    }

    return BandScaffold(
      color: t.government,
      onColor: t.onGovernment,
      brand: true,
      eyebrow: l10n.tabGovernment,
      title: title,
      actions: const [SettingsAction()],
      control: bundle == null || bundle.governments.isEmpty || suspended ? null : _TimeSlider(bundle: bundle, date: date),
      children: children,
    );
  }

  List<Widget> _compositionCards(BuildContext context, GovernmentComposition composition) {
    final l10n = context.l10n;
    final t = context.tokens;
    final g = composition.government;
    final blocs = composition.byBloc;
    const order = [null, 'regalien', 'economie', 'social', 'infrastructure'];
    final keys = [...order.where(blocs.containsKey), ...blocs.keys.where((k) => !order.contains(k))];
    final coverage = g.portefeuillesTotal == null
        ? l10n.govCoverageUnknown(composition.portefeuillesRenseignes)
        : l10n.govCoverage(composition.portefeuillesRenseignes, g.portefeuillesTotal!);
    return [
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.nom, style: PalabreType.cardTitle(t.ink)),
            const SizedBox(height: 4),
            Text(
              g.fin == null
                  ? l10n.govSince(LocalTime.civil(g.debut, context.localeName))
                  : l10n.govFromTo(LocalTime.civil(g.debut, context.localeName), LocalTime.civil(g.fin!, context.localeName)),
              style: PalabreType.note(t.muted),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text(coverage, style: PalabreType.note(t.muted))),
                SourceLink(url: g.sourceUrl, label: g.decretRef ?? l10n.source, dense: true),
              ],
            ),
          ],
        ),
      ),
      for (final bloc in keys)
        CardSection(
          title: '',
          leading: Pill(label: bloc == null ? l10n.govHead : blocLabel(context, bloc), icon: null, trailing: null),
          trailing: ColorDot(bloc == null ? t.ink : blocColor(bloc), size: 10),
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final cols = bloc == null ? 1 : (c.maxWidth / 190).floor().clamp(3, 6);
                final w = bloc == null ? c.maxWidth : (c.maxWidth - 12 * (cols - 1)) / cols;
                return Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: [
                    for (final e in blocs[bloc]!)
                      SizedBox(width: w, child: _PortraitCell(e, bloc == null ? t.primary : blocColor(bloc), wide: bloc == null)),
                  ],
                );
              },
            ),
          ],
        ),
    ];
  }
}

class _TimeSlider extends ConsumerWidget {
  const _TimeSlider({required this.bundle, required this.date});
  final ReferenceBundle bundle;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final today = dayOnly(DateTime.now());
    final min = dayOnly(bundle.earliestDate ?? today);
    final span = today.difference(min).inDays;
    final value = date.difference(min).inDays.clamp(0, span).toDouble();
    final max = span <= 0 ? 1.0 : span.toDouble();
    final marks = <double>{
      for (final g in bundle.governments) dayOnly(g.debut).difference(min).inDays.clamp(0, span).toDouble(),
    }.toList()
      ..sort();

    void set(double v) {
      // Aimanté sur un remaniement s'il est à moins de 3 % de la course.
      var d = v;
      for (final m in marks) {
        if ((m - v).abs() <= max * 0.03) d = m;
      }
      ref.read(governmentDateProvider.notifier).set(min.add(Duration(days: d.round())));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            const pad = 12.0;
            final usable = c.maxWidth - 2 * pad;
            return SizedBox(
              height: 40,
              child: Stack(
                children: [
                  for (final m in marks)
                    Positioned(
                      left: pad + usable * (m / max) - 3,
                      bottom: 4,
                      child: Container(width: 6, height: 6, decoration: BoxDecoration(color: t.ink, borderRadius: BorderRadius.circular(1.5))),
                    ),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      activeTrackColor: t.government,
                      inactiveTrackColor: t.line,
                      thumbColor: t.card,
                      overlayColor: t.government.withValues(alpha: 0.15),
                      thumbShape: _PosterThumb(border: t.border, shadow: t.isDark ? t.government : t.hardShadow),
                      trackShape: const RoundedRectSliderTrackShape(),
                      padding: const EdgeInsets.symmetric(horizontal: pad),
                    ),
                    child: Slider(
                      value: value,
                      min: 0,
                      max: max,
                      onChanged: span <= 0 ? null : (v) => ref.read(governmentDateProvider.notifier).set(min.add(Duration(days: v.round()))),
                      onChangeEnd: span <= 0 ? null : set,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Row(
          children: [
            Text(LocalTime.civilShort(min, context.localeName), style: PalabreType.note(t.muted)),
            Expanded(child: Text(l10n.govSliderHint, textAlign: TextAlign.center, style: PalabreType.note(t.muted))),
            GestureDetector(
              onTap: () => ref.read(governmentDateProvider.notifier).set(today),
              child: Text(l10n.govToday, style: PalabreType.note(t.ink).copyWith(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ],
    );
  }
}

class _PortraitCell extends StatelessWidget {
  const _PortraitCell(this.entry, this.color, {this.wide = false});
  final GovernmentEntry entry;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final name = Text(entry.person.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: wide ? 15 : 12.5, fontWeight: FontWeight.w700, height: 1.2, color: t.ink));
    final role = Text(entry.intitule, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: wide ? 13 : 11, color: t.muted, height: 1.25, fontWeight: FontWeight.w500));
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(Routes.person(entry.person.id)),
      child: wide
          ? Row(
              children: [
                PersonAvatar(nom: entry.person.nom, photoUrl: entry.person.photoUrl, size: 64, color: color),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [name, const SizedBox(height: 3), role])),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(builder: (_, c) => PersonAvatar(nom: entry.person.nom, photoUrl: entry.person.photoUrl, size: c.maxWidth, color: color)),
                ),
                const SizedBox(height: 6),
                name,
                const SizedBox(height: 2),
                role,
              ],
            ),
    );
  }
}

/// Pouce du curseur : cercle 18 px, fond carte, bord 2 px, ombre dure 2/2.
class _PosterThumb extends SliderComponentShape {
  const _PosterThumb({required this.border, required this.shadow});
  final Color border;
  final Color shadow;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(22, 22);

  @override
  void paint(PaintingContext context, Offset center, {required Animation<double> activationAnimation, required Animation<double> enableAnimation, required bool isDiscrete, required TextPainter labelPainter, required RenderBox parentBox, required SliderThemeData sliderTheme, required TextDirection textDirection, required double value, required double textScaleFactor, required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    const r = 9.0;
    canvas.drawCircle(center + const Offset(2, 2), r, Paint()..color = shadow);
    canvas.drawCircle(center, r, Paint()..color = sliderTheme.thumbColor ?? Colors.white);
    canvas.drawCircle(center, r - 1, Paint()..color = border..style = PaintingStyle.stroke..strokeWidth = 2);
  }
}
