import 'package:flutter/material.dart';

import 'theme.dart';

/// Ce qu'on montre au tout premier lancement, une fois pour toutes : de quoi
/// il s'agit, comment on répond, et ce qui peut vous coûter le pouvoir. Trois
/// écrans, qu'on passe en glissant — le geste du jeu, appris avant d'y jouer.
class IntroEcran extends StatefulWidget {
  const IntroEcran({super.key, required this.onFini});

  /// Appelé quand le joueur a fini l'intro, ou l'a passée.
  final VoidCallback onFini;

  @override
  State<IntroEcran> createState() => _IntroEcranState();
}

class _IntroEcranState extends State<IntroEcran> {
  final _page = PageController();
  int _a = 0;

  static const _panneaux = [
    (
      titre: 'Vous venez d\'être élu président.',
      texte:
          'Un palais, des caisses presque vides, et tout le monde qui '
          'veut vous voir demain matin.',
    ),
    (
      titre: 'Chaque jour, quelqu\'un entre.',
      texte:
          'Il pose son problème. Vous glissez sa carte à gauche ou à droite : '
          'c\'est votre réponse. Il n\'y a pas de bouton, et pas de « plus tard ».',
    ),
    (
      titre: 'Quatre forces vous tiennent.',
      texte:
          'Le peuple, l\'armée, les caisses, la presse. Contentez-en une, '
          'vous fâchez les autres. Si l\'une se vide ou déborde, votre mandat s\'arrête là.',
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _suivant() {
    if (_a < _panneaux.length - 1) {
      _page.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    } else {
      widget.onFini();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dernier = _a == _panneaux.length - 1;
    final grand = grandEcran(context);
    return Scaffold(
      backgroundColor: Couleurs.nuit,
      body: SafeArea(
        child: Column(
          children: [
            Cadre(
              enfant: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 12, 0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icone/marque.png',
                      height: 40,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 40),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onFini,
                      child: Text('Passer', style: Textes.rappel.copyWith(color: Couleurs.creme)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _a = i),
                children: [
                  for (final p in _panneaux)
                    Cadre(
                      enfant: Padding(
                        padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
                        child: Column(
                          // Centré : ces écrans se lisent d'un bloc, sans
                          // rien à toucher. Sur une tablette la typographie
                          // prend l'ampleur que la place permet, au lieu de
                          // rester au corps d'un téléphone.
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.titre,
                              textAlign: TextAlign.center,
                              style: Textes.nomParcours.copyWith(fontSize: grand ? 42 : 34),
                            ),
                            SizedBox(height: grand ? 26 : 18),
                            Text(
                              p.texte,
                              textAlign: TextAlign.center,
                              style: Textes.sousTitre.copyWith(fontSize: grand ? 22 : 17, height: 1.55),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Cadre(
              enfant: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _panneaux.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _a ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _a ? Couleurs.or : Couleurs.bordure,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _suivant,
                        child: Text(dernier ? 'Prendre mes fonctions' : 'Suivant'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
