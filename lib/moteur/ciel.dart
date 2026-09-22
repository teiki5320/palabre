import 'dart:math' as math;

import 'decor.dart';
import 'denouement.dart';
import 'etat_partie.dart';

/// Ce qui traverse le ciel de la carte : un astre, sa hauteur, et pour la
/// lune sa phase.
///
/// Rien ici ne connaît Flutter : la course se calcule et se teste sans
/// écran, comme le reste des règles du palais.
enum Astre { soleil, lune }

/// Combien de nuits compte un mandat : cinq, puisque le jour et la nuit
/// alternent toutes les dix cartes sur cent. Calculé, jamais écrit à la
/// main — changer la durée du mandat ou la tranche doit suffire.
const int nuitsParMandat = dureeMandat ~/ (cartesParDemiJournee * 2);

class CielDuJour {
  const CielDuJour({
    required this.astre,
    required this.course,
    required this.hauteur,
    required this.phase,
  });

  final Astre astre;

  /// De 0 au lever à 1 au coucher : c'est ce qui place l'astre en largeur.
  final double course;

  /// De 0 à l'horizon à 1 au zénith. Une demi-sinusoïde de la course, donc
  /// l'astre monte vite, s'attarde en haut, et redescend.
  final double hauteur;

  /// Pour la lune, de 0,2 la première nuit à 1 la dernière : elle croît
  /// d'une nuit à l'autre et n'est pleine qu'au centième jour. Toujours 1
  /// pour le soleil, qui n'a pas de phase.
  final double phase;
}

/// Le ciel du jour [etat.jour]. La course se compte à l'intérieur de la
/// tranche de dix cartes, et se referme à chaque bascule.
CielDuJour cielDe(EtatPartie etat) {
  final bloc = (etat.jour - 1) ~/ cartesParDemiJournee;
  final dans = (etat.jour - 1) % cartesParDemiJournee;
  // Sur dix cartes, le premier pas est le lever et le dernier le coucher :
  // on divise par neuf, pas par dix, sinon l'astre ne se couche jamais.
  final course = cartesParDemiJournee > 1 ? dans / (cartesParDemiJournee - 1) : 0.0;
  final nuit = bloc.isOdd;
  // La nuit numéro zéro est la première du mandat : sa lune est un mince
  // croissant, et chaque nuit la découvre d'un cinquième de plus.
  final rang = nuit ? (bloc - 1) ~/ 2 : 0;
  return CielDuJour(
    astre: nuit ? Astre.lune : Astre.soleil,
    course: course,
    hauteur: math.sin(math.pi * course),
    phase: nuit ? ((rang + 1) / nuitsParMandat).clamp(0.2, 1.0) : 1,
  );
}
