import 'dart:convert';

import 'package:flutter/services.dart';

import '../moteur/memoire.dart';
import '../moteur/modeles.dart';
import '../moteur/palais.dart';
import '../moteur/progression.dart';

/// Tout le contenu du jeu, lu une fois au démarrage.
class Contenu {
  const Contenu({
    required this.cartes,
    required this.personnages,
    required this.parcours,
    required this.fins,
    this.exploits = const [],
    this.objets = const [],
    this.adversaires = const [],
  });

  final List<Carte> cartes;
  final Map<String, Personnage> personnages;

  /// Identifiant que les cartes emploient pour l'époux ou l'épouse du
  /// joueur : il n'existe pas dans le fichier des personnages, il se résout
  /// selon le parcours — une présidente a un époux, un président une épouse.
  static const conjoint = 'conjoint';

  /// Qui parle sur cette carte, pour ce joueur.
  Personnage? personnageDe(Carte carte, Parcours? parcours) {
    if (carte.personnage != conjoint) return personnages[carte.personnage];
    return personnages[(parcours?.femme ?? false) ? 'epoux' : 'epouse'];
  }
  final List<Parcours> parcours;
  final List<Fin> fins;

  /// Vide par défaut pour ne pas casser les appels existants de
  /// [depuisChaines] qui ne passent pas ce paramètre.
  final List<Exploit> exploits;

  /// Le catalogue du palais. Vide par défaut, pour la même raison.
  final List<Objet> objets;

  /// Ceux qui peuvent se présenter contre vous. Vide par défaut : une
  /// partie sans opposant se joue comme avant, l'élection se décidant
  /// alors sur la force de départ.
  final List<Adversaire> adversaires;

  Adversaire? adversaireParId(String? id) {
    if (id == null) return null;
    for (final a in adversaires) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Les objets d'une pièce, dans l'ordre du moins cher au plus cher :
  /// c'est l'ordre dans lequel on les découvre, et celui dans lequel on
  /// peut se les offrir.
  List<Objet> objetsDe(Piece piece) =>
      [for (final o in objets) if (o.piece == piece) o]..sort((a, b) => a.prix.compareTo(b.prix));

  Objet? objetParId(String id) {
    for (final o in objets) {
      if (o.id == id) return o;
    }
    return null;
  }

  static List<Map<String, dynamic>> _liste(String source) =>
      (jsonDecode(source) as List).cast<Map<String, dynamic>>();

  static Contenu depuisChaines({
    required String cartes,
    required String personnages,
    required String parcours,
    required String fins,
    String exploits = '',
    String objets = '',
    String adversaires = '',
  }) {
    final gens = [for (final j in _liste(personnages)) Personnage.depuisJson(j)];
    return Contenu(
      cartes: [for (final j in _liste(cartes)) Carte.depuisJson(j)],
      personnages: {for (final p in gens) p.id: p},
      parcours: [for (final j in _liste(parcours)) Parcours.depuisJson(j)],
      fins: [for (final j in _liste(fins)) Fin.depuisJson(j)],
      exploits: exploits.isEmpty ? const [] : [for (final j in _liste(exploits)) Exploit.depuisJson(j)],
      objets: objets.isEmpty ? const [] : [for (final j in _liste(objets)) Objet.depuisJson(j)],
      adversaires:
          adversaires.isEmpty ? const [] : [for (final j in _liste(adversaires)) Adversaire.depuisJson(j)],
    );
  }

  static Future<Contenu> depuisAssets(AssetBundle bundle) async {
    Future<String> lis(String nom) => bundle.loadString('assets/contenu/$nom.json');
    return depuisChaines(
      cartes: await lis('cartes'),
      personnages: await lis('personnages'),
      parcours: await lis('parcours'),
      fins: await lis('fins'),
      exploits: await lis('exploits'),
      objets: await lis('objets'),
      adversaires: await lis('adversaires'),
    );
  }

  Parcours? parcoursParId(String id) {
    for (final p in parcours) {
      if (p.id == id) return p;
    }
    return null;
  }
}
