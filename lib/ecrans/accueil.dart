import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../moteur/modeles.dart';
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 22, 22, 6),
                  child: Text('Président pour 100 jours',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
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
                              : () {
                                  final p = c.parcoursParId(_choisi!)!;
                                  ref.read(sessionProvider.notifier).demarre(parcours: p, nom: _nom.text.trim());
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const PartieEcran()),
                                  );
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
