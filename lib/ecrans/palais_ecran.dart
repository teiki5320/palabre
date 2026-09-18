import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/decor.dart';
import '../moteur/etat_partie.dart';
import '../moteur/palais.dart';
import 'session.dart';
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const Scaffold(body: SizedBox.shrink());
    final objets = ref.watch(progressionProvider).value?.objets ?? const <String>{};
    final contenu = ref.watch(contenuProvider).value;
    final decor = decorDe(_piece, session.etat, objets);

    return Scaffold(
      backgroundColor: Couleurs.nuit,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Decor(decor: decor, cle: ValueKey('${_piece.name}-${decor.etat}')),
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
                _Portes(piece: _piece, vers: (p) => setState(() => _piece = p)),
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
  const _Decor({required this.decor, required this.cle});

  final Decor decor;
  final Key cle;

  @override
  State<_Decor> createState() => _DecorState();
}

class _DecorState extends State<_Decor> with SingleTickerProviderStateMixin {
  static const _cycle = Duration(seconds: 8);
  late final Ticker _ticker = Ticker(_bat);
  double _t = 0;
  double _regard = 0.5; // 0 = tout à gauche, 1 = tout à droite
  double _cible = 0.5;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  void _bat(Duration ecoule) {
    setState(() {
      _t = ecoule.inMilliseconds / _cycle.inMilliseconds;
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
    final n = widget.decor.images;
    final phase = (_t % 1) * n;
    final i = phase.floor() % n;
    final reste = phase - phase.floor();
    const fondu = 0.5;
    final a = ((reste - (1 - fondu)) / fondu).clamp(0.0, 1.0);
    final suivant = (i + 1) % n;

    // Le travelling : un aller-retour de quelques pour cent sur vingt-six
    // secondes, imperceptible mais suffisant pour que rien ne soit figé.
    final zoom = 1.06 + 0.03 * math.sin(_t * (_cycle.inMilliseconds / 26000) * 2 * math.pi);

    return GestureDetector(
      key: widget.cle,
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        final largeur = MediaQuery.sizeOf(context).width;
        setState(() => _cible = (_cible - d.delta.dx / largeur).clamp(0.0, 1.0));
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
                      widget.decor.chemin(index + 1),
                      height: c.maxHeight,
                      fit: BoxFit.fitHeight,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              );
          return Stack(
            fit: StackFit.expand,
            children: [
              plan(i, 1),
              if (a > 0) plan(suivant, a),
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

/// Les portes : on ne choisit pas une pièce dans une liste, on va vers
/// elle. Le bureau est le vestibule, donc il est toujours atteignable.
class _Portes extends StatelessWidget {
  const _Portes({required this.piece, required this.vers});

  final Piece piece;
  final void Function(Piece) vers;

  @override
  Widget build(BuildContext context) => Cadre(
        enfant: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final p in Piece.values)
                _Porte(nom: p.nom, ici: p == piece, onTap: () => vers(p)),
            ],
          ),
        ),
      );
}

class _Porte extends StatelessWidget {
  const _Porte({required this.nom, required this.ici, required this.onTap});

  final String nom;
  final bool ici;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: ici ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: ici ? Couleurs.or.withValues(alpha: .16) : Couleurs.nuitClair.withValues(alpha: .72),
            border: Border.all(color: ici ? Couleurs.or : Couleurs.bordure),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            nom,
            style: Textes.nomJauge.copyWith(
              color: ici ? Couleurs.or : Couleurs.cremeDoux,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
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

  @override
  void didUpdateWidget(_Tiroir ancien) {
    super.didUpdateWidget(ancien);
    // On change de pièce : le tiroir se referme, sinon on arrive dans la
    // chambre avec le catalogue du bureau grand ouvert devant les yeux.
    if (ancien.piece != widget.piece && _ouvert) setState(() => _ouvert = false);
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
                          onTap: () => widget.achete(o),
                        ),
                    ],
                  ),
                ),
              ),
            _Poignee(
              texte: _ouvert ? 'Fermer' : resume,
              ouvert: _ouvert,
              onTap: () => setState(() => _ouvert = !_ouvert),
            ),
          ],
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
    return Semantics(
      button: !possede && possible,
      label: '${objet.nom}, ${objet.prix} points de caisses',
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
