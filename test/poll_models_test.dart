import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/features/poll/poll_models.dart';

void main() {
  final poll = Poll.fromJson({
    'id': 1,
    'country_code': 'SN',
    'semaine': '2026-09-07',
    'question': 'Q ?',
    'contexte': 'ctx',
    'sources': [{'titre': 'Src', 'url': 'https://example.org', 'date': '2026-01-01'}],
    'ouverture': '2026-09-07T08:00:00+00:00',
    'fermeture': '2026-09-13T20:00:00+00:00',
    'options': [
      {'id': 3, 'ordre': 3, 'libelle': 'Sans avis', 'neutre': true},
      {'id': 1, 'ordre': 1, 'libelle': 'Oui', 'neutre': false},
      {'id': 2, 'ordre': 2, 'libelle': 'Non', 'neutre': false},
    ],
    'repondants': 12,
    'suspect': false,
    'resultat_final': false,
  });

  test('l\'état se déduit des horodatages', () {
    expect(poll.statusAt(DateTime.utc(2026, 9, 7, 7, 59)), PollStatus.programme);
    expect(poll.statusAt(DateTime.utc(2026, 9, 7, 8, 0)), PollStatus.ouvert);
    expect(poll.statusAt(DateTime.utc(2026, 9, 13, 19, 59)), PollStatus.ouvert);
    expect(poll.statusAt(DateTime.utc(2026, 9, 13, 20, 0)), PollStatus.ferme);
  });

  test('les options sont triées par ordre et survivent au cache', () {
    expect(poll.options.map((o) => o.id), [1, 2, 3]);
    final again = Poll.fromJson(poll.toJson());
    expect(again.options.map((o) => o.libelle), ['Oui', 'Non', 'Sans avis']);
    expect(again.sources.single.url, 'https://example.org');
    expect(again.ouverture, poll.ouverture);
  });

  test('résultats : total, fractions et découpes', () {
    final r = PollResults.fromJson({
      'poll_id': 1,
      'repondants': 100,
      'final': true,
      'seuil': 30,
      'cellules': [
        {'dimension': 'total', 'valeur': '', 'n_cellule': 100, 'options': [{'option_id': 1, 'n': 60}, {'option_id': 2, 'n': 30}, {'option_id': 3, 'n': 10}]},
        {'dimension': 'region', 'valeur': '1', 'n_cellule': 40, 'options': [{'option_id': 1, 'n': 20}, {'option_id': 2, 'n': 20}, {'option_id': 3, 'n': 0}]},
      ],
    });
    expect(r.total!.fraction(1), 0.6);
    expect(r.hasBreakdowns, isTrue);
    expect(r.dimension('region').single.fraction(2), 0.5);
    expect(r.dimension('tranche_age'), isEmpty);
    final again = PollResults.fromJson(r.toJson());
    expect(again.total!.counts, {1: 60, 2: 30, 3: 10});
  });

  test('le flux retrouve un sondage par id', () {
    final feed = PollFeed(current: poll, archive: const []);
    expect(feed.byId(1), same(poll));
    expect(feed.byId(2), isNull);
    expect(PollFeed.fromJson(feed.toJson()).current!.question, 'Q ?');
  });
}
