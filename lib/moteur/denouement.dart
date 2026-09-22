import 'etat_partie.dart';
import 'jauges.dart';
import 'modeles.dart';

/// Durée d'un mandat : cent jours, comme le titre le promet. Mesuré sur
/// 296 cartes, le paquet tient sans jamais s'épuiser.
const int dureeMandat = 100;

enum TypeDenouement { chute, electionGagnee, electionPerdue }

/// Pourquoi et comment le mandat s'arrête.
class Denouement {
  const Denouement({required this.type, this.jauge, this.versLeHaut = false});

  final TypeDenouement type;

  /// La jauge fautive en cas de chute, null pour une élection.
  final Jauge? jauge;

  /// true si la jauge a débordé, false si elle s'est vidée.
  final bool versLeHaut;
}

/// Rend le dénouement si le mandat s'arrête, null s'il continue.
Denouement? evalue(EtatPartie etat, {int duree = dureeMandat}) {
  final fautive = etat.jauges.extreme();
  if (fautive != null) {
    return Denouement(
      type: TypeDenouement.chute,
      jauge: fautive,
      versLeHaut: etat.jauges.valeur(fautive) >= 100,
    );
  }
  if (etat.jour > duree) return Denouement(type: electionDe(etat));
  return null;
}

/// Qui gagne le centième jour. Le pays vous pèse au peuple et à la presse ;
/// en face, l'opposition a sa propre force, qui part de cinquante et monte
/// de ce que vous avez perdu devant le pays. Une partie où personne ne
/// monte se décide donc exactement comme avant : à cinquante.
TypeDenouement electionDe(EtatPartie etat) {
  final moyenne = (etat.jauges.peuple + etat.jauges.presse) / 2;
  return moyenne > etat.force ? TypeDenouement.electionGagnee : TypeDenouement.electionPerdue;
}

/// La fin écrite qui correspond au dénouement, ou null si le contenu ne la
/// fournit pas encore. À dénouement égal, c'est le régime qui départage :
/// la fin la plus précise l'emporte, et une fin couvrant tout l'axe reste
/// le repli quand aucune ne colle.
Fin? choisitFin(Denouement d, List<Fin> fins,
    {int style = styleDepart, Set<String> drapeaux = const {}}) {
  bool correspond(Fin f) => switch (d.type) {
        TypeDenouement.chute => f.jauge == d.jauge && f.versLeHaut == d.versLeHaut,
        TypeDenouement.electionGagnee => f.jauge == null && f.versLeHaut,
        TypeDenouement.electionPerdue => f.jauge == null && !f.versLeHaut,
      };

  // Une fin qui exige quelque chose du palais passe avant une fin qui
  // n'exige rien : c'est la plus précise des deux, même si elle couvre
  // tout l'axe du régime.
  final candidates = fins
      .where(correspond)
      .where((f) => f.drapeauxRequis.every(drapeaux.contains))
      .toList()
    ..sort((a, b) {
      final poids = b.drapeauxRequis.length.compareTo(a.drapeauxRequis.length);
      return poids != 0 ? poids : a.precision.compareTo(b.precision);
    });
  for (final f in candidates) {
    if (style >= f.styleMin && style <= f.styleMax) return f;
  }
  return null;
}
