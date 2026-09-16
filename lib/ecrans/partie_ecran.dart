import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/denouement.dart';
import '../moteur/jauges.dart';
import '../moteur/modeles.dart';
import '../moteur/partie.dart';
import 'carte_glissante.dart';
import 'fin_ecran.dart';
import 'session.dart';
import 'theme.dart';

/// L'écran de jeu : les jauges en haut, la carte du jour au milieu, les deux
/// réponses rappelées en bas. Pendant le geste, le joueur voit ce que sa
/// réponse coûtera avant de lâcher.
class PartieEcran extends ConsumerStatefulWidget {
  const PartieEcran({super.key});

  @override
  ConsumerState<PartieEcran> createState() => _PartieEcranState();
}

class _PartieEcranState extends ConsumerState<PartieEcran> with SingleTickerProviderStateMixin {
  Cote? _intention;

  /// Le passage de la carte suivante de l'arrière-plan au premier plan. Il
  /// démarre au départ de la carte du jour et se remet à zéro d'un coup quand
  /// la nouvelle carte est montée : la doublure est alors de nouveau derrière.
  late final AnimationController _doublure =
      AnimationController(vsync: this, duration: CarteGlissante.sortie);

  @override
  void dispose() {
    _doublure.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const Scaffold(body: SizedBox.shrink());
    if (session.terminee) return const FinEcran();

    final contenu = ref.watch(contenuProvider).requireValue;
    final carte = session.carte!;
    final personnage = contenu.personnages[carte.personnage];
    final parcours = contenu.parcoursParId(session.etat.parcours);
    final titre = parcours?.titre ?? 'Monsieur le Président';
    final reponse = switch (_intention) {
      Cote.gauche => carte.gauche,
      Cote.droite => carte.droite,
      null => null,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _LigneJauges(jauges: session.etat.jauges, effets: reponse?.effets ?? const {}),
            _LigneJour(jour: session.etat.jour, mandat: session.etat.mandat),
            Expanded(
              // La carte qui part ne doit pas passer devant les jauges.
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _doublure,
                          builder: (context, enfant) {
                            final t = Curves.easeOut.transform(_doublure.value);
                            return Transform.translate(
                              offset: Offset(0, 10 * (1 - t)),
                              child: Transform.scale(scale: .96 + .04 * t, child: enfant),
                            );
                          },
                          child: const _Doublure(),
                        ),
                      ),
                      Positioned.fill(
                        child: CarteGlissante(
                          key: ValueKey(carte.id),
                          libelleGauche: carte.gauche.libelle,
                          libelleDroite: carte.droite.libelle,
                          onIntention: (c) => setState(() => _intention = c),
                          onSortie: () => _doublure.forward(from: 0),
                          onReponse: (c) {
                            setState(() => _intention = null);
                            _doublure.value = 0;
                            ref.read(sessionProvider.notifier).repondA(c);
                          },
                          enfant: _Carte(
                            personnage: personnage,
                            humeur: carte.humeur,
                            texte: habille(carte.texte, nom: session.etat.nomJoueur, titre: titre),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _LibellesRappeles(
              gauche: carte.gauche.libelle,
              droite: carte.droite.libelle,
              vise: _intention,
            ),
          ],
        ),
      ),
    );
  }
}

/// « JOUR 12 », et ce vers quoi le mandat va.
class _LigneJour extends StatelessWidget {
  const _LigneJour({required this.jour, required this.mandat});

  final int jour;
  final int mandat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('JOUR $jour', style: Textes.jour),
          const SizedBox(width: 8),
          Text(
            mandat > 1 ? 'second mandat' : 'élection au jour $dureeMandatPrototype',
            style: Textes.echeance,
          ),
        ],
      ),
    );
  }
}

/// La carte suivante, entrevue derrière celle du jour. C'est un aplat : on ne
/// révèle pas qui viendra demain.
class _Doublure extends StatelessWidget {
  const _Doublure();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Couleurs.nuitClair,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({required this.personnage, required this.humeur, required this.texte});

  final Personnage? personnage;
  final Humeur humeur;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .6), blurRadius: 60, offset: const Offset(0, 30)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: Couleurs.nuit,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (personnage != null)
                Image.asset(
                  personnage!.image(humeur),
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.35),
                  errorBuilder: (_, __, ___) => Container(color: Couleurs.aplat),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 120, 20, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Couleurs.encre.withValues(alpha: .95)],
                      stops: const [0, .55],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text((personnage?.titre ?? '').toUpperCase(), style: Textes.titrePersonnage),
                      const SizedBox(height: 8),
                      Text(texte, style: Textes.texteCarte),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les deux réponses rappelées sous la carte. Celle qu'on vise passe en or.
class _LibellesRappeles extends StatelessWidget {
  const _LibellesRappeles({required this.gauche, required this.droite, required this.vise});

  final String gauche;
  final String droite;
  final Cote? vise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 34),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: _Rappel(texte: gauche, cote: Cote.gauche, actif: vise == Cote.gauche)),
          const SizedBox(width: 16),
          Flexible(child: _Rappel(texte: droite, cote: Cote.droite, actif: vise == Cote.droite)),
        ],
      ),
    );
  }
}

class _Rappel extends StatelessWidget {
  const _Rappel({required this.texte, required this.cote, required this.actif});

  final String texte;
  final Cote cote;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final style = actif ? Textes.rappel.copyWith(color: Couleurs.or) : Textes.rappel;
    // Les flèches passent par les icônes : ← et → n'existent pas dans les
    // polices embarquées, et chaque plateforme en substituerait une autre.
    final fleche = Icon(
      cote == Cote.gauche ? Icons.west : Icons.east,
      size: 14,
      color: style.color,
    );
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 160),
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cote == Cote.gauche) ...[fleche, const SizedBox(width: 6)],
          Flexible(child: Text(texte.toUpperCase(), overflow: TextOverflow.ellipsis)),
          if (cote == Cote.droite) ...[const SizedBox(width: 6), fleche],
        ],
      ),
    );
  }
}

/// Les quatre jauges. Au repos elles informent ; pendant le geste, celles que
/// la réponse touche s'allument et montrent d'avance ce qu'elles vont perdre
/// ou gagner. Jamais un chiffre de jauge : seulement ce qui change.
class _LigneJauges extends StatefulWidget {
  const _LigneJauges({required this.jauges, required this.effets});

  final Jauges jauges;
  final Map<Jauge, int> effets;

  /// En deçà et au-delà, la jauge est mortelle : on prévient avant.
  static const int bas = 15;
  static const int haut = 85;

  @override
  State<_LigneJauges> createState() => _LigneJaugesState();
}

class _LigneJaugesState extends State<_LigneJauges> with SingleTickerProviderStateMixin {
  /// Une seule pulsation pour toute la ligne : les jauges en danger battent
  /// ensemble, et l'écran n'entretient qu'une animation.
  late final AnimationController _battement = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _danger => Jauge.values.any((j) {
        final v = widget.jauges.valeur(j);
        return v <= _LigneJauges.bas || v >= _LigneJauges.haut;
      });

  /// Le battement ne tourne que tant qu'une jauge est au bord. Sans cette
  /// garde il tournerait toute la partie, pour rien.
  void _accorde() {
    if (_danger && !_battement.isAnimating) {
      _battement.repeat(reverse: true);
    } else if (!_danger && _battement.isAnimating) {
      _battement.stop();
      _battement.value = 1;
    }
  }

  @override
  void initState() {
    super.initState();
    _accorde();
  }

  @override
  void didUpdateWidget(_LigneJauges ancien) {
    super.didUpdateWidget(ancien);
    _accorde();
  }

  @override
  void dispose() {
    _battement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: AnimatedBuilder(
        animation: _battement,
        builder: (context, _) => Row(
          children: [
            for (final j in Jauge.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _Jauge(
                    key: ValueKey('jauge_${j.name}'),
                    jauge: j,
                    valeur: widget.jauges.valeur(j),
                    effet: widget.effets[j],
                    // .70 ↔ 1 : la jauge en danger respire, elle ne clignote pas.
                    pulsation: .70 + .30 * Curves.easeInOut.transform(_battement.value),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Jauge extends StatelessWidget {
  const _Jauge({
    required super.key,
    required this.jauge,
    required this.valeur,
    required this.effet,
    required this.pulsation,
  });

  final Jauge jauge;
  final int valeur;

  /// Ce que la réponse pressentie ferait à cette jauge, ou null si elle ne la
  /// touche pas.
  final int? effet;
  final double pulsation;

  bool get _concernee => effet != null;
  bool get _alerte => valeur <= _LigneJauges.bas || valeur >= _LigneJauges.haut;

  /// Le geste rapproche une jauge déjà en danger du bord qui tue.
  bool get _aggrave =>
      _alerte &&
      effet != null &&
      ((valeur >= _LigneJauges.haut && effet! > 0) || (valeur <= _LigneJauges.bas && effet! < 0));

  double get _hauteur => _aggrave ? 10 : (_concernee ? 8 : 6);

  @override
  Widget build(BuildContext context) {
    final couleurNom = _concernee || _alerte ? Couleurs.or : Textes.nomJauge.color;
    final remplissage = _concernee
        ? Couleurs.or
        : (_alerte ? Couleurs.or.withValues(alpha: pulsation) : Couleurs.creme);

    return Column(
      children: [
        Text(jauge.nom.toUpperCase(), style: Textes.nomJauge.copyWith(color: couleurNom)),
        const SizedBox(height: 4),
        SizedBox(
          height: 14,
          child: LayoutBuilder(builder: (context, c) {
            final large = c.maxWidth;
            double x(int v) => large * v.clamp(0, 100) / 100;
            final apres = (valeur + (effet ?? 0)).clamp(0, 100);
            final debut = effet != null && effet! < 0 ? apres : valeur;
            final fin = effet != null && effet! < 0 ? valeur : apres;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: _hauteur,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(_hauteur / 2),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    key: ValueKey('barre_${jauge.name}'),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    height: _hauteur,
                    width: x(valeur),
                    decoration: BoxDecoration(
                      color: remplissage,
                      borderRadius: BorderRadius.circular(_hauteur / 2),
                    ),
                  ),
                ),
                // Le fantôme : la part que la réponse ferait gagner ou perdre.
                if (_concernee && fin > debut)
                  Positioned(
                    left: x(debut),
                    width: x(fin) - x(debut),
                    child: Container(
                      height: _aggrave ? 6 : 4,
                      decoration: BoxDecoration(
                        color: _aggrave ? Couleurs.or : Couleurs.or.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(_aggrave ? 4 : 2),
                      ),
                    ),
                  ),
                // Pour une perte, une marque au niveau d'aujourd'hui : on voit
                // d'où l'on part autant que là où l'on tombe.
                if (_concernee && effet! < 0)
                  Positioned(
                    left: x(valeur) - 1,
                    child: Container(width: 2, height: 14, color: Couleurs.or),
                  ),
              ],
            );
          }),
        ),
        const SizedBox(height: 3),
        AnimatedOpacity(
          opacity: _concernee ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          // La hauteur du delta est toujours réservée : rien ne saute quand
          // une jauge s'allume.
          child: _Delta(effet: effet ?? 0, aggrave: _aggrave),
        ),
      ],
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({required this.effet, required this.aggrave});

  final int effet;
  final bool aggrave;

  @override
  Widget build(BuildContext context) {
    // Le vrai signe moins, pas le trait d'union : il s'aligne sur le plus.
    final texte = effet >= 0 ? '+$effet' : '−${-effet}';
    if (!aggrave) return Text(texte, style: Textes.deltaJauge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: Couleurs.or, borderRadius: BorderRadius.circular(4)),
      child: Text(texte, style: Textes.deltaJauge.copyWith(color: Couleurs.creme)),
    );
  }
}
