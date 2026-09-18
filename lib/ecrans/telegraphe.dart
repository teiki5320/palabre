import 'dart:async';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Le journal du lendemain, frappé lettre à lettre comme sur un télégraphe.
///
/// La frappe ne bloque jamais rien : le joueur peut glisser la carte
/// suivante pendant que la ligne s'écrit, et un appui la termine d'un coup
/// pour ceux qui lisent plus vite que la machine.
class Telegraphe extends StatefulWidget {
  const Telegraphe({super.key, required this.ligne});

  /// La brève du jour, ou null s'il n'y en a pas pour cette carte.
  final String? ligne;

  /// Le temps mis par chaque caractère. Six millisecondes : une brève de
  /// cent vingt signes s'écrit en sept dixièmes de seconde.
  static const parCaractere = Duration(milliseconds: 6);

  @override
  State<Telegraphe> createState() => _TelegrapheState();
}

class _TelegrapheState extends State<Telegraphe> {
  Timer? _frappe;
  int _jusqua = 0;

  @override
  void initState() {
    super.initState();
    _lance();
  }

  @override
  void didUpdateWidget(Telegraphe ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.ligne != widget.ligne) _lance();
  }

  void _lance() {
    _frappe?.cancel();
    final ligne = widget.ligne;
    if (ligne == null || ligne.isEmpty) {
      setState(() => _jusqua = 0);
      return;
    }
    setState(() => _jusqua = 0);
    _frappe = Timer.periodic(Telegraphe.parCaractere, (t) {
      if (!mounted) return t.cancel();
      setState(() => _jusqua++);
      if (_jusqua >= ligne.length) t.cancel();
    });
  }

  void _termine() {
    final ligne = widget.ligne;
    if (ligne == null) return;
    _frappe?.cancel();
    setState(() => _jusqua = ligne.length);
  }

  @override
  void dispose() {
    _frappe?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ligne = widget.ligne;
    // Pas de ligne pour cette carte : rien du tout, et surtout pas un
    // espace réservé qui ferait sauter la mise en page d'une carte à
    // l'autre.
    if (ligne == null || ligne.isEmpty) return const SizedBox.shrink();
    final fini = _jusqua >= ligne.length;

    return Semantics(
      liveRegion: true,
      label: ligne,
      child: GestureDetector(
        onTap: fini ? null : _termine,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.fromLTRB(4, 2, 4, 8),
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
          decoration: BoxDecoration(
            color: Couleurs.encre.withValues(alpha: .66),
            border: Border.all(color: Couleurs.bordure),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LE QUOTIDIEN',
                style: Textes.nomJauge.copyWith(color: Couleurs.or, fontSize: 9, letterSpacing: 1.6),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: ligne.substring(0, _jusqua.clamp(0, ligne.length))),
                    if (!fini)
                      const TextSpan(
                        text: '▌',
                        style: TextStyle(color: Couleurs.or),
                      ),
                  ],
                ),
                style: Textes.sousTitre.copyWith(
                  color: Couleurs.cremeDoux,
                  fontSize: 12.5,
                  height: 1.42,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
