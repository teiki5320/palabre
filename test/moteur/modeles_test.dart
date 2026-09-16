import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';

void main() {
  test('une carte se lit depuis son JSON', () {
    final j = jsonDecode('''
    {
      "id": "general_solde_1",
      "personnage": "general",
      "humeur": "fache",
      "texte": "La solde a deux mois de retard.",
      "gauche": { "libelle": "Qu ils patientent", "effets": { "armee": -15, "caisses": 5 }, "drapeaux": ["solde_impayee"] },
      "droite": { "libelle": "On paie", "effets": { "armee": 10, "caisses": -15 } },
      "conditions": { "jour_min": 3, "caisses_max": 80 },
      "poids": 3,
      "chaine": { "id": "solde", "rang": 1, "delai_min": 4 }
    }
    ''') as Map<String, dynamic>;

    final c = Carte.depuisJson(j);
    expect(c.id, 'general_solde_1');
    expect(c.humeur, Humeur.fache);
    expect(c.gauche.effets[Jauge.armee], -15);
    expect(c.gauche.drapeaux, ['solde_impayee']);
    expect(c.droite.drapeaux, isEmpty);
    expect(c.conditions.jourMin, 3);
    expect(c.conditions.maximums[Jauge.caisses], 80);
    expect(c.poids, 3);
    expect(c.chaine!.rang, 1);
    expect(c.chaine!.delaiMin, 4);
    expect(c.repetable, isFalse);
  });

  test('les champs absents prennent leur valeur par defaut', () {
    final c = Carte.depuisJson(jsonDecode('''
    {
      "id": "x", "personnage": "p", "humeur": "neutre", "texte": "t",
      "gauche": { "libelle": "a", "effets": { "peuple": 1 } },
      "droite": { "libelle": "b", "effets": { "peuple": -1 } }
    }
    ''') as Map<String, dynamic>);
    expect(c.poids, 1);
    expect(c.chaine, isNull);
    expect(c.conditions.mandatMin, 1);
    expect(c.conditions.jourMin, 1);
    expect(c.conditions.parcours, isEmpty);
  });

  test('un parcours se lit depuis son JSON', () {
    final p = Parcours.depuisJson(jsonDecode('''
    {
      "id": "general", "nom": "L ancien general", "titre": "Monsieur le President",
      "femme": false, "depart": { "peuple": 40, "armee": 70, "caisses": 50, "presse": 40 }
    }
    ''') as Map<String, dynamic>);
    expect(p.depart.armee, 70);
    expect(p.femme, isFalse);
    expect(p.conditionDeblocage, isNull);
  });

  test('une fin se lit depuis son JSON', () {
    final f = Fin.depuisJson(jsonDecode('''
    { "id": "armee_bas", "jauge": "armee", "vers_le_haut": false, "titre": "Le palais est pris",
      "texte": "Les blindes sont entres a l aube.", "image": "fins/coup.jpg" }
    ''') as Map<String, dynamic>);
    expect(f.jauge, Jauge.armee);
    expect(f.versLeHaut, isFalse);
  });
}
