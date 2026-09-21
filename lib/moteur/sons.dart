import 'jauges.dart';

/// Les six sons du jeu. Six, et pas un de plus : on fait le même geste cent
/// fois par partie, et trois bruits superposés à chaque décision feraient
/// couper le son au bout de dix minutes.
enum Son { decision, mieux, mal, caisses, reelu, battu }

/// À partir de quel mouvement une réponse mérite son propre son.
///
/// Mesuré sur les 1 300 réponses écrites : un extrême de 8 points ou plus
/// concerne 46 % d'entre elles, 10 points 13 %, et 12 points 4 %. En deçà de
/// douze, le son « notable » sortirait dix à cinquante fois par mandat et ne
/// dirait plus rien. À douze, il sort quatre ou cinq fois, et chacune se
/// remarque.
const int seuilNotable = 12;

/// Le son d'une réponse : celui de la décision, sauf quand une jauge bouge
/// franchement — auquel cas il le *remplace*, il ne s'y ajoute pas.
///
/// On juge sur le mouvement le plus ample, pas sur la somme : une réponse
/// qui donne quinze au peuple et reprend quinze aux caisses est un coup de
/// théâtre, pas un événement neutre. À égalité, la mauvaise nouvelle gagne —
/// c'est elle qu'un président retient.
Son sonDeLaReponse(Map<Jauge, int> effetsReels) {
  var extreme = 0;
  for (final v in effetsReels.values) {
    if (v.abs() > extreme.abs() || (v.abs() == extreme.abs() && v < extreme)) {
      extreme = v;
    }
  }
  if (extreme >= seuilNotable) return Son.mieux;
  if (extreme <= -seuilNotable) return Son.mal;
  return Son.decision;
}

/// Le fichier de chaque son, tel qu'il est livré dans les assets.
String fichierDe(Son son) => 'sons/${son.name}.mp3';
