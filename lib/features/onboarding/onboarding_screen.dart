import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/country/country_models.dart';
import '../../core/country/country_providers.dart';
import '../../core/profile/profile.dart';
import '../../core/widgets/widgets.dart';

/// Deux écrans : le principe en une phrase, puis pays, tranche d'âge et
/// région. Tout est facultatif sauf le pays.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            _PrinciplePage(onNext: () => _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut)),
            const ProfileForm(onboarding: true),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [for (var i = 0; i < 2; i++) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ColorDot(i == _page ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, size: 6))],
        ),
      ),
    );
  }
}

class _PrinciplePage extends StatelessWidget {
  const _PrinciplePage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Palabre', style: TextStyle(fontSize: 13, letterSpacing: 2.5, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Text(l10n.onboardingTitle, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15)),
          const SizedBox(height: 20),
          Text(l10n.onboardingPrinciple, style: const TextStyle(fontSize: 18, height: 1.45)),
          const SizedBox(height: 16),
          Text(l10n.onboardingNoOpinion, style: TextStyle(fontSize: 15, height: 1.45, color: scheme.onSurfaceVariant)),
          const Spacer(),
          FilledButton(onPressed: onNext, child: Text(l10n.continueLabel)),
        ],
      ),
    );
  }
}

/// Formulaire de profil, partagé entre l'onboarding et les paramètres.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key, this.onboarding = false});
  final bool onboarding;

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
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.settingsSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final config = ref.watch(countryConfigOrFallbackProvider);
    final countries = config.countries.where((c) => c.actif).toList();
    if (!countries.any((c) => c.code == _country) && countries.isNotEmpty) _country = countries.first.code;
    final regions = config.regionsOf(_country);
    if (_regionId != null && !regions.any((r) => r.id == _regionId)) _regionId = null;

    return ListView(
      padding: EdgeInsets.fromLTRB(24, widget.onboarding ? 48 : 8, 24, 24),
      children: [
        if (widget.onboarding) ...[
          Text(l10n.onboardingProfileTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 12),
          Text(l10n.onboardingProfileWhy(30), style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 28),
        ],
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
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: _age,
          decoration: InputDecoration(labelText: l10n.fieldAge),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.notSpecified, style: TextStyle(color: scheme.onSurfaceVariant))),
            for (final a in ageBrackets) DropdownMenuItem(value: a, child: Text(a)),
          ],
          onChanged: (v) => setState(() => _age = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          initialValue: _regionId,
          decoration: InputDecoration(labelText: l10n.fieldRegion),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.notSpecified, style: TextStyle(color: scheme.onSurfaceVariant))),
            for (final r in regions) DropdownMenuItem(value: r.id, child: Text(r.nom)),
          ],
          onChanged: (v) => setState(() => _regionId = v),
        ),
        const SizedBox(height: 32),
        FilledButton(onPressed: _busy ? null : _save, child: Text(widget.onboarding ? l10n.start : l10n.save)),
      ],
    );
  }
}
