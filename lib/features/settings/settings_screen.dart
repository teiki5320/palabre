import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/notifications/push_service.dart';
import '../../core/prefs/theme_mode_provider.dart';
import '../../core/profile/profile.dart';
import '../../core/widgets/widgets.dart';
import '../onboarding/onboarding_screen.dart';

/// Version affichée ; suit `version` de pubspec.yaml.
const appVersion = '0.2.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final locale = ref.watch(localeSettingProvider);
    final themeMode = ref.watch(themeModeProvider);

    Widget radio<T>(T value, String label) => RadioListTile<T>(
          value: value,
          title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: t.ink)),
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: VisualDensity.compact,
        );

    return BandScaffold(
      title: l10n.settings,
      children: [
        CardSection(
          title: l10n.settingsAppearance,
          children: [
            RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (v) => ref.read(themeModeProvider.notifier).set(v ?? ThemeMode.system),
              child: Column(
                children: [
                  radio(ThemeMode.system, l10n.themeSystem),
                  radio(ThemeMode.light, l10n.themeLight),
                  radio(ThemeMode.dark, l10n.themeDark),
                ],
              ),
            ),
          ],
        ),
        CardSection(title: l10n.settingsProfile, children: const [ProfileForm()]),
        CardSection(
          title: l10n.settingsLanguage,
          children: [
            RadioGroup<String?>(
              groupValue: locale,
              onChanged: (v) => ref.read(localeSettingProvider.notifier).set(v),
              child: Column(
                children: [
                  radio<String?>(null, l10n.languageSystem),
                  radio<String?>('fr', l10n.languageFr),
                  radio<String?>('en', l10n.languageEn),
                  radio<String?>('wo', l10n.languageWo),
                ],
              ),
            ),
          ],
        ),
        CardSection(
          title: l10n.settingsNotifications,
          children: [Text(PushService.available ? l10n.settingsNotificationsDesc : l10n.settingsNotificationsUnavailable, style: PalabreType.note(t.muted).copyWith(fontSize: 13))],
        ),
        CardSection(
          title: l10n.settingsAbout,
          children: [
            Text(l10n.settingsAboutText, style: PalabreType.note(t.muted).copyWith(fontSize: 13)),
            const SizedBox(height: 8),
            Text(l10n.settingsVersion(appVersion), style: PalabreType.note(t.muted)),
          ],
        ),
      ],
    );
  }
}
