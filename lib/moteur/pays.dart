import 'modeles.dart';

/// Les lieux du pays, tels que la carte du bureau les montre.
///
/// Ils ne sont pas inventés pour la carte : chacun est nommé par au moins
/// une carte du jeu, et c'est à cela qu'on le reconnaît. Tant qu'aucune
/// carte vue ne l'a nommé, il reste éteint — la carte se remplit comme on
/// apprend un pays, en le traversant.
class Lieu {
  const Lieu({
    required this.id,
    required this.nom,
    required this.x,
    required this.y,
    required this.motif,
    this.taille = TailleDuNom.ordinaire,
    this.toujours = false,
  });

  final String id;
  final String nom;

  /// Où il se pose sur la plaque, en fractions de 0 à 1.
  final double x;
  final double y;

  /// Ce qu'une carte doit dire pour qu'on le découvre. Sans accent et sans
  /// casse : la comparaison se fait sur le texte aplati.
  final String motif;

  final TailleDuNom taille;

  /// Vrai pour ce qu'on connaît avant d'avoir joué : on gouverne depuis la
  /// capitale, on ne la découvre pas.
  final bool toujours;
}

enum TailleDuNom { capitale, ordinaire, quartier }

const List<Lieu> lieuxDuPays = [
  Lieu(id: 'capitale', nom: 'La capitale', x: .49, y: .65,
      motif: 'capitale', taille: TailleDuNom.capitale, toujours: true),
  Lieu(id: 'port', nom: 'Le port', x: .60, y: .74, motif: 'port'),
  Lieu(id: 'cuvette', nom: 'Quartier de la Cuvette', x: .36, y: .76,
      motif: 'cuvette', taille: TailleDuNom.quartier),
  Lieu(id: 'palmiers', nom: 'Quartier des Palmiers', x: .56, y: .55,
      motif: 'palmiers', taille: TailleDuNom.quartier),
  Lieu(id: 'route', nom: 'La route du nord', x: .28, y: .35, motif: 'route du nord'),
  Lieu(id: 'camp', nom: 'Le camp du nord', x: .20, y: .155, motif: 'camp'),
  Lieu(id: 'villages', nom: 'Les quarante villages', x: .10, y: .46, motif: 'villages'),
  Lieu(id: 'fleuve', nom: 'Le fleuve', x: .66, y: .27, motif: 'fleuve'),
  Lieu(id: 'mine', nom: 'La mine', x: .72, y: .38, motif: 'mine'),
  Lieu(id: 'barrage', nom: 'Le barrage', x: .82, y: .13, motif: 'barrage'),
];

const String _avecAccents = 'àâäéèêëîïôöùûüç';
const String _sans = 'aaaeeeeiioouuuc';

/// Le texte aplati : sans accent, sans casse. C'est la même méthode que le
/// contrôle de contenu emploie pour chercher les mots interdits.
String aplati(String s) {
  final out = StringBuffer();
  for (final c in s.toLowerCase().runes) {
    final i = _avecAccents.runes.toList().indexOf(c);
    out.writeCharCode(i >= 0 ? _sans.codeUnitAt(i) : c);
  }
  return out.toString();
}

/// Les lieux qu'on a rencontrés : ceux qu'au moins une carte déjà vue a
/// nommés, plus ceux qu'on connaît d'avance.
Set<String> lieuxConnus({required Iterable<Carte> paquet, required Set<String> vues}) {
  final connus = {for (final l in lieuxDuPays) if (l.toujours) l.id};
  for (final c in paquet) {
    if (!vues.contains(c.id)) continue;
    final texte = aplati('${c.texte} ${c.gauche.journal} ${c.droite.journal}');
    for (final l in lieuxDuPays) {
      if (!connus.contains(l.id) && texte.contains(l.motif)) connus.add(l.id);
    }
  }
  return connus;
}
