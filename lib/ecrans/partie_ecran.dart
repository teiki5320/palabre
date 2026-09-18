import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/denouement.dart';
import '../moteur/jauges.dart';
import '../moteur/modeles.dart';
import '../moteur/partie.dart';
import 'carte_glissante.dart';
import 'fin_ecran.dart';
import 'palais_ecran.dart';
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
  late final AnimationController _doublure = AnimationController(
    vsync: this,
    duration: CarteGlissante.sortie,
  );

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
    final parcours = contenu.parcoursParId(session.etat.parcours);
    final personnage = contenu.personnageDe(carte, parcours);
    final titre = parcours?.titre ?? 'Monsieur le Président';
    final reponse = switch (_intention) {
      Cote.gauche => carte.gauche,
      Cote.droite => carte.droite,
      null => null,
    };

    return Scaffold(
      body: SafeArea(
        child: Cadre(
          enfant: Column(
            children: [
              _LigneJauges(
                jauges: session.etat.jauges,
                // Ce que la réponse fera vraiment, régime et mandat compris :
                // montrer l'effet brut mentirait au joueur au moment précis où
                // il décide.
                effets: reponse == null
                    ? const {}
                    : effetsReels(
                        effets: reponse.effets,
                        style: session.etat.style,
                        mandat: session.etat.mandat,
                        atout: parcours?.atout,
                      ),
              ),
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
                            // Le jour fait partie de la clé : une carte répétable
                            // tirée deux jours de suite doit être une carte neuve
                            // pour Flutter, sinon il garde l'état « sortie » de la
                            // veille et plus aucun geste ne répond.
                            key: ValueKey('${session.etat.jour}_${carte.id}'),
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
              _AxeRegime(style: session.etat.style, vise: reponse?.style ?? 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// « JOUR 12 », et ce vers quoi le mandat va. À gauche, la sortie : la
/// partie est sauvegardée à chaque réponse, on la retrouve à l'accueil.
class _LigneJour extends StatelessWidget {
  const _LigneJour({required this.jour, required this.mandat});

  final int jour;
  final int mandat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('JOUR $jour', style: Textes.jour),
                const SizedBox(width: 8),
                Text(mandat > 1 ? 'second mandat' : 'élection au jour $dureeMandat', style: Textes.echeance),
              ],
            ),
            Positioned(
              left: 0,
              child: IconButton(
                tooltip: 'Quitter, la partie est gardée',
                icon: const Icon(Icons.west, size: 20),
                color: Couleurs.cremeDoux,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                tooltip: 'Le palais',
                icon: const Icon(Icons.account_balance_outlined, size: 20),
                color: Couleurs.cremeDoux,
                // Visiter ne coûte pas un jour : le palais est une
                // récompense, pas une dépense.
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PalaisEcran()),
                ),
              ),
            ),
          ],
        ),
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

/// L'axe du régime, sous la carte. Ce n'est pas une jauge : aucun bout ne
/// tue, et il ne montre pas de chiffre. Il dit seulement de quel côté le
/// mandat penche, et il penche sans qu'on l'ait jamais décidé d'un coup.
class _AxeRegime extends StatelessWidget {
  const _AxeRegime({required this.style, required this.vise});

  final int style;

  /// Ce que la réponse pressentie déplacerait, ou zéro si elle ne dit rien
  /// du régime — ce qui est le cas de la plupart des décisions.
  final int vise;

  @override
  Widget build(BuildContext context) {
    final apres = (style + vise).clamp(0, 100);
    final penche = vise != 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 34),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: vise < 0 ? Textes.nomJauge.copyWith(color: Couleurs.or) : Textes.nomJauge,
                child: const Text('RÉPUBLIQUE'),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: vise > 0 ? Textes.nomJauge.copyWith(color: Couleurs.or) : Textes.nomJauge,
                child: const Text('DICTATURE'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, c) {
                final large = c.maxWidth;
                double x(int v) => large * v.clamp(0, 100) / 100;
                final debut = vise < 0 ? apres : style;
                final fin = vise < 0 ? style : apres;
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    // Le chemin que la réponse ferait faire.
                    if (penche && fin > debut)
                      Positioned(
                        left: x(debut),
                        width: x(fin) - x(debut),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Couleurs.or.withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    // Où l'on en est : un curseur, pas un remplissage. Un axe
                    // ne se remplit pas, on se déplace dessus.
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      left: x(style) - 5,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 10,
                        height: penche ? 14 : 10,
                        decoration: BoxDecoration(
                          color: penche ? Couleurs.or : Couleurs.creme,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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
          child: LayoutBuilder(
            builder: (context, c) {
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
            },
          ),
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
