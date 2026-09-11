import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Le wolof n'a pas de traductions Material/Cupertino dans Flutter : les
/// libellés système (boutons de dialogue, dates du sélecteur…) reprennent le
/// français. Les chaînes de l'app, elles, viennent de app_wo.arb.
const _fallback = Locale('fr');
const _wolof = 'wo';

class WolofMaterialLocalizations extends LocalizationsDelegate<MaterialLocalizations> {
  const WolofMaterialLocalizations();
  @override
  bool isSupported(Locale locale) => locale.languageCode == _wolof;
  @override
  Future<MaterialLocalizations> load(Locale locale) => GlobalMaterialLocalizations.delegate.load(_fallback);
  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}

class WolofCupertinoLocalizations extends LocalizationsDelegate<CupertinoLocalizations> {
  const WolofCupertinoLocalizations();
  @override
  bool isSupported(Locale locale) => locale.languageCode == _wolof;
  @override
  Future<CupertinoLocalizations> load(Locale locale) => GlobalCupertinoLocalizations.delegate.load(_fallback);
  @override
  bool shouldReload(covariant LocalizationsDelegate<CupertinoLocalizations> old) => false;
}

class WolofWidgetsLocalizations extends LocalizationsDelegate<WidgetsLocalizations> {
  const WolofWidgetsLocalizations();
  @override
  bool isSupported(Locale locale) => locale.languageCode == _wolof;
  @override
  Future<WidgetsLocalizations> load(Locale locale) => GlobalWidgetsLocalizations.delegate.load(_fallback);
  @override
  bool shouldReload(covariant LocalizationsDelegate<WidgetsLocalizations> old) => false;
}

/// Locale à passer à `intl` pour les dates : le wolof n'y existe pas.
String intlLocaleFor(Locale locale) => locale.languageCode == _wolof ? 'fr' : locale.toString();
