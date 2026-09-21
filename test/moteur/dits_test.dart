import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/dits.dart';

const _source = '{'
    '"maire":{'
    '"liaison":{"habille":"Une reunion.","deshabille":"Un budget.","lit":"Eteignez."},'
    '"marie":{"habille":"Ta garde.","deshabille":"Trois arretes.","lit":"Viens."}'
    '},'
    '"epoux":{'
    '"liaison":{"habille":"L aile est.","deshabille":"Onze ans.","lit":"Personne."},'
    '"marie":{"habille":"Du the.","deshabille":"Debout.","lit":"Laisse-moi."}'
    '}}';

void main() {
  final dits = DitsDeLaChambre.depuisJson(_source);

  test('la liaison et le mariage ne disent pas la meme chose', () {
    expect(dits.dit('maire', marie: false, temps: TempsChambre.lit), 'Eteignez.');
    expect(dits.dit('maire', marie: true, temps: TempsChambre.lit), 'Viens.');
  });

  test('les trois temps portent chacun leur replique', () {
    expect(dits.dit('epoux', marie: false, temps: TempsChambre.habille), 'L aile est.');
    expect(dits.dit('epoux', marie: false, temps: TempsChambre.deshabille), 'Onze ans.');
    expect(dits.dit('epoux', marie: false, temps: TempsChambre.lit), 'Personne.');
  });

  test('une personne sans texte laisse la scene muette, elle ne la casse pas', () {
    expect(dits.dit('militante', marie: false, temps: TempsChambre.lit), isNull);
    expect(DitsDeLaChambre.muette.dit('maire', marie: false, temps: TempsChambre.lit), isNull);
    expect(DitsDeLaChambre.muette.muet, isTrue);
  });

  test('les personnes lues sont celles du fichier', () {
    expect(dits.personnes, containsAll(['maire', 'epoux']));
    expect(dits.muet, isFalse);
  });
}
