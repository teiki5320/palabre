import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/push_service.dart';
import '../../core/profile/profile.dart';
import '../../core/widgets/widgets.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = ref.watch(localeSettingProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: SectionTitle(l10n.settingsProfile)),
          const SizedBox(height: 360, child: ProfileForm()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: SectionTitle(l10n.settingsLanguage)),
          for (final entry in [(null, l10n.languageSystem), ('fr', l10n.languageFr), ('en', l10n.languageEn), ('wo', l10n.languageWo)])
            RadioListTile<String?>(
              value: entry.$1,
              // ignore: deprecated_member_use
              groupValue: locale,
              title: Text(entry.$2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              // ignore: deprecated_member_use
              onChanged: (v) => ref.read(localeSettingProvider.notifier).set(v),
            ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: SectionTitle(l10n.settingsNotifications)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(PushService.available ? l10n.settingsNotificationsDesc : l10n.settingsNotificationsUnavailable, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: SectionTitle(l10n.settingsAbout)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(l10n.settingsAboutText, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(l10n.settingsVersion('0.1.0'), style: TextStyle(fontSize: 12, color: scheme.outline)),
          ),
        ],
      ),
    );
  }
}
