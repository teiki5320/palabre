import 'etat_partie.dart';
import 'jauges.dart';
import 'modeles.dart';

/// Durée d'un mandat dans le prototype. Le lancement passera à 100, quand il
/// y aura assez de cartes pour tenir cent jours sans se répéter.
const int dureeMandatPrototype = 30;

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
Denouement? evalue(EtatPartie etat, {int duree = dureeMandatPrototype}) {
  final fautive = etat.jauges.extreme();
  if (fautive != null) {
    return Denouement(
      type: TypeDenouement.chute,
      jauge: fautive,
      versLeHaut: etat.jauges.valeur(fautive) >= 100,
    );
  }
  if (etat.jour > duree) {
    final moyenne = (etat.jauges.peuple + etat.jauges.presse) / 2;
    return Denouement(type: moyenne > 50 ? TypeDenouement.electionGagnee : TypeDenouement.electionPerdue);
  }
  return null;
}

/// La fin écrite qui correspond au dénouement, ou null si le contenu ne la
/// fournit pas encore. À dénouement égal, c'est le régime qui départage :
/// la fin la plus précise l'emporte, et une fin couvrant tout l'axe reste
/// le repli quand aucune ne colle.
Fin? choisitFin(Denouement d, List<Fin> fins, {int style = styleDepart}) {
  bool correspond(Fin f) => switch (d.type) {
        TypeDenouement.chute => f.jauge == d.jauge && f.versLeHaut == d.versLeHaut,
        TypeDenouement.electionGagnee => f.jauge == null && f.versLeHaut,
        TypeDenouement.electionPerdue => f.jauge == null && !f.versLeHaut,
      };

  final candidates = fins.where(correspond).toList()
    ..sort((a, b) => a.precision.compareTo(b.precision));
  for (final f in candidates) {
    if (style >= f.styleMin && style <= f.styleMax) return f;
  }
  return null;
}
