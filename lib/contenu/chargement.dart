import 'dart:convert';

import 'package:flutter/services.dart';

import '../moteur/modeles.dart';

/// Tout le contenu du jeu, lu une fois au démarrage.
class Contenu {
  const Contenu({
    required this.cartes,
    required this.personnages,
    required this.parcours,
    required this.fins,
  });

  final List<Carte> cartes;
  final Map<String, Personnage> personnages;
  final List<Parcours> parcours;
  final List<Fin> fins;

  static List<Map<String, dynamic>> _liste(String source) =>
      (jsonDecode(source) as List).cast<Map<String, dynamic>>();

  static Contenu depuisChaines({
    required String cartes,
    required String personnages,
    required String parcours,
    required String fins,
  }) {
    final gens = [for (final j in _liste(personnages)) Personnage.depuisJson(j)];
    return Contenu(
      cartes: [for (final j in _liste(cartes)) Carte.depuisJson(j)],
      personnages: {for (final p in gens) p.id: p},
      parcours: [for (final j in _liste(parcours)) Parcours.depuisJson(j)],
      fins: [for (final j in _liste(fins)) Fin.depuisJson(j)],
    );
  }

  static Future<Contenu> depuisAssets(AssetBundle bundle) async {
    Future<String> lis(String nom) => bundle.loadString('assets/contenu/$nom.json');
    return depuisChaines(
      cartes: await lis('cartes'),
      personnages: await lis('personnages'),
      parcours: await lis('parcours'),
      fins: await lis('fins'),
    );
  }

  Parcours? parcoursParId(String id) {
    for (final p in parcours) {
      if (p.id == id) return p;
    }
    return null;
  }
}
