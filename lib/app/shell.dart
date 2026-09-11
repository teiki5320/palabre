import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/widgets.dart';

/// Quatre onglets, dans cet ordre. Le sondage est le centre de l'app.
/// Barre du bas sur tous les écrans : sur iPad, c'est tout l'affichage qui grandit.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.forum_outlined, Icons.forum, l10n.tabQuestion),
      (Icons.checklist_outlined, Icons.checklist, l10n.tabQuiz),
      (Icons.account_balance_outlined, Icons.account_balance, l10n.tabGovernment),
      (Icons.groups_outlined, Icons.groups, l10n.tabAssembly),
    ];
    void go(int i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(boxShadow: [BoxShadow(offset: Offset(0, -4), blurRadius: 16, color: Color(0x14000000))]),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: go,
          destinations: [
            for (final (icon, selected, label) in items) NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
          ],
        ),
      ),
    );
  }
}
