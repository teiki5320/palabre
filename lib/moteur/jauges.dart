/// Les quatre jauges du mandat, toujours dans cet ordre.
enum Jauge { peuple, armee, caisses, presse }

/// Un état des quatre jauges. Immuable : appliquer des effets rend un
/// nouvel objet, ce qui rend le moteur facile à tester et à rejouer.
class Jauges {
  const Jauges({required this.peuple, required this.armee, required this.caisses, required this.presse});

  final int peuple;
  final int armee;
  final int caisses;
  final int presse;

  static const milieu = Jauges(peuple: 50, armee: 50, caisses: 50, presse: 50);

  int valeur(Jauge j) => switch (j) {
        Jauge.peuple => peuple,
        Jauge.armee => armee,
        Jauge.caisses => caisses,
        Jauge.presse => presse,
      };

  /// Additionne les effets et borne chaque jauge entre 0 et 100.
  Jauges applique(Map<Jauge, int> effets) {
    int v(Jauge j) => (valeur(j) + (effets[j] ?? 0)).clamp(0, 100);
    return Jauges(
      peuple: v(Jauge.peuple),
      armee: v(Jauge.armee),
      caisses: v(Jauge.caisses),
      presse: v(Jauge.presse),
    );
  }

  /// La première jauge arrivée à un bout, ou null si le mandat continue.
  Jauge? extreme() {
    for (final j in Jauge.values) {
      final v = valeur(j);
      if (v <= 0 || v >= 100) return j;
    }
    return null;
  }

  @override
  String toString() => 'Jauges(P$peuple A$armee C$caisses Pr$presse)';
}

/// Le nom affiché d'une jauge, jamais son chiffre — utilisé aussi bien
/// pendant la partie que dans la collection.
extension NomDeJauge on Jauge {
  String get nom => switch (this) {
        Jauge.peuple => 'Peuple',
        Jauge.armee => 'Armée',
        Jauge.caisses => 'Caisses',
        Jauge.presse => 'Presse',
      };
}
