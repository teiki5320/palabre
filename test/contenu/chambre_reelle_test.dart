import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/decor.dart';
import 'package:president/moteur/dits.dart';

/// Ce qui se dit vraiment dans la chambre, relu comme le jeu le lit.
void main() {
  final dits = DitsDeLaChambre.depuisJson(
      File('assets/contenu/chambre.json').readAsStringSync());

  test('les dix personnes qu on peut courtiser ont toutes leurs repliques', () {
    for (final qui in chambresPartagees) {
      for (final marie in [false, true]) {
        for (final temps in TempsChambre.values) {
          expect(dits.dit(qui, marie: marie, temps: temps), isNotNull,
              reason: '$qui : il manque ${temps.name} '
                  '${marie ? 'une fois marie' : 'pendant la liaison'}');
        }
      }
    }
  });

  test('personne ne parle depuis une chambre qui n existe pas', () {
    expect(dits.personnes.toSet().difference(chambresPartagees), isEmpty);
  });

  test('la replique du lit reste courte : elle s affiche pendant l image', () {
    for (final qui in chambresPartagees) {
      for (final marie in [false, true]) {
        final ligne = dits.dit(qui, marie: marie, temps: TempsChambre.lit)!;
        expect(ligne.length, lessThanOrEqualTo(40), reason: '$qui : « $ligne »');
      }
    }
  });

  test('aucune replique ne deborde de l ecran', () {
    for (final qui in chambresPartagees) {
      for (final marie in [false, true]) {
        for (final temps in TempsChambre.values) {
          final ligne = dits.dit(qui, marie: marie, temps: temps)!;
          // « Madame la Presidente » est le plus long titre que le jeu
          // puisse poser : c est sur lui qu on mesure.
          final pose = ligne
              .replaceAll('{titre}', 'Madame la Presidente')
              .replaceAll('{nom}', 'Idriss');
          expect(pose.length, lessThanOrEqualTo(90), reason: '$qui : « $pose »');
        }
      }
    }
  });

  test('les seules marques posees sont le titre et le nom', () {
    final marque = RegExp(r'\{([a-z_]+)\}');
    for (final qui in chambresPartagees) {
      for (final marie in [false, true]) {
        for (final temps in TempsChambre.values) {
          for (final m in marque.allMatches(dits.dit(qui, marie: marie, temps: temps)!)) {
            expect(['titre', 'nom'], contains(m.group(1)), reason: '$qui : ${m.group(0)}');
          }
        }
      }
    }
  });
}
