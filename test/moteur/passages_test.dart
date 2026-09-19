import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/decor.dart';
import 'package:president/moteur/palais.dart';

/// Les ouvertures du palais. Le joueur ne choisit plus une pièce dans une
/// liste : il touche une porte dans l'image. Ce qui doit rester vrai, c'est
/// qu'aucune porte ne sorte de sa plaque, et qu'aucune pièce n'enferme.
void main() {
  test('aucune ouverture ne déborde de sa plaque', () {
    for (final piece in Piece.values) {
      for (final p in passagesDe(piece)) {
        final z = p.zone;
        expect(z.x, inInclusiveRange(0, 1), reason: '${piece.name} → ${p.nom}');
        expect(z.y, inInclusiveRange(0, 1), reason: '${piece.name} → ${p.nom}');
        expect(z.droite, lessThanOrEqualTo(1.0), reason: '${piece.name} → ${p.nom}');
        expect(z.bas, lessThanOrEqualTo(1.0), reason: '${piece.name} → ${p.nom}');
      }
    }
  });

  test('aucune ouverture n est trop petite pour un doigt', () {
    // Un huitième de la plaque en largeur : sur un téléphone tenu à la
    // main, c'est le plancher en dessous duquel on tape à côté.
    for (final piece in Piece.values) {
      for (final p in passagesDe(piece)) {
        expect(p.zone.largeur, greaterThanOrEqualTo(0.12), reason: '${piece.name} → ${p.nom}');
        expect(p.zone.hauteur, greaterThanOrEqualTo(0.12), reason: '${piece.name} → ${p.nom}');
      }
    }
  });

  test('aucune ouverture ne mène à la pièce où l on est', () {
    for (final piece in Piece.values) {
      for (final p in passagesDe(piece)) {
        expect(p.vers, isNot(piece), reason: '${piece.name} boucle sur elle-même');
      }
    }
  });

  test('deux ouvertures d une même pièce ne se chevauchent pas', () {
    for (final piece in Piece.values) {
      final l = passagesDe(piece);
      for (var i = 0; i < l.length; i++) {
        for (var j = i + 1; j < l.length; j++) {
          final a = l[i].zone;
          final b = l[j].zone;
          final croise = a.x < b.droite && b.x < a.droite && a.y < b.bas && b.y < a.bas;
          expect(croise, isFalse, reason: '${piece.name} : « ${l[i].nom} » et « ${l[j].nom} »');
        }
      }
    }
  });

  test('le bureau est le vestibule : on en repart, on n y revient pas par un demi-tour', () {
    expect(demiTourDepuis(Piece.bureau), isNull);
    for (final piece in Piece.values.where((p) => p != Piece.bureau)) {
      expect(demiTourDepuis(piece), Piece.bureau, reason: piece.name);
    }
  });

  test('les cinq pièces se rejoignent depuis le bureau', () {
    final vues = <Piece>{Piece.bureau};
    final aVoir = <Piece>[Piece.bureau];
    while (aVoir.isNotEmpty) {
      final ici = aVoir.removeLast();
      for (final p in passagesDe(ici)) {
        if (vues.add(p.vers)) aVoir.add(p.vers);
      }
    }
    expect(vues, Piece.values.toSet(), reason: 'pièces inatteignables : ${Piece.values.toSet().difference(vues)}');
  });

  test('aucune pièce n enferme : on repart toujours', () {
    for (final piece in Piece.values) {
      final sorties = passagesDe(piece).length + (demiTourDepuis(piece) == null ? 0 : 1);
      expect(sorties, greaterThan(0), reason: '${piece.name} n\'a aucune sortie');
    }
  });

  test('le balcon se quitte par le demi-tour, faute de porte dans le champ', () {
    // On y est accoudé, dos au palais : il n'y a rien à toucher devant soi.
    expect(passagesDe(Piece.balcon), isEmpty);
    expect(demiTourDepuis(Piece.balcon), Piece.bureau);
  });

  test('la plaque est en trois-deux, et le placement des portes en dépend', () {
    expect(ratioPlaque, closeTo(1.5, 0.0001));
  });

  group('le tour d horizon d entrée', () {
    test('part du centre et y revient', () {
      expect(regardDuTour(0), closeTo(0.5, 0.001));
      expect(regardDuTour(1), closeTo(0.5, 0.001));
    });

    test('touche les deux bords en chemin', () {
      final parcouru = [for (var i = 0; i <= 100; i++) regardDuTour(i / 100)];
      expect(parcouru.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(0.11));
      expect(parcouru.reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(0.89));
    });

    test('ne sort jamais de la plaque', () {
      for (var i = 0; i <= 100; i++) {
        expect(regardDuTour(i / 100), inInclusiveRange(0, 1));
      }
    });

    test('ne saute jamais : aucun à-coup d un instant au suivant', () {
      var precedent = regardDuTour(0);
      for (var i = 1; i <= 400; i++) {
        final v = regardDuTour(i / 400);
        expect((v - precedent).abs(), lessThan(0.02), reason: 'saut à ${i / 400}');
        precedent = v;
      }
    });

    test('hors bornes, il se tient au centre', () {
      expect(regardDuTour(-3), closeTo(0.5, 0.001));
      expect(regardDuTour(9), closeTo(0.5, 0.001));
    });
  });
}
