import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/etat_partie.dart';
import '../moteur/modeles.dart';
import '../sauvegarde/sauvegarde.dart';
import 'partie_ecran.dart';
import 'session.dart';

/// Premier écran : qui étiez-vous avant, et comment vous appelez-vous.
class AccueilEcran extends ConsumerStatefulWidget {
  const AccueilEcran({super.key});

  @override
  ConsumerState<AccueilEcran> createState() => _AccueilEcranState();
}

class _AccueilEcranState extends ConsumerState<AccueilEcran> {
  final _nom = TextEditingController();
  String? _choisi;
  EtatPartie? _enCours;

  @override
  void initState() {
    super.initState();
    _relisSauvegarde();
  }

  /// Relit la sauvegarde sur l'appareil. À rappeler chaque fois que l'accueil
  /// redevient visible : une partie peut avoir été perdue ou quittée entre
  /// temps, et le bouton « Reprendre » doit refléter l'état réel.
  Future<void> _relisSauvegarde() async {
    final e = await Sauvegarde.lis();
    if (mounted) setState(() => _enCours = e);
  }

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contenu = ref.watch(contenuProvider);

    return Scaffold(
      body: SafeArea(
        child: contenu.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Contenu illisible : $e')),
          data: (c) {
            final parcours = c.parcours;
            final pret = _choisi != null && _nom.text.trim().isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Le logo porte le nom du jeu ; le sous-titre dit ce qu'on y fait.
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Image.asset('assets/icone/logo.png',
                      height: 170, fit: BoxFit.contain, alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => const Text('Palabre',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 0, 22, 2),
                  child: Text('Président pour 100 jours',
                      style: TextStyle(fontSize: 15, letterSpacing: .3, color: Color(0xFFE9B44C))),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Text('Qui étiez-vous avant ?', style: TextStyle(color: Colors.white70)),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: parcours.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CarteParcours(
                      parcours: parcours[i],
                      choisi: _choisi == parcours[i].id,
                      onTap: () => setState(() {
                        _choisi = parcours[i].ouvertDesLeDebut ? parcours[i].id : null;
                      }),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    children: [
                      if (_enCours != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                ref.read(sessionProvider.notifier).reprend(_enCours!);
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PartieEcran()),
                                );
                                await _relisSauvegarde();
                              },
                              child: Text('Reprendre le jour ${_enCours!.jour}'),
                            ),
                          ),
                        ),
                      TextField(
                        controller: _nom,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Votre nom',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: !pret
                              ? null
                              : () async {
                                  final p = c.parcoursParId(_choisi!)!;
                                  ref.read(sessionProvider.notifier).demarre(parcours: p, nom: _nom.text.trim());
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const PartieEcran()),
                                  );
                                  await _relisSauvegarde();
                                },
                          child: const Text('Prendre mes fonctions'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CarteParcours extends StatelessWidget {
  const _CarteParcours({required this.parcours, required this.choisi, required this.onTap});

  final Parcours parcours;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final verrouille = !parcours.ouvertDesLeDebut;
    return Opacity(
      opacity: verrouille ? 0.45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: choisi ? const Color(0xFFE9B44C) : Colors.white24, width: choisi ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parcours.nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    if (verrouille)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(parcours.conditionDeblocage!,
                            style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                      ),
                  ],
                ),
              ),
              if (verrouille) const Icon(Icons.lock_outline, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
