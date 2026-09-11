import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/locale_fallbacks.dart';
import '../../app/theme.dart';
import '../../l10n/generated/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  /// Locale pour `intl` (dates) : le wolof retombe sur le français.
  String get localeName => intlLocaleFor(Localizations.localeOf(this));
}

/// Photo, ou repli en initiales traité aussi soigneusement que le cas nominal :
/// ce sera fréquent.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.nom, this.photoUrl, this.size = 56, this.color});

  final String nom;
  final String? photoUrl;
  final double size;
  final Color? color;

  static String initials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size / 6),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials(nom),
        style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w600, color: accent, letterSpacing: 0.5),
      ),
    );
    if (photoUrl == null || photoUrl!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 6),
      child: Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
      ),
    );
  }
}

/// Chaque fait affiché renvoie à sa source.
class SourceLink extends StatelessWidget {
  const SourceLink({super.key, required this.url, this.label, this.dense = false});

  final String? url;
  final String? label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = label ?? context.l10n.source;
    if (url == null || url!.isEmpty) {
      return Text(text, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: dense ? 12 : 13));
    }
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link, size: dense ? 14 : 16, color: scheme.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.primary, fontSize: dense ? 12 : 13, decoration: TextDecoration.underline, decorationColor: scheme.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'information : module suspendu, données absentes, hors-ligne.
/// Une absence assumée vaut mieux qu'une donnée inventée.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.text, this.icon = Icons.info_outline, this.color});

  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: c.withValues(alpha: 0.5), width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: c, fontSize: 13, height: 1.35))),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text.toUpperCase(),
                style: TextStyle(fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

class Hairline extends StatelessWidget {
  const Hairline({super.key});
  @override
  Widget build(BuildContext context) => const Divider(height: 0.5);
}

/// Pastille de couleur d'encodage (bloc, groupe).
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 8});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// Barre horizontale plate pour un pourcentage.
class PercentBar extends StatelessWidget {
  const PercentBar({super.key, required this.fraction, this.color, this.height = 6});
  final double fraction;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: fraction.clamp(0, 1),
          backgroundColor: scheme.outlineVariant.withValues(alpha: 0.4),
          color: color ?? scheme.primary,
        ),
      ),
    );
  }
}

String blocLabel(BuildContext context, String? bloc) => switch (bloc) {
      'regalien' => context.l10n.blocRegalien,
      'economie' => context.l10n.blocEconomie,
      'social' => context.l10n.blocSocial,
      'infrastructure' => context.l10n.blocInfrastructure,
      _ => context.l10n.blocAutre,
    };

Color blocColor(String? bloc) => BlocColors.of(bloc);
