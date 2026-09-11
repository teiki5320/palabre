import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/prefs/theme_mode_provider.dart';
import '../core/profile/profile.dart';
import '../l10n/generated/app_localizations.dart';
import 'locale_fallbacks.dart';
import '../core/widgets/band_scaffold.dart';
import 'router.dart';
import 'theme.dart';

class PalabreApp extends ConsumerWidget {
  const PalabreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final localeCode = ref.watch(localeSettingProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Palabre',
      debugShowCheckedModeBanner: false,
      theme: PalabreTheme.light(),
      darkTheme: PalabreTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      // Sur iPad, tout l'affichage grandit d'un cran : texte, cartes, boutons.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final wide = mq.size.width >= BandScaffold.wideBreakpoint;
        if (!wide) return child!;
        return MediaQuery(data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 1.18, maxScaleFactor: 2.0)), child: child!);
      },
      locale: localeCode == null ? null : Locale(localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // Les délégués wolof passent avant les globaux : premier qui accepte gagne.
        WolofMaterialLocalizations(),
        WolofCupertinoLocalizations(),
        WolofWidgetsLocalizations(),
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
