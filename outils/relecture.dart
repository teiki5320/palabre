// Fabrique une page de relecture du contenu : un tableau par personnage, les
// chaînes signalées, les effets visibles, et les mesures d'équilibrage.
//
// Usage : flutter test outils/relecture.dart
// La page est écrite dans .tmp/relecture.html. On passe par le lanceur de
// tests parce que le paquet dépend de Flutter : `dart run` ne sait pas le
// compiler. Le fichier vit hors de test/, donc il ne tourne pas en intégration
// continue : c'est un outil, pas un test.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:president/contenu/chargement.dart';
import 'package:president/contenu/validation.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/simulation.dart';

String lis(String nom) => File('assets/contenu/$nom.json').readAsStringSync();

String effets(Map<Jauge, int> e) =>
    e.entries.map((x) => '${x.key.name} ${x.value > 0 ? "+" : ""}${x.value}').join(', ');

void main() {
  test('page de relecture du contenu', () {
  final c = Contenu.depuisChaines(
    cartes: lis('cartes'),
    personnages: lis('personnages'),
    parcours: lis('parcours'),
    fins: lis('fins'),
  );
  final problemes = valide(c);

  final b = StringBuffer()
    ..writeln('<!doctype html><html lang="fr"><head><meta charset="utf-8">')
    ..writeln('<meta name="viewport" content="width=device-width,initial-scale=1">')
    ..writeln('<title>Relecture du contenu</title><style>')
    ..writeln('body{font:15px/1.55 system-ui,sans-serif;margin:0;background:#14131a;color:#f6efe4}')
    ..writeln('main{max-width:1000px;margin:0 auto;padding:28px}')
    ..writeln('h1{font-size:26px;margin:0 0 4px}h2{margin:34px 0 10px;color:#e9b44c;font-size:19px}')
    ..writeln('table{border-collapse:collapse;width:100%;margin-bottom:6px}')
    ..writeln('td,th{border-bottom:1px solid #332f3d;padding:9px 8px;text-align:left;vertical-align:top}')
    ..writeln('th{font-size:11px;text-transform:uppercase;letter-spacing:.08em;color:#a79e93;font-weight:700}')
    ..writeln('.eff{font-variant-numeric:tabular-nums;color:#c9bfae;font-size:12.5px}')
    ..writeln('.id{color:#6f6a7d;font-size:11.5px}')
    ..writeln('.ch{color:#7ec8e3;font-size:11.5px}')
    ..writeln('.cond{color:#c8a2c8;font-size:11.5px}')
    ..writeln('.ok{background:#1d3a24;padding:12px 14px;border-radius:8px}')
    ..writeln('.pb{background:#5a1d1d;padding:12px 14px;border-radius:8px}')
    ..writeln('.mes{background:#1c1b24;padding:14px;border-radius:8px;margin:14px 0}')
    ..writeln('</style></head><body><main>')
    ..writeln('<h1>Président pour 100 jours — relecture du contenu</h1>')
    ..writeln('<p class="id">${c.cartes.length} cartes · ${c.personnages.length} personnages · '
        '${c.parcours.length} parcours · ${c.fins.length} fins</p>');

  if (problemes.isEmpty) {
    b.writeln('<div class="ok">Le contrôle automatique ne signale rien.</div>');
  } else {
    b.writeln('<div class="pb"><b>${problemes.length} problème(s)</b><ul>');
    for (final p in problemes) {
      b.writeln('<li>$p</li>');
    }
    b.writeln('</ul></div>');
  }

  b.writeln('<div class="mes"><b>Équilibrage</b> — dix mille mandats simulés par parcours ouvert :<ul>');
  for (final p in c.parcours.where((p) => p.ouvertDesLeDebut)) {
    final hasard = simule(contenu: c, parcours: p.id, strategie: Strategie.auHasard, parties: 5000);
    final prudent = simule(contenu: c, parcours: p.id, strategie: Strategie.equilibree, parties: 5000);
    final fins = hasard.denouements.entries.map((e) => '${e.key} ${(e.value * 100 / hasard.parties).round()} %').join(', ');
    b.writeln('<li><b>${p.nom}</b> — au hasard : ${hasard.joursMoyens.toStringAsFixed(1)} jours en moyenne '
        '($fins) · en jouant prudemment : ${prudent.joursMoyens.toStringAsFixed(1)} jours</li>');
  }
  b.writeln('</ul></div>');

  for (final p in c.personnages.values) {
    final siennes = c.cartes.where((x) => x.personnage == p.id).toList();
    b
      ..writeln('<h2>${p.nom} — ${siennes.length} cartes</h2>')
      ..writeln('<table><tr><th>Carte</th><th>Ce qu il dit</th><th>← Gauche</th><th>Droite →</th></tr>');
    for (final carte in siennes) {
      final ch = carte.chaine;
      final cond = <String>[];
      if (carte.conditions.parcours.isNotEmpty) cond.add('parcours ${carte.conditions.parcours.join(", ")}');
      if (carte.conditions.drapeauxRequis.isNotEmpty) cond.add('si ${carte.conditions.drapeauxRequis.join(", ")}');
      for (final j in Jauge.values) {
        final min = carte.conditions.minimums[j];
        final max = carte.conditions.maximums[j];
        if (min != null) cond.add('${j.name} ≥ $min');
        if (max != null) cond.add('${j.name} ≤ $max');
      }
      if (carte.conditions.jourMin > 1) cond.add('jour ≥ ${carte.conditions.jourMin}');
      if (carte.poids != 1) cond.add('poids ${carte.poids}');

      String cote(dynamic r) {
        final drapeaux = (r.drapeaux as List).isEmpty ? '' : '<br><span class="ch">pose ${r.drapeaux.join(", ")}</span>';
        return '<b>${r.libelle}</b><br><span class="eff">${effets(r.effets as Map<Jauge, int>)}</span>$drapeaux';
      }

      b.writeln('<tr><td><span class="id">${carte.id}</span>'
          '${ch != null ? '<br><span class="ch">chaîne ${ch.id} · ${ch.rang}/3'
              '${ch.delaiMin > 0 ? " · ${ch.delaiMin} j" : ""}</span>' : ''}'
          '${cond.isEmpty ? '' : '<br><span class="cond">${cond.join(" · ")}</span>'}</td>'
          '<td>${carte.texte}</td><td>${cote(carte.gauche)}</td><td>${cote(carte.droite)}</td></tr>');
    }
    b.writeln('</table>');
  }

  b
    ..writeln('<h2>Les fins</h2><table><tr><th>Quand</th><th>Titre</th><th>Texte</th></tr>')
    ..writeln(c.fins
        .map((f) => '<tr><td><span class="id">${f.jauge?.name ?? "élection"} '
            '${f.jauge == null ? (f.versLeHaut ? "gagnée" : "perdue") : (f.versLeHaut ? "à 100" : "à 0")}</span></td>'
            '<td><b>${f.titre}</b></td><td>${f.texte}</td></tr>')
        .join('\n'))
    ..writeln('</table></main></body></html>');

  Directory('.tmp').createSync(recursive: true);
  final sortie = File('.tmp/relecture.html')..writeAsStringSync(b.toString());
  stdout.writeln('page écrite : ${sortie.path} (${c.cartes.length} cartes)');
  });
}
