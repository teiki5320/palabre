import 'dart:convert';

/// Les trois temps du rendez-vous, dans l'ordre des appuis : la personne
/// debout habillée, la personne déshabillée, puis la scène sur le lit.
enum TempsChambre { habille, deshabille, lit }

/// Ce que la personne dit pendant le rendez-vous.
///
/// Trois répliques, une par appui, et deux jeux : tant que la liaison se
/// cache, et une fois mariés. La même personne ne parle pas de la même
/// façon dans les deux cas — c'est la seule chose qui raconte le mariage
/// dans cette pièce, et elle ne coûte pas une image.
///
/// Le président, lui, ne répond jamais : c'est le joueur, et il n'a de
/// réplique nulle part ailleurs dans le jeu.
class DitsDeLaChambre {
  const DitsDeLaChambre(this._parPersonne);

  /// Personne → situation → temps → réplique.
  final Map<String, Map<String, Map<String, String>>> _parPersonne;

  /// Une chambre muette. C'est ce que voit une partie dont le contenu n'a
  /// pas ce fichier : la scène se joue alors sans une parole, comme avant.
  static const muette = DitsDeLaChambre({});

  factory DitsDeLaChambre.depuisJson(String source) {
    final brut = jsonDecode(source) as Map<String, dynamic>;
    return DitsDeLaChambre({
      for (final personne in brut.entries)
        personne.key: {
          for (final situation in (personne.value as Map<String, dynamic>).entries)
            situation.key: {
              for (final temps in (situation.value as Map<String, dynamic>).entries)
                temps.key: temps.value as String,
            },
        },
    });
  }

  /// La réplique, ou rien. Une personne sans texte laisse la scène muette
  /// au lieu d'arrêter le jeu : on n'interrompt pas une partie pour un
  /// fichier de contenu incomplet.
  String? dit(String qui, {required bool marie, required TempsChambre temps}) =>
      _parPersonne[qui]?[marie ? 'marie' : 'liaison']?[temps.name];

  bool get muet => _parPersonne.isEmpty;

  /// Les personnes qui ont quelque chose à dire. Sert aux vérifications
  /// du contenu, pas au jeu.
  Iterable<String> get personnes => _parPersonne.keys;
}
