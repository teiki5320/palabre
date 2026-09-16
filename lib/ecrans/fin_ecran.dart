import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/denouement.dart';
import 'session.dart';

/// Ce qu'on voit quand le mandat s'arrête : la fin écrite, les jours tenus,
/// et l'invitation à recommencer.
class FinEcran extends ConsumerWidget {
  const FinEcran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null || !session.terminee) return const Scaffold(body: SizedBox.shrink());

    final fin = session.fin;
    final jours = session.etat.jour - 1;
    final gagnee = session.denouement!.type == TypeDenouement.electionGagnee;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (fin != null)
            Image.asset(
              'assets/images/${fin.image}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1620)),
            )
          else
            Container(color: const Color(0xFF1A1620)),
          Container(color: Colors.black.withValues(alpha: 0.55)),
          SafeArea(
            child: LayoutBuilder(
              // Alignement en bas pour un texte court, défilement pour une
              // fin longue qui déborderait sur un petit écran.
              builder: (context, contraintes) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: contraintes.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          gagnee ? 'RÉÉLU' : 'FIN DU MANDAT',
                          style: const TextStyle(
                              color: Color(0xFFE9B44C), letterSpacing: 2.5, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          fin?.titre ?? "Le mandat s'arrête",
                          style:
                              const TextStyle(color: Colors.white, fontSize: 30, height: 1.1, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          fin?.texte ?? '',
                          style: const TextStyle(color: Color(0xFFE3D9C9), fontSize: 16, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Vous avez tenu $jours jours.',
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              ref.read(sessionProvider.notifier).arrete();
                              Navigator.of(context).popUntil((r) => r.isFirst);
                            },
                            child: const Text('Reprendre ses fonctions'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
