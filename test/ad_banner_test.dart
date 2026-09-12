import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/core/ads/ads.dart';
import 'package:palabre/core/country/country_models.dart';
import 'package:palabre/core/country/country_providers.dart';

void main() {
  Widget host(CountryConfig config) => ProviderScope(
        overrides: [countryConfigOrFallbackProvider.overrideWithValue(config)],
        child: const MaterialApp(home: Scaffold(body: Column(children: [Expanded(child: SizedBox()), AdBanner()]))),
      );

  testWidgets('aucune bannière tant que le SDK n\'est pas prêt', (tester) async {
    await tester.pumpWidget(host(CountryConfig.fallback('SN')));
    await tester.pump();
    expect(tester.getSize(find.byType(AdBanner)), Size.zero);
  });

  testWidgets('la coupure à distance masque la bannière', (tester) async {
    final config = CountryConfig(countries: const [], regions: const [], modules: const [], appConfig: const {'publicite': 'off'});
    await tester.pumpWidget(host(config));
    await tester.pump();
    expect(tester.getSize(find.byType(AdBanner)), Size.zero);
  });

  test('sans identifiant fourni, ce sont les blocs de test de Google', () {
    expect(AdsConfig.isTest, isTrue);
  });
}
