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
/// fournit pas encore.
Fin? choisitFin(Denouement d, List<Fin> fins) {
  for (final f in fins) {
    switch (d.type) {
      case TypeDenouement.chute:
        if (f.jauge == d.jauge && f.versLeHaut == d.versLeHaut) return f;
      case TypeDenouement.electionGagnee:
        if (f.jauge == null && f.versLeHaut) return f;
      case TypeDenouement.electionPerdue:
        if (f.jauge == null && !f.versLeHaut) return f;
    }
  }
  return null;
}
