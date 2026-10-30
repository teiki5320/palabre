import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/decor.dart';
import '../moteur/dits.dart';
import '../moteur/etat_partie.dart';
import '../moteur/palais.dart';
import 'session.dart';
import 'sons.dart';
import 'carte_pays_ecran.dart';
import '../moteur/pays.dart';
import 'theme.dart';

/// Le palais : on arrive au bureau, on en repart vers les quatre autres
/// pièces. Le décor obéit aux jauges, jamais à l'écran — toute la règle est
/// dans `moteur/decor.dart`, et cet écran ne fait que la montrer.
class PalaisEcran extends ConsumerStatefulWidget {
  const PalaisEcran({super.key});

  @override
  ConsumerState<PalaisEcran> createState() => _PalaisEcranState();
}

class _PalaisEcranState extends ConsumerState<PalaisEcran> {
  Piece _piece = Piece.bureau;

  /// Gardé ici plutôt que relu dans `dispose` : à ce moment-là le widget
  /// n'est plus monté, et Riverpod refuse — à raison — qu'on touche à `ref`.
  /// Le son est un objet de toute la partie, le garder ne risque rien.
  Sons? _sons;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sons = ref.read(sonsProvider);
  }

  @override
  void dispose() {
    // Le palais rend le silence en partant. L'écran des cartes coupait bien
    // le fond, mais depuis son `build` — et visiter le palais ne consomme
    // pas un jour : en revenant sans avoir rien acheté, la session n'a pas
    // bougé, l'écran ne se reconstruit pas, et la foule du balcon continuait
    // de courir sous les cartes. Ce qu'une pièce a allumé, c'est à elle de
    // l'éteindre.
    _sons?.metLeFond(null);
    // Le palais est de loin ce que le jeu affiche de plus lourd : une plaque
    // décodée pèse 15,7 Mo, et une visite en traverse plusieurs. En sortant,
    // on rend ce qui ne sert plus. `clear` ne touche pas aux images encore à
    // l'écran — le portrait de la carte du jour, qui est dessous, survit et
    // ne clignote pas.
    PaintingBinding.instance.imageCache.clear();
    super.dispose();
  }

  void _va(Piece p) {
    if (p == _piece) return;
    setState(() => _piece = p);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const Scaffold(body: SizedBox.shrink());
    final objets = ref.watch(progressionProvider).value?.objets ?? const <String>{};
    final contenu = ref.watch(contenuProvider).value;
    final decor = decorDe(_piece, session.etat, objets);

    // Le fond de la pièce où l'on vient d'entrer. Posé ici parce que c'est
    // le seul endroit qui connaît à la fois la pièce et son décor ;
    // `metLeFond` ne fait rien quand on lui redemande ce qui joue déjà,
    // donc le redire à chaque reconstruction ne coûte rien.
    ref.read(sonsProvider).metLeFond(fondDe(_piece, decor, session.etat));

    // Un rendez-vous remplace la chambre entière : pas de tiroir, pas de
    // portes, rien que la scène. On n'entre pas là pour acheter un lit.
    final rdv = _piece == Piece.chambre ? rendezVousDe(session.etat) : null;
    if (rdv != null) {
      return Scaffold(
        backgroundColor: Couleurs.nuit,
        body: _SceneRendezVous(
          rdv: rdv,
          key: ValueKey('rdv-${rdv.qui}'),
          // Le texte se résout ici, pas dans la scène : c'est l'écran qui
          // sait qui joue, sous quel titre, et si le mariage a eu lieu.
          replique: (temps) {
            final dit = (contenu?.dits ?? DitsDeLaChambre.muette)
                .dit(rdv.qui, marie: session.etat.epouse == rdv.qui, temps: temps);
            if (dit == null) return null;
            final parcours = contenu?.parcoursParId(session.etat.parcours);
            return habille(dit,
                nom: session.etat.nomJoueur,
                titre: parcours?.titre ?? 'Monsieur le Président');
          },
          fini: () {
            ref.read(sessionProvider.notifier).consommeRendezVous();
            _va(Piece.bureau);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Couleurs.nuit,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            child: _Decor(
              decor: decor,
              passages: passagesDe(_piece),
              ecran: ecranDe(_piece),
              decoupes: decoupesDe(_piece, decor.etat, objets),
              nuit: estNuit(session.etat),
              lieuxConnus: lieuxConnus(
                  paquet: contenu?.cartes ?? const [], vues: session.etat.vues),
              vers: _va,
              key: ValueKey('${_piece.name}-${decor.etat}'),
            ),
          ),
          const _Voile(),
          SafeArea(
            child: Column(
              children: [
                _Entete(piece: _piece, decor: decor, caisses: session.etat.jauges.caisses),
                const Spacer(),
                if (contenu != null)
                  _Tiroir(
                    piece: _piece,
                    etat: session.etat,
                    objets: objets,
                    catalogue: contenu.objetsDe(_piece),
                    achete: (o) => ref.read(sessionProvider.notifier).acheteObjet(o),
                  ),
                Semantics(
                  button: true,
                  label: 'Revenir au bureau',
                  onTap: () => _va(Piece.bureau),
                  child: _DemiTour(depuis: _piece, vers: _va),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le décor animé : six images en fondu sur huit secondes pour le balcon,
/// une seule image pour les pièces — et dans les deux cas un très lent
/// travelling et un regard qu'on déplace au doigt.
///
/// Le fondu est piloté en Dart plutôt qu'en implicite : le palais doit
/// bouger même quand le système demande de réduire les animations, sinon
/// le décor du jeu devient une photographie sans que personne le sache.
class _Decor extends StatefulWidget {
  const _Decor({
    required this.decor,
    required this.passages,
    required this.vers,
    required this.ecran,
    required this.decoupes,
    required this.nuit,
    required this.lieuxConnus,
    super.key,
  });

  final Decor decor;

  /// Les ouvertures de cette pièce, en coordonnées d'image : c'est le
  /// décor qui les porte, donc elles suivent le regard et le travelling
  /// au lieu de flotter à une place fixe de l'écran.
  final List<Passage> passages;

  /// L'écran accroché au mur, ou null : seul le bureau en a un.
  final Zone? ecran;

  /// Ce que le joueur a acheté et qu'on voit : une découpe par objet, à sa
  /// place dans la plaque. Elles suivent le regard comme les ouvertures,
  /// parce qu'elles sont posées sur l'image et non sur l'écran.
  final List<Decoupe> decoupes;

  /// Ce que l'écran montre : le pays de jour ou de nuit, et les lieux
  /// qu'au moins une carte vue a nommés.
  final bool nuit;
  final Set<String> lieuxConnus;
  final void Function(Piece) vers;

  @override
  State<_Decor> createState() => _DecorState();
}

class _DecorState extends State<_Decor> with SingleTickerProviderStateMixin {
  static const _cycle = Duration(seconds: 8);

  /// En entrant dans une pièce, le regard en fait le tour une fois : à
  /// gauche, à droite, puis il revient. Sans ça, un joueur qui ignore
  /// qu'on peut déplacer le regard ne voit qu'une ouverture sur trois et
  /// croit le palais fermé. Le premier toucher l'interrompt.
  static const _tour = Duration(milliseconds: 3400);

  late final Ticker _ticker = Ticker(_bat);
  double _t = 0;
  double _regard = 0.5; // 0 = tout à gauche, 1 = tout à droite
  double _cible = 0.5;
  bool _tourFini = false;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  void _bat(Duration ecoule) {
    setState(() {
      _t = ecoule.inMilliseconds / _cycle.inMilliseconds;
      if (!_tourFini) {
        final p = ecoule.inMilliseconds / _tour.inMilliseconds;
        if (p >= 1) {
          _tourFini = true;
          _cible = 0.5;
        } else {
          _cible = regardDuTour(p);
        }
      }
      // Le regard rejoint sa cible sans à-coup, et dérive doucement tout
      // seul quand le doigt ne dit rien.
      _regard += (_cible - _regard) * 0.08;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le pas, et non le nombre d'images : une boucle en aller-retour
    // compte presque deux fois plus de pas qu'elle n'a de plaques.
    final pas = widget.decor.pas;
    final phase = (_t % 1) * pas;
    final i = phase.floor() % pas;
    final reste = phase - phase.floor();
    const fondu = 0.5;
    final a = ((reste - (1 - fondu)) / fondu).clamp(0.0, 1.0);

    // Le travelling : un aller-retour de quelques pour cent sur vingt-six
    // secondes, imperceptible mais suffisant pour que rien ne soit figé.
    final zoom = 1.06 + 0.03 * math.sin(_t * (_cycle.inMilliseconds / 26000) * 2 * math.pi);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        final largeur = MediaQuery.sizeOf(context).width;
        setState(() {
          // Le doigt reprend la main : le tour d'horizon s'arrête là où il
          // en est, il ne ramène pas le regard de force.
          _tourFini = true;
          _cible = (_cible - d.delta.dx / largeur).clamp(0.0, 1.0);
        });
      },
      child: LayoutBuilder(
        builder: (context, c) {
          Widget plan(int index, double opacite) => Opacity(
                opacity: opacite,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  alignment: Alignment(_regard * 2 - 1, 0),
                  child: Transform.scale(
                    scale: zoom,
                    child: Image.asset(
                      widget.decor.chemin(widget.decor.cle(index)),
                      height: c.maxHeight,
                      fit: BoxFit.fitHeight,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              );
          // La même transformation que l'image, refaite à la main : c'est
          // elle qui pose une porte sur sa porte, et non à côté.
          final hauteurPlaque = c.maxHeight * zoom;
          final largeurPlaque = hauteurPlaque * ratioPlaque;
          final gauche = (c.maxWidth - largeurPlaque) * _regard;
          final haut = (c.maxHeight - hauteurPlaque) / 2;
          Rect surEcran(Zone z) => Rect.fromLTWH(
                gauche + z.x * largeurPlaque,
                haut + z.y * hauteurPlaque,
                z.largeur * largeurPlaque,
                z.hauteur * hauteurPlaque,
              );
          // Un souffle lent, pour qu'une ouverture se remarque sans
          // clignoter : elle doit se voir, pas se réclamer.
          final souffle = .5 + .5 * math.sin(_t * 2 * math.pi);

          return Stack(
            fit: StackFit.expand,
            children: [
              plan(i, 1),
              if (a > 0) plan(i + 1, a),
              // Les objets achetés, posés sur la plaque avant les
              // ouvertures : une porte reste touchable même si un meuble
              // vient mordre dessus.
              for (final decoupe in widget.decoupes)
                Positioned.fromRect(
                  rect: surEcran(decoupe.zone),
                  child: IgnorePointer(
                    child: _Decoupe(chemin: decoupe.image, nuit: widget.nuit),
                  ),
                ),
              if (widget.ecran != null)
                () {
                  final r = surEcran(widget.ecran!)
                      .intersect(Rect.fromLTWH(0, 0, c.maxWidth, c.maxHeight));
                  if (r.width < 30 || r.height < 20) return const SizedBox.shrink();
                  return Positioned.fromRect(
                    rect: r,
                    child: _EcranDuMur(
                      nuit: widget.nuit,
                      connus: widget.lieuxConnus,
                      souffle: souffle,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CartePaysEcran(
                            nuit: widget.nuit, connus: widget.lieuxConnus),
                      )),
                    ),
                  );
                }(),
              for (final passage in widget.passages)
                () {
                  // Une ouverture ne se dessine que sur sa part visible :
                  // une porte à demi sortie du champ garderait sinon son
                  // nom hors de l'écran, donc hors d'atteinte du doigt.
                  final r = surEcran(passage.zone)
                      .intersect(Rect.fromLTWH(0, 0, c.maxWidth, c.maxHeight));
                  if (r.width < 40 || r.height < 40) return const SizedBox.shrink();
                  return Positioned.fromRect(
                    rect: r,
                    // C'est par les ouvertures qu'on circule dans le palais :
                    // sans ce nœud, un lecteur d'écran n'y trouve aucune porte.
                    child: Semantics(
                      button: true,
                      label: 'Aller vers ${passage.nom}',
                      onTap: () => widget.vers(passage.vers),
                      child: _Ouverture(
                        nom: passage.nom,
                        souffle: souffle,
                        onTap: () => widget.vers(passage.vers),
                      ),
                    ),
                  );
                }(),
            ],
          );
        },
      ),
    );
  }
}

/// Un voile sombre en haut et en bas, pour que le texte reste lisible
/// quelle que soit l'image derrière.
class _Voile extends StatelessWidget {
  const _Voile();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Couleurs.encre.withValues(alpha: .72),
                Couleurs.encre.withValues(alpha: .10),
                Couleurs.encre.withValues(alpha: .34),
                Couleurs.encre.withValues(alpha: .88),
              ],
              stops: const [0, .28, .58, 1],
            ),
          ),
        ),
      );
}

class _Entete extends StatelessWidget {
  const _Entete({required this.piece, required this.decor, required this.caisses});

  final Piece piece;
  final Decor decor;
  final int caisses;

  @override
  Widget build(BuildContext context) => Cadre(
        enfant: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Retour à la journée',
                icon: const Icon(Icons.west, size: 20),
                color: Couleurs.cremeDoux,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(piece.nom, style: Textes.jour),
                    const SizedBox(height: 2),
                    Text(decor.nom, style: Textes.echeance),
                  ],
                ),
              ),
              Text('$caisses', style: Textes.nomParcoursCourt.copyWith(fontSize: 20, color: Couleurs.or)),
              const SizedBox(width: 6),
              Text('caisses', style: Textes.nomJauge),
            ],
          ),
        ),
      );
}

/// Un objet acheté, posé sur le décor. L'image est la même de jour comme
/// de nuit : la teinte de nuit la ramène dans la lumière de la plaque,
/// plutôt que de livrer deux fichiers par objet.
class _Decoupe extends StatelessWidget {
  const _Decoupe({required this.chemin, required this.nuit});

  final String chemin;
  final bool nuit;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(chemin, fit: BoxFit.fill, gaplessPlayback: true);
    if (!nuit) return image;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(teinteDeNuit), BlendMode.modulate),
      child: image,
    );
  }
}

/// La carte du pays accrochée au mur du bureau, qu'on touche pour
/// l'ouvrir. Elle porte le même contour qui respire que les portes, et son
/// nom sous le cadre : c'est une chose qu'on touche, et rien d'autre ne le
/// disait. Elle s'allume et s'éteint avec le palais.
class _EcranDuMur extends StatelessWidget {
  const _EcranDuMur({
    required this.nuit,
    required this.connus,
    required this.souffle,
    required this.onTap,
  });

  final bool nuit;
  final Set<String> connus;
  final double souffle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'La carte du pays',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Couleurs.or.withValues(alpha: .22 + .26 * souffle),
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: (nuit ? Couleurs.creme : Couleurs.or)
                          .withValues(alpha: .10 + .16 * souffle),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                    const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: PlaqueDuPays(nuit: nuit, connus: connus, avecNoms: false),
                ),
              ),
            ),
            // Le nom sous le cadre, et non dedans comme pour les portes :
            // la carte est petite, et une étiquette posée par-dessus
            // mangerait le pays qu'elle annonce. Il est retiré de
            // l'arbre d'accessibilité : lu à la suite du nœud qui le
            // porte, il ferait annoncer « la carte du pays, le pays ».
            const Positioned(
              left: -24,
              right: -24,
              bottom: -19,
              child: ExcludeSemantics(
                child: IgnorePointer(child: Center(child: _NomDuCadre('Le pays'))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le nom posé sous un cadre ou au bas d'une ouverture : fond sombre,
/// petites capitales, une seule ligne. Les portes et la carte le partagent,
/// pour qu'on reconnaisse d'un coup d'œil ce qui se touche.
class _NomDuCadre extends StatelessWidget {
  const _NomDuCadre(this.nom);

  final String nom;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Couleurs.encre.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          nom,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Textes.nomJauge.copyWith(
            color: Couleurs.creme,
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
      );
}

/// Une ouverture dans le décor : une baie, une porte, une colonnade. Pas
/// un bouton posé sur l'image — un rectangle qui épouse l'ouverture vraie,
/// et qui se déplace avec le regard du joueur.
class _Ouverture extends StatelessWidget {
  const _Ouverture({required this.nom, required this.souffle, required this.onTap});

  final String nom;

  /// De 0 à 1, le battement lent qui fait remarquer l'ouverture.
  final double souffle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Couleurs.or.withValues(alpha: .18 + .22 * souffle), width: 1.2),
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Couleurs.or.withValues(alpha: 0),
                Couleurs.or.withValues(alpha: .05 + .07 * souffle),
              ],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NomDuCadre(nom),
            ),
          ),
        ),
      );
}

/// Le demi-tour. On est toujours dos à quelque chose : depuis n'importe
/// quelle pièce, cette ligne ramène au bureau. C'est la sortie de secours
/// du palais — si une ouverture tombait mal, aucune pièce n'enferme.
class _DemiTour extends StatelessWidget {
  const _DemiTour({required this.depuis, required this.vers});

  final Piece depuis;
  final void Function(Piece) vers;

  @override
  Widget build(BuildContext context) {
    final retour = demiTourDepuis(depuis);
    if (retour == null) return const SizedBox(height: 10);
    return GestureDetector(
      onTap: () => vers(retour),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.keyboard_return, size: 14, color: Couleurs.cremeDoux),
            const SizedBox(width: 8),
            Text(
              'Revenir au bureau',
              style: Textes.nomJauge.copyWith(color: Couleurs.cremeDoux, fontSize: 11, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce qu'on peut acheter ici — replié par défaut. Le palais est d'abord un
/// endroit qu'on regarde : un catalogue ouvert en permanence recouvrirait
/// l'image, et la pièce ne servirait plus à rien.
class _Tiroir extends StatefulWidget {
  const _Tiroir({
    required this.piece,
    required this.etat,
    required this.objets,
    required this.catalogue,
    required this.achete,
  });

  final Piece piece;
  final EtatPartie etat;
  final Set<String> objets;
  final List<Objet> catalogue;
  final void Function(Objet) achete;

  @override
  State<_Tiroir> createState() => _TiroirState();
}

class _TiroirState extends State<_Tiroir> {
  bool _ouvert = false;

  /// Le dernier objet payé, et le compte à rebours qui efface son reçu.
  /// Sans ça, on paie et il ne se passe rien de visible : la ligne du
  /// catalogue passe à « Au palais » pendant que le joueur regarde
  /// ailleurs, et les caisses baissent sans explication.
  Objet? _paye;
  Timer? _effacement;

  @override
  void dispose() {
    _effacement?.cancel();
    super.dispose();
  }

  void _paie(Objet objet) {
    widget.achete(objet);
    _effacement?.cancel();
    setState(() => _paye = objet);
    _effacement = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _paye = null);
    });
  }

  @override
  void didUpdateWidget(_Tiroir ancien) {
    super.didUpdateWidget(ancien);
    // On change de pièce : le tiroir se referme, sinon on arrive dans la
    // chambre avec le catalogue du bureau grand ouvert devant les yeux.
    // Le reçu s'en va avec, il ne concerne plus la pièce où l'on est.
    if (ancien.piece != widget.piece && (_ouvert || _paye != null)) {
      _effacement?.cancel();
      setState(() {
        _ouvert = false;
        _paye = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = widget.catalogue;
    if (catalogue.isEmpty) return const SizedBox.shrink();

    final restants = catalogue.where((o) => !widget.objets.contains(o.id)).toList();
    final moinsCher = restants.isEmpty
        ? null
        : restants.map((o) => o.prix).reduce((a, b) => a < b ? a : b);
    final resume = restants.isEmpty
        ? 'Tout est là'
        : '${restants.length} objet${restants.length > 1 ? 's' : ''} · à partir de $moinsCher';

    return Cadre(
      enfant: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_ouvert)
              ConstrainedBox(
                // Jamais plus de la moitié de l'écran : la pièce doit
                // rester visible derrière ce qu'on lui achète.
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .48),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final o in catalogue)
                        _Ligne(
                          objet: o,
                          possede: widget.objets.contains(o.id),
                          possible: achetable(widget.etat, o, widget.objets),
                          onTap: () => _paie(o),
                        ),
                    ],
                  ),
                ),
              ),
            if (_paye != null) _Recu(objet: _paye!),
            Semantics(
              button: true,
              label: _ouvert ? 'Fermer le tiroir des objets' : '$resume. Ouvrir le tiroir',
              onTap: () => setState(() => _ouvert = !_ouvert),
              child: _Poignee(
                texte: _ouvert ? 'Fermer' : resume,
                ouvert: _ouvert,
                onTap: () => setState(() => _ouvert = !_ouvert),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le reçu d'un achat : ce qui a été pris, et ce que ça a fait tout de
/// suite. Il s'efface au bout de six secondes, ou en changeant de pièce.
class _Recu extends StatelessWidget {
  const _Recu({required this.objet});

  final Objet objet;

  @override
  Widget build(BuildContext context) {
    final dit = [
      objet.nom,
      '− ${objet.prix} caisses',
      ...effetsImmediats(objet),
    ].join(' · ');
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Couleurs.nuitClair.withValues(alpha: .86),
          border: Border.all(color: Couleurs.or.withValues(alpha: .5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          dit,
          textAlign: TextAlign.center,
          style: Textes.echeance.copyWith(color: Couleurs.creme),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _Poignee extends StatelessWidget {
  const _Poignee({required this.texte, required this.ouvert, required this.onTap});

  final String texte;
  final bool ouvert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Couleurs.nuitClair.withValues(alpha: .82),
            border: Border.all(color: Couleurs.bordure),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ouvert ? Icons.expand_more : Icons.expand_less, size: 16, color: Couleurs.or),
              const SizedBox(width: 8),
              Text(texte, style: Textes.nomJauge.copyWith(color: Couleurs.cremeDoux, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.objet,
    required this.possede,
    required this.possible,
    required this.onTap,
  });

  final Objet objet;
  final bool possede;
  final bool possible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleur = possede
        ? Couleurs.cremeDoux.withValues(alpha: .45)
        : (possible ? Couleurs.creme : Couleurs.cremeDoux.withValues(alpha: .45));
    final effets = effetsImmediats(objet);
    return Semantics(
      button: !possede && possible,
      label: [
        objet.nom,
        '${objet.prix} points de caisses',
        if (!possede) ...effets,
      ].join(', '),
      child: GestureDetector(
        onTap: possede || !possible ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Couleurs.nuitClair.withValues(alpha: .76),
            border: Border.all(color: possede ? Couleurs.bordure : (possible ? Couleurs.or : Couleurs.bordure)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(objet.nom, style: Textes.sousTitre.copyWith(color: couleur, fontSize: 14)),
                    const SizedBox(height: 1),
                    Text(
                      possede ? 'Au palais' : objet.description,
                      style: Textes.echeance,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Ce que l'achat fait comptant, avant de payer. Trois
                    // objets du catalogue en ont un : les autres ouvrent
                    // quelque chose plus tard, et n'annoncent rien ici.
                    if (!possede && effets.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        effets.join(' · '),
                        style: Textes.echeance.copyWith(color: Couleurs.or),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                possede ? '—' : '${objet.prix}',
                style: Textes.deltaJauge.copyWith(
                  fontSize: 15,
                  color: possede ? Couleurs.cremeDoux.withValues(alpha: .4) : (possible ? Couleurs.or : Couleurs.cremeDoux.withValues(alpha: .4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un battement par trame, sans dépendre de `SchedulerBinding` côté appel :
/// le décor doit vivre tant que l'écran est monté, et s'arrêter net sinon.
class Ticker {
  Ticker(this._bat);

  final void Function(Duration) _bat;
  bool _actif = false;
  Duration _debut = Duration.zero;
  Timer? _minuterie;

  void start() {
    _actif = true;
    _debut = Duration.zero;
    _minuterie = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_actif) return;
      _debut += const Duration(milliseconds: 40);
      _bat(_debut);
    });
  }

  void dispose() {
    _actif = false;
    _minuterie?.cancel();
  }
}

/// Les trois temps d'une soirée promise. Le palais avance à l'horloge
/// partout ailleurs ; ici il attend le doigt, et c'est ce qui fait la
/// différence entre un décor et une scène.
/// La scène du rendez-vous. Elle remplace la chambre entière tant que le
/// drapeau tient : on arrive, la personne attend habillée, un appui la
/// fait se déshabiller, un second emmène sur le lit, un troisième rend au
/// bureau et éteint le rendez-vous.
class _SceneRendezVous extends StatefulWidget {
  const _SceneRendezVous({
    required this.rdv,
    required this.replique,
    required this.fini,
    super.key,
  });

  final RendezVous rdv;

  /// Ce que la personne dit à ce moment-là, ou rien : une personne sans
  /// texte laisse la scène muette au lieu d'arrêter le jeu.
  final String? Function(TempsChambre) replique;

  /// Appelée une fois, à la sortie : c'est elle qui consomme le drapeau.
  final VoidCallback fini;

  @override
  State<_SceneRendezVous> createState() => _SceneRendezVousState();
}

class _SceneRendezVousState extends State<_SceneRendezVous> with SingleTickerProviderStateMixin {
  /// Ce que dure chaque pose pendant qu'elle se déshabille. Trois poses,
  /// soit un peu moins de trois secondes : assez pour qu'on suive, trop
  /// court pour qu'on s'impatiente.
  static const _pose = Duration(milliseconds: 900);

  /// La boucle du lit, au même rythme que le reste du palais.
  static const _cycle = Duration(seconds: 8);

  TempsChambre _temps = TempsChambre.habille;

  /// La pose debout affichée, de 1 à 4.
  int _pas = 1;
  Timer? _minuteur;

  late final Ticker _ticker = Ticker((e) {
    if (_temps == TempsChambre.lit) setState(() => _t = e.inMilliseconds / _cycle.inMilliseconds);
  });
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _touche() {
    switch (_temps) {
      case TempsChambre.habille:
        setState(() => _temps = TempsChambre.deshabille);
        _minuteur = Timer.periodic(_pose, (t) {
          // La dernière pose reste : on ne boucle pas sur le début, ce
          // serait la rhabiller.
          if (_pas >= 4) {
            t.cancel();
            return;
          }
          setState(() => _pas++);
        });
      case TempsChambre.deshabille:
        // Pas avant la fin des quatre poses : un doigt pressé sauterait
        // la seule chose qu'il est venu voir.
        if (_pas < 4) return;
        _minuteur?.cancel();
        setState(() => _temps = TempsChambre.lit);
      case TempsChambre.lit:
        widget.fini();
    }
  }

  /// Ce qu'on invite à faire, ou rien pendant que ça se joue.
  String? get _invite => switch (_temps) {
        TempsChambre.habille => 'Approcher',
        TempsChambre.deshabille => _pas >= 4 ? 'Rejoindre le lit' : null,
        TempsChambre.lit => 'Revenir au bureau',
      };

  @override
  Widget build(BuildContext context) {
    final decor = _temps == TempsChambre.lit ? widget.rdv.lit : widget.rdv.debout;
    final invite = _invite;
    final dit = widget.replique(_temps);
    return GestureDetector(
      onTap: _touche,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_temps == TempsChambre.lit) _boucleDuLit(decor) else _poseDebout(decor),
          const _Voile(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // La réplique se pose au-dessus de l'invitation, sur le
                // voile qui est déjà là. Elle se fond d'un temps à l'autre
                // plutôt que de sauter : on la lit pendant que l'image
                // change.
                if (dit != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        dit,
                        key: ValueKey(dit),
                        textAlign: TextAlign.center,
                        style: Textes.texteCarte.copyWith(fontSize: 17, height: 1.34),
                      ),
                    ),
                  ),
                if (invite != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 34),
                    child: Text(
                      invite,
                      style: Textes.nomJauge.copyWith(
                        color: Couleurs.creme,
                        fontSize: 11,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Une pose debout, sur une plaque en trois-deux dont l'écran ne montre
  /// que le milieu : c'est là que la personne se tient.
  Widget _poseDebout(Decor decor) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: Image.asset(
          decor.chemin(_pas),
          key: ValueKey(_pas),
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );

  /// La boucle du lit : six images en aller-retour, en fondu, et l'image
  /// est en portrait — elle remplit l'écran sans qu'on ait à la déplacer.
  Widget _boucleDuLit(Decor decor) {
    final pas = decor.pas;
    final phase = (_t % 1) * pas;
    final i = phase.floor() % pas;
    final reste = phase - phase.floor();
    const fondu = 0.5;
    final a = ((reste - (1 - fondu)) / fondu).clamp(0.0, 1.0);
    Widget plan(int index, double opacite) => Opacity(
          opacity: opacite,
          child: Image.asset(decor.chemin(decor.cle(index)), fit: BoxFit.cover, gaplessPlayback: true),
        );
    return Stack(fit: StackFit.expand, children: [plan(i, 1), if (a > 0) plan(i + 1, a)]);
  }
}
