import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/locale_fallbacks.dart';
import '../../app/theme.dart';
import '../../l10n/generated/app_localizations.dart';

export 'band_scaffold.dart';
export 'soft_card.dart';

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
    final t = context.tokens;
    final accent = color ?? t.primary;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(size / 4)),
      alignment: Alignment.center,
      child: Text(
        initials(nom),
        style: TextStyle(fontFamily: PalabreType.display, fontSize: size * 0.34, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.5),
      ),
    );
    if (photoUrl == null || photoUrl!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
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
    final t = context.tokens;
    final text = label ?? context.l10n.source;
    if (url == null || url!.isEmpty) {
      return Text(text, style: TextStyle(color: t.muted, fontSize: dense ? 12 : 13, fontWeight: FontWeight.w600));
    }
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link, size: dense ? 14 : 16, color: t.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.primary, fontSize: dense ? 12 : 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline, decorationColor: t.primary.withValues(alpha: 0.5))),
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
    final t = context.tokens;
    final c = color ?? t.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color == null ? t.primarySoft : c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color == null ? t.ink : c, fontSize: 13, height: 1.35, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// Titre de section hors carte.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10, left: 4, right: 4),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: PalabreType.eyebrow(t.muted))),
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

/// Pastille de couleur d'encodage (bloc, groupe).
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 8});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// Barre horizontale pour un pourcentage.
class PercentBar extends StatelessWidget {
  const PercentBar({super.key, required this.fraction, this.color, this.height = 6, this.track});
  final double fraction;
  final Color? color;
  final Color? track;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: fraction.clamp(0, 1),
          backgroundColor: track ?? t.line,
          color: color ?? t.primary,
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
