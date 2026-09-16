import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/jauges.dart';

void main() {
  test('applique additionne les effets', () {
    final j = Jauges.milieu.applique({Jauge.armee: 10, Jauge.caisses: -15});
    expect(j.armee, 60);
    expect(j.caisses, 35);
    expect(j.peuple, 50);
    expect(j.presse, 50);
  });

  test('applique borne entre 0 et 100', () {
    final basse = const Jauges(peuple: 5, armee: 95, caisses: 50, presse: 50)
        .applique({Jauge.peuple: -20, Jauge.armee: 20});
    expect(basse.peuple, 0);
    expect(basse.armee, 100);
  });

  test('extreme signale la premiere jauge a bout, dans l ordre', () {
    expect(Jauges.milieu.extreme(), isNull);
    expect(const Jauges(peuple: 0, armee: 50, caisses: 50, presse: 50).extreme(), Jauge.peuple);
    expect(const Jauges(peuple: 50, armee: 50, caisses: 100, presse: 0).extreme(), Jauge.caisses);
  });

  test('valeur lit la bonne jauge', () {
    const j = Jauges(peuple: 1, armee: 2, caisses: 3, presse: 4);
    expect(j.valeur(Jauge.presse), 4);
  });
}
