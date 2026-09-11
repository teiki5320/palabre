import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/widgets.dart';
import 'theme.dart';

/// Quatre onglets, dans cet ordre. Le sondage est le centre de l'app.
/// Barre du bas « affiche » : fond carte, bord supérieur 2 px, onglet actif
/// en couleur de section avec un trait orange qui glisse.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final items = [
      (Icons.forum_outlined, Icons.forum, l10n.tabQuestion, t.primary),
      (Icons.checklist_outlined, Icons.checklist, l10n.tabQuiz, t.quiz),
      (Icons.account_balance_outlined, Icons.account_balance, l10n.tabGovernment, t.government),
      (Icons.groups_outlined, Icons.groups, l10n.tabAssembly, t.assembly),
    ];
    final index = navigationShell.currentIndex;
    void go(int i) => navigationShell.goBranch(i, initialLocation: i == index);

    return Scaffold(
      backgroundColor: t.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: t.card, border: Border(top: BorderSide(color: t.border, width: 2))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < items.length; i++)
                  _Tab(
                    icon: items[i].$1,
                    filledIcon: items[i].$2,
                    label: items[i].$3,
                    color: items[i].$4,
                    active: i == index,
                    onTap: () => go(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.filledIcon, required this.label, required this.color, required this.active, required this.onTap});
  final IconData icon;
  final IconData filledIcon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = active ? color : t.muted;
    final motion = !reduceMotion(context);
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 84,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? filledIcon : icon, size: 24, color: c),
              const SizedBox(height: 3),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: PalabreType.body, fontSize: 11.5, fontWeight: active ? FontWeight.w800 : FontWeight.w700, color: c)),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: Duration(milliseconds: motion ? 200 : 0),
                curve: Curves.easeOutCubic,
                width: active ? 18 : 0,
                height: 3,
                decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
