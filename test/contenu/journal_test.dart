import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les brèves du lendemain : ce que le pays dit d'une réponse. Le jeu tourne
/// sans elles — mais celles qui existent doivent tenir la consigne, sinon
/// elles feront plus de mal que leur absence.
void main() {
  late List<Map<String, dynamic>> cartes;

  setUpAll(() {
    final source = File('assets/contenu/cartes.json').readAsStringSync();
    cartes = (jsonDecode(source) as List).cast<Map<String, dynamic>>();
  });

  Iterable<({String carte, String cote, String ligne})> lignes() sync* {
    for (final c in cartes) {
      for (final cote in ['gauche', 'droite']) {
        final r = c[cote] as Map<String, dynamic>;
        final j = r['journal'] as String?;
        if (j != null) yield (carte: c['id'] as String, cote: cote, ligne: j);
      }
    }
  }

  test('une carte a ses deux brèves ou aucune', () {
    final boiteuses = <String>[];
    for (final c in cartes) {
      final g = (c['gauche'] as Map)['journal'] != null;
      final d = (c['droite'] as Map)['journal'] != null;
      if (g != d) boiteuses.add(c['id'] as String);
    }
    expect(boiteuses, isEmpty, reason: 'brève d\'un seul côté : ${boiteuses.join(', ')}');
  });

  test('aucune brève ne dépasse cent quarante signes', () {
    for (final l in lignes()) {
      expect(l.ligne.length, lessThanOrEqualTo(140), reason: '${l.carte} ${l.cote} : « ${l.ligne} »');
    }
  });

  test('aucune brève ne nomme une jauge', () {
    const interdits = ['peuple vous', 'vos caisses', 'la jauge', 'votre popularité', 'votre cote'];
    for (final l in lignes()) {
      final bas = l.ligne.toLowerCase();
      for (final mot in interdits) {
        expect(bas.contains(mot), isFalse, reason: '${l.carte} ${l.cote} dit « $mot »');
      }
    }
  });

  test('aucune brève ne juge ni ne s exclame', () {
    const interdits = ['hélas', 'malheureusement', 'heureusement', 'hélas'];
    for (final l in lignes()) {
      final bas = l.ligne.toLowerCase();
      expect(l.ligne.contains('!'), isFalse, reason: '${l.carte} ${l.cote} s\'exclame');
      for (final mot in interdits) {
        expect(bas.contains(mot), isFalse, reason: '${l.carte} ${l.cote} dit « $mot »');
      }
    }
  });

  test('aucune brève ne parle de francs', () {
    // Le mot entier, pas la suite de lettres : « franchissent » et
    // « franchise » sont innocents, et un test qui les condamne fait perdre
    // plus de temps qu'il n'en fait gagner.
    final argent = RegExp(r'\bfrancs?\b', caseSensitive: false);
    for (final l in lignes()) {
      expect(argent.hasMatch(l.ligne), isFalse, reason: '${l.carte} ${l.cote} : « ${l.ligne} »');
    }
  });

  test('les deux brèves d une carte ne se ressemblent pas', () {
    for (final c in cartes) {
      final g = (c['gauche'] as Map)['journal'] as String?;
      final d = (c['droite'] as Map)['journal'] as String?;
      if (g == null || d == null) continue;
      expect(g, isNot(d), reason: c['id'] as String);
      // Au-delà de l'égalité stricte : deux brèves qui partagent leurs huit
      // premiers mots racontent la même chose.
      String debut(String s) => s.split(' ').take(8).join(' ').toLowerCase();
      expect(debut(g), isNot(debut(d)), reason: '${c['id']} : mêmes premiers mots');
    }
  });

  test('chaque brève tient en deux phrases au plus', () {
    for (final l in lignes()) {
      final phrases = l.ligne.split(RegExp(r'[.?]')).where((p) => p.trim().isNotEmpty).length;
      expect(phrases, lessThanOrEqualTo(2), reason: '${l.carte} ${l.cote} : $phrases phrases');
    }
  });

  test('la couverture est annoncée', () {
    final couvertes = cartes.where((c) {
      return (c['gauche'] as Map)['journal'] != null && (c['droite'] as Map)['journal'] != null;
    }).length;
    // Ce test ne bloque rien : il imprime où en est le chantier.
    // ignore: avoid_print
    print('Journal : $couvertes cartes sur ${cartes.length}, ${couvertes * 2} brèves écrites.');
    expect(couvertes, greaterThan(0));
  });
}
