import 'package:flutter_test/flutter_test.dart';
import 'package:president/ecrans/sons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Le greffon audio n'existe pas en test, mais le liant si : c'est la
  // situation d'un appareil où le son échoue, et pas celle d'un moteur
  // sans Flutter.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('le son est allume tant que personne ne l a coupe', () async {
    final sons = Sons();
    await sons.relisLeReglage();
    expect(sons.coupe, isFalse);
  });

  test('le reglage survit au relancement du jeu', () async {
    final avant = Sons();
    await avant.coupeLe(true);
    expect(avant.coupe, isTrue);

    final apres = Sons();
    await apres.relisLeReglage();
    expect(apres.coupe, isTrue, reason: 'le silence demande doit etre garde');

    await apres.coupeLe(false);
    final encore = Sons();
    await encore.relisLeReglage();
    expect(encore.coupe, isFalse);
  });

  test('sans greffon audio, jouer un son ne casse rien', () async {
    final sons = Sons();
    // `prepare` echoue faute de plateforme : la table reste vide, et c est
    // exactement la situation qu on veut voir passer sans erreur.
    await sons.prepare();
    expect(() => sons.joue(Son.decision), returnsNormally);
    await sons.coupeLe(true);
    expect(() => sons.joue(Son.reelu), returnsNormally);
  });
}
