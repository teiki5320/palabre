import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/profile/profile.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class PalabreApp extends ConsumerWidget {
  const PalabreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final localeCode = ref.watch(localeSettingProvider);
    return MaterialApp.router(
      title: 'Palabre',
      debugShowCheckedModeBanner: false,
      theme: PalabreTheme.dark(),
      darkTheme: PalabreTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      locale: localeCode == null ? null : Locale(localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) {
        if (device == null) return const Locale('fr');
        for (final l in supported) {
          if (l.languageCode == device.languageCode) return l;
        }
        return const Locale('fr');
      },
    );
  }
}
