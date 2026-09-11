import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// Affichage en heure locale du pays (Dakar pour le Sénégal), stockage en UTC.
class LocalTime {
  LocalTime(this.fuseau);
  final String fuseau;

  tz.Location get _location {
    try {
      return tz.getLocation(fuseau);
    } catch (_) {
      return tz.UTC;
    }
  }

  tz.TZDateTime local(DateTime utc) => tz.TZDateTime.from(utc.toUtc(), _location);

  /// « lundi 7 septembre, 08:00 »
  String dateTime(DateTime utc, String locale) =>
      DateFormat('EEEE d MMMM, HH:mm', locale).format(local(utc));

  /// « 7 septembre 2026 »
  String date(DateTime utc, String locale) =>
      DateFormat('d MMMM yyyy', locale).format(local(utc));

  /// Pour une date civile (sans heure) : « 7 septembre 2026 »
  static String civil(DateTime date, String locale) =>
      DateFormat('d MMMM yyyy', locale).format(date);

  static String civilShort(DateTime date, String locale) =>
      DateFormat('d MMM yyyy', locale).format(date);
}

/// Une date civile (« 2026-09-07 ») est lue en UTC pour que les comparaisons
/// au jour près ne dépendent pas du fuseau du téléphone.
DateTime? parseDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  if (s.length == 10) return DateTime.tryParse('${s}T00:00:00Z');
  return DateTime.tryParse(s);
}

/// Date civile ISO « 2026-09-07 » depuis un DateTime.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Date civile sans composante horaire, en UTC pour éviter les surprises.
DateTime dayOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
