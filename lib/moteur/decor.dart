import 'etat_partie.dart';
import 'jauges.dart';
import 'palais.dart';

/// Quelle image le palais montre, pour une pièce et un état de partie.
///
/// Tout est ici, et nulle part ailleurs : l'ordre des règles est l'ordre de
/// priorité, la première qui s'applique gagne. C'est volontaire — l'émeute
/// l'emporte sur la liesse, et la ville éteinte sur l'avenue ordinaire,
/// parce qu'un pays en feu n'est pas « aussi » un pays qui circule.
///
/// Rien ici ne connaît Flutter : la règle se teste sans écran.
class Decor {
  const Decor({required this.dossier, required this.etat, required this.nom, this.images = 1});

  /// Le chemin sous `assets/images/palais/`, sans le numéro d'image.
  final String dossier;

  /// L'identifiant de l'état, pour les tests et les traces.
  final String etat;

  /// Ce qu'on en dirait à voix haute.
  final String nom;

  /// Combien d'images composent la boucle : six pour le balcon, une pour
  /// les pièces, qui s'animent autrement.
  final int images;

  String chemin(int i) =>
      images == 1 ? 'assets/images/palais/$dossier.jpg' : 'assets/images/palais/$dossier/k$i.jpg';
}

/// Vrai entre le quatre-vingtième jour et la fin : c'est la seule chose qui
/// fait tomber la nuit sur le palais. Le jeu n'a pas d'horloge — la nuit
/// n'est pas une heure, c'est la fin d'un mandat qui approche et qu'on ne
/// dort plus.
bool estNuit(EtatPartie etat) => etat.jour >= 80;

/// Les dix états de la place, dans leur ordre de priorité.
Decor decorDuBalcon(EtatPartie etat) {
  final j = etat.jauges;
  final heure = estNuit(etat) ? 'nuit' : 'jour';

  // Les deux états de cérémonie passent avant tout le reste : ils sont
  // posés par une carte, donc ils décrivent un jour précis, pas une
  // situation durable. Ils n'existent que de jour.
  if (etat.drapeaux.contains('fete_nationale')) {
    return const Decor(dossier: 'balcon/jour/defile', etat: 'defile', nom: 'Le défilé', images: 6);
  }
  if (etat.drapeaux.contains('deuil_national')) {
    return const Decor(dossier: 'balcon/jour/deuil', etat: 'deuil', nom: 'Le deuil national', images: 6);
  }

  String d(String nom) => 'balcon/$heure/$nom';

  if (j.peuple <= 25) return Decor(dossier: d('emeute'), etat: 'emeute', nom: "L'émeute", images: 6);
  if (j.armee >= 70) {
    return Decor(dossier: d('verrouillee'), etat: 'verrouillee', nom: "L'avenue verrouillée", images: 6);
  }
  if (j.caisses <= 25) {
    return Decor(dossier: d('eteinte'), etat: 'eteinte', nom: 'La ville éteinte', images: 6);
  }
  if (j.presse <= 25) {
    return Decor(dossier: d('cameras'), etat: 'cameras', nom: 'Le siège des caméras', images: 6);
  }
  if (j.peuple >= 70) return Decor(dossier: d('liesse'), etat: 'liesse', nom: 'La liesse', images: 6);
  if (j.caisses >= 65 && j.peuple >= 55) {
    return Decor(dossier: d('prospere'), etat: 'prospere', nom: "L'avenue prospère", images: 6);
  }
  if (etat.jour >= 55 && etat.jour <= 75) {
    return Decor(dossier: d('pluies'), etat: 'pluies', nom: 'La saison des pluies', images: 6);
  }
  return Decor(dossier: d('ordinaire'), etat: 'ordinaire', nom: "L'avenue ordinaire", images: 6);
}

Decor decorDuBureau(EtatPartie etat) {
  if (etat.jauges.presse <= 30) {
    return const Decor(dossier: 'pieces/bureau_enseveli', etat: 'enseveli', nom: 'Enseveli');
  }
  if (etat.style >= 70) {
    return const Decor(dossier: 'pieces/bureau_chef', etat: 'chef', nom: 'Le palais du chef');
  }
  if (etat.style <= 30) {
    return const Decor(dossier: 'pieces/bureau_ouvert', etat: 'ouvert', nom: 'La porte ouverte');
  }
  return const Decor(dossier: 'pieces/bureau_base', etat: 'base', nom: 'Le bureau de travail');
}

Decor decorDeLaChambre(EtatPartie etat) {
  if (estNuit(etat)) {
    return const Decor(dossier: 'pieces/chambre_nuit', etat: 'nuit', nom: 'La nuit blanche');
  }
  if (etat.drapeaux.contains('conjoint')) {
    return const Decor(dossier: 'pieces/chambre_conjoint', etat: 'conjoint', nom: "On n'est pas seul");
  }
  return const Decor(dossier: 'pieces/chambre_base', etat: 'base', nom: 'La chambre');
}

/// Le garage se remplit de ce qu'on a acheté : c'est la seule pièce dont
/// l'état ne dépend pas des jauges mais du palais lui-même.
const _vehicules = {'velo', 'quatre_quatre', 'motos', 'limousine'};

Decor decorDuGarage(Set<String> objets) {
  final combien = objets.where(_vehicules.contains).length;
  if (combien >= 2) {
    return const Decor(dossier: 'pieces/garage_parc', etat: 'parc', nom: 'Le parc');
  }
  return const Decor(dossier: 'pieces/garage_base', etat: 'base', nom: 'La voiture de fonction');
}

Decor decorDeLaPiscine(EtatPartie etat, Set<String> objets) {
  if (objets.contains('dimanche') && etat.style <= 35) {
    return const Decor(dossier: 'pieces/piscine_quartier', etat: 'quartier', nom: 'Le dimanche du quartier');
  }
  if (etat.jauges.caisses <= 15) {
    return const Decor(dossier: 'pieces/piscine_vide', etat: 'vide', nom: 'Le bassin vidé');
  }
  if (etat.jauges.caisses <= 30) {
    return const Decor(dossier: 'pieces/piscine_verte', etat: 'verte', nom: "L'eau verte");
  }
  return const Decor(dossier: 'pieces/piscine_base', etat: 'base', nom: "L'eau claire");
}

/// Le décor d'une pièce quelconque, pour que l'écran n'ait pas à savoir
/// laquelle des cinq fonctions appeler.
Decor decorDe(Piece piece, EtatPartie etat, Set<String> objets) => switch (piece) {
      Piece.balcon => decorDuBalcon(etat),
      Piece.bureau => decorDuBureau(etat),
      Piece.chambre => decorDeLaChambre(etat),
      Piece.garage => decorDuGarage(objets),
      Piece.piscine => decorDeLaPiscine(etat, objets),
    };

/// Les jauges que la règle de cette pièce regarde — pour que l'écran puisse
/// dire au joueur pourquoi sa piscine est verte.
List<Jauge> jaugesLues(Piece piece) => switch (piece) {
      Piece.balcon => const [Jauge.peuple, Jauge.armee, Jauge.caisses, Jauge.presse],
      Piece.bureau => const [Jauge.presse],
      Piece.chambre => const [],
      Piece.garage => const [],
      Piece.piscine => const [Jauge.caisses],
    };
