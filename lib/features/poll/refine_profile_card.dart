import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/profile/profile.dart';
import '../../core/widgets/widgets.dart';
import '../onboarding/onboarding_screen.dart';

/// Après le premier vote : tranche d'âge et région, facultatives, pour les
/// découpes du sondage. Une fois remplie ou refusée, la carte ne revient pas.
class RefineProfileCard extends ConsumerWidget {
  const RefineProfileCard({super.key, required this.visible});

  /// Vrai quand l'utilisateur a voté au moins une fois.
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(profilePromptDoneProvider);
    final profile = ref.watch(profileProvider);
    if (!visible || done || profile.trancheAge != null || profile.regionId != null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final t = context.tokens;
    void complete() => ref.read(profilePromptDoneProvider.notifier).complete();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.refineTitle, style: PalabreType.cardTitle(t.ink)),
          const SizedBox(height: 6),
          Text(l10n.onboardingProfileWhy(30), style: PalabreType.note(t.muted)),
          const SizedBox(height: 14),
          ProfileForm(
            showCountry: false,
            onSaved: complete,
            secondaryAction: OutlinedButton(onPressed: complete, child: Text(l10n.refineLater)),
          ),
        ],
      ),
    );
  }
}
