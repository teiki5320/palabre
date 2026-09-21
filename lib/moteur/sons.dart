import 'decor.dart';
import 'etat_partie.dart';
import 'jauges.dart';
import 'palais.dart';

/// Les six sons du jeu. Six, et pas un de plus : on fait le même geste cent
/// fois par partie, et trois bruits superposés à chaque décision feraient
/// couper le son au bout de dix minutes.
enum Son { decision, mieux, mal, caisses, reelu, battu, ceremonie }

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


/// Ce qu'une pièce fait entendre en fond, en boucle, tant qu'on y reste.
///
/// Deux natures se mélangent ici sans que l'écran ait à les distinguer :
/// des ambiances — la rue, l'eau, le béton — et deux morceaux. La règle
/// vient de ce qu'il y a à entendre : là où des gens vivent, on les
/// entend ; là où il ne se passe rien, la musique prend le relais.
enum Fond {
  balconOrdinaire, balconProspere, balconPluies, balconLiesse, balconEmeute,
  balconEteinte, balconVerrouillee, balconCameras, balconDefile, balconDeuil,
  balconNuit, piscineQuartier, garage, musiqueBureau, musiqueChambre,
}

/// Vrai pour les deux morceaux. Ils se coupent plus lentement que les
/// ambiances : une rue qu'on quitte peut s'arrêter net, pas une musique.
bool estMusique(Fond fond) =>
    fond == Fond.musiqueBureau || fond == Fond.musiqueChambre;

const Map<String, Fond> _balcon = {
  'ordinaire': Fond.balconOrdinaire,
  'prospere': Fond.balconProspere,
  'pluies': Fond.balconPluies,
  'liesse': Fond.balconLiesse,
  'emeute': Fond.balconEmeute,
  'eteinte': Fond.balconEteinte,
  'verrouillee': Fond.balconVerrouillee,
  'cameras': Fond.balconCameras,
  'defile': Fond.balconDefile,
  'deuil': Fond.balconDeuil,
};

/// Les états du balcon que la nuit remplace. Une émeute, une liesse, un
/// défilé ne se taisent pas parce qu'il fait nuit ; une ville ordinaire,
/// prospère ou pleine de journalistes, si.
const Set<String> _calmesDeLaNuit = {'ordinaire', 'prospere', 'cameras'};

/// Le fond d'une pièce, d'après le décor que le moteur y a déjà choisi.
///
/// La piscine n'a d'ambiance que lorsqu'il y a du monde dedans : un bassin
/// vide, verdi ou vidé n'a rien à faire entendre, et prend la musique du
/// bureau — celle-là même qui joue sur l'écran des cartes.
Fond fondDe(Piece piece, Decor decor, EtatPartie etat) => switch (piece) {
      Piece.balcon => estNuit(etat) && _calmesDeLaNuit.contains(decor.etat)
          ? Fond.balconNuit
          : _balcon[decor.etat] ?? Fond.balconOrdinaire,
      Piece.piscine =>
        decor.etat == 'quartier' ? Fond.piscineQuartier : Fond.musiqueBureau,
      Piece.garage => Fond.garage,
      Piece.chambre => Fond.musiqueChambre,
      Piece.bureau => Fond.musiqueBureau,
    };

/// Le fichier de chaque fond.
String fichierDuFond(Fond fond) {
  final nom = switch (fond) {
    Fond.balconOrdinaire => 'balcon_ordinaire',
    Fond.balconProspere => 'balcon_prospere',
    Fond.balconPluies => 'balcon_pluies',
    Fond.balconLiesse => 'balcon_liesse',
    Fond.balconEmeute => 'balcon_emeute',
    Fond.balconEteinte => 'balcon_eteinte',
    Fond.balconVerrouillee => 'balcon_verrouillee',
    Fond.balconCameras => 'balcon_cameras',
    Fond.balconDefile => 'balcon_defile',
    Fond.balconDeuil => 'balcon_deuil',
    Fond.balconNuit => 'balcon_nuit',
    Fond.piscineQuartier => 'piscine_quartier',
    Fond.garage => 'garage',
    Fond.musiqueBureau => 'musique_bureau',
    Fond.musiqueChambre => 'musique_chambre',
  };
  return 'sons/fond/$nom.mp3';
}
