import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/country/country_providers.dart';
import '../../core/net/cached_notifier.dart';
import '../../core/supabase/supabase_providers.dart';
import 'reference_models.dart';

class ReferenceNotifier extends CachedNotifier<ReferenceBundle> {
  ReferenceNotifier(this.countryCode);
  final String countryCode;

  @override
  String get cacheKey => 'reference:$countryCode';

  @override
  Future<ReferenceBundle> fetchRemote() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) throw const NotConfiguredException();
    final c = countryCode;
    final results = await Future.wait([
      client.from('person').select().eq('country_code', c).order('nom'),
      client.from('organization').select().eq('country_code', c).order('nom'),
      client.from('portfolio').select().eq('country_code', c).order('rang'),
      client.from('role').select().eq('country_code', c),
      client.from('government').select().eq('country_code', c).order('debut'),
      client.from('legislature').select().eq('country_code', c).order('numero'),
      client.from('constituency').select().eq('country_code', c).order('nom'),
      client.from('mandate').select('*, person!inner(country_code)').eq('person.country_code', c),
      client.from('affiliation').select('*, person!inner(country_code)').eq('person.country_code', c),
      client.from('career').select('*, person!inner(country_code)').eq('person.country_code', c),
    ]);
    final orgIds = results[1].map((o) => (o['id'] as num).toInt()).toList();
    final mandateIds = results[7].map((m) => (m['id'] as num).toInt()).toList();
    final relations = orgIds.isEmpty ? <Map<String, dynamic>>[] : await client.from('org_relation').select().inFilter('from_id', orgIds);
    final activities = mandateIds.isEmpty ? <Map<String, dynamic>>[] : await client.from('deputy_activity').select().inFilter('mandate_id', mandateIds);
    return ReferenceBundle(
      persons: results[0].map(Person.fromJson).toList(),
      organizations: results[1].map(Organization.fromJson).toList(),
      orgRelations: relations.map(OrgRelation.fromJson).toList(),
      portfolios: results[2].map(Portfolio.fromJson).toList(),
      roles: results[3].map(Role.fromJson).toList(),
      governments: results[4].map(Government.fromJson).toList(),
      legislatures: results[5].map(Legislature.fromJson).toList(),
      constituencies: results[6].map(Constituency.fromJson).toList(),
      mandates: results[7].map(Mandate.fromJson).toList(),
      affiliations: results[8].map(Affiliation.fromJson).toList(),
      careers: results[9].map(Career.fromJson).toList(),
      activities: activities.map(DeputyActivity.fromJson).toList(),
    );
  }

  @override
  ReferenceBundle decode(Map<String, dynamic> json) => ReferenceBundle.fromJson(json);

  @override
  Map<String, dynamic> encode(ReferenceBundle value) => value.toJson();
}

final referenceProvider = AsyncNotifierProvider.family<ReferenceNotifier, ReferenceBundle, String>(ReferenceNotifier.new);

final currentReferenceProvider = Provider<AsyncValue<ReferenceBundle>>((ref) {
  final code = ref.watch(selectedCountryProvider);
  return ref.watch(referenceProvider(code));
});

/// Date du curseur temporel de l'onglet gouvernement (jour civil, UTC).
class GovernmentDate extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  void set(DateTime d) => state = DateTime.utc(d.year, d.month, d.day);
}

final governmentDateProvider = NotifierProvider<GovernmentDate, DateTime>(GovernmentDate.new);
