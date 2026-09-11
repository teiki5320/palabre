import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/country/country_models.dart';
import '../../core/country/country_providers.dart';
import '../../core/profile/profile.dart';
import '../../core/widgets/widgets.dart';

Widget _narrow(Widget child) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: BandScaffold.maxWidth), child: child),
    );

/// Un seul écran : le principe en une phrase et le pays. Tranche d'âge et
/// région sont proposées plus tard, après le premier vote.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: _narrow(
          ListView(
            padding: const EdgeInsets.fromLTRB(BandScaffold.side, 28, BandScaffold.side, 32),
            children: [
              Text('Palabre', style: PalabreType.wordmark(t.primary)),
              const SizedBox(height: 28),
              Text(l10n.onboardingTitle, style: PalabreType.poster(t.ink)),
              const SizedBox(height: 14),
              Container(width: 56, height: 6, decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 18),
              Text(l10n.onboardingPrinciple, style: TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600, color: t.ink)),
              const SizedBox(height: 28),
              const SoftCard(child: ProfileForm(onboarding: true)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formulaire de profil. En onboarding : le pays seul. Ailleurs : tranche
/// d'âge et région, avec ou sans le pays. Tout est facultatif sauf le pays.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key, this.onboarding = false, this.showCountry = true, this.secondaryAction, this.onSaved, this.saveLabel});
  final bool onboarding;
  final bool showCountry;

  /// Rendu à côté du bouton d'enregistrement (« Plus tard »).
  final Widget? secondaryAction;
  final VoidCallback? onSaved;
  final String? saveLabel;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  late String _country;
  String? _age;
  int? _regionId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _country = p.countryCode;
    _age = p.trancheAge;
    _regionId = p.regionId;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    await ref.read(profileProvider.notifier).save(Profile(countryCode: _country, trancheAge: _age, regionId: _regionId));
    if (!mounted) return;
    if (widget.onboarding) {
      await ref.read(onboardingDoneProvider.notifier).complete();
      if (mounted) context.go(Routes.question);
      return;
    }
    setState(() => _busy = false);
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.settingsSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final config = ref.watch(countryConfigOrFallbackProvider);
    final countries = config.countries.where((c) => c.actif).toList();
    if (!countries.any((c) => c.code == _country) && countries.isNotEmpty) _country = countries.first.code;
    final regions = config.regionsOf(_country);
    if (_regionId != null && !regions.any((r) => r.id == _regionId)) _regionId = null;
    final showCountry = widget.onboarding || widget.showCountry;
    final showDetails = !widget.onboarding;

    final saveButton = ActionButton(
      label: widget.saveLabel ?? (widget.onboarding ? l10n.start : l10n.save),
      busy: _busy,
      onPressed: _busy ? null : _save,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCountry) ...[
          DropdownButtonFormField<String>(
            initialValue: countries.any((c) => c.code == _country) ? _country : null,
            decoration: InputDecoration(labelText: l10n.fieldCountry),
            items: [
              for (final c in countries) DropdownMenuItem(value: c.code, child: Text(c.nom)),
              if (countries.isEmpty) DropdownMenuItem(value: _country, child: Text(_country)),
            ],
            onChanged: (v) => setState(() {
              _country = v ?? _country;
              _regionId = null;
            }),
          ),
          const SizedBox(height: 14),
        ],
        if (showDetails) ...[
          DropdownButtonFormField<String?>(
            initialValue: _age,
            decoration: InputDecoration(labelText: l10n.fieldAge),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l10n.notSpecified, style: TextStyle(color: t.muted)),
              ),
              for (final a in ageBrackets) DropdownMenuItem(value: a, child: Text(a)),
            ],
            onChanged: (v) => setState(() => _age = v),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int?>(
            initialValue: _regionId,
            decoration: InputDecoration(labelText: l10n.fieldRegion),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l10n.notSpecified, style: TextStyle(color: t.muted)),
              ),
              for (final r in regions) DropdownMenuItem(value: r.id, child: Text(r.nom)),
            ],
            onChanged: (v) => setState(() => _regionId = v),
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 6),
        if (widget.secondaryAction == null)
          saveButton
        else
          Row(
            children: [
              Expanded(child: widget.secondaryAction!),
              const SizedBox(width: 10),
              Expanded(child: saveButton),
            ],
          ),
      ],
    );
  }
}
