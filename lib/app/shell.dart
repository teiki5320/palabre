import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/widgets.dart';
import 'theme.dart';

/// Quatre onglets, dans cet ordre. Le sondage est le centre de l'app.
/// Barre du bas sur téléphone, rail latéral sur écran large.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final items = [
      (Icons.forum_outlined, Icons.forum, l10n.tabQuestion),
      (Icons.checklist_outlined, Icons.checklist, l10n.tabQuiz),
      (Icons.account_balance_outlined, Icons.account_balance, l10n.tabGovernment),
      (Icons.groups_outlined, Icons.groups, l10n.tabAssembly),
    ];
    void go(int i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);

    if (BandScaffold.isWide(context)) {
      return Scaffold(
        backgroundColor: t.background,
        body: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: t.card, boxShadow: [BoxShadow(offset: const Offset(4, 0), blurRadius: 16, color: Colors.black.withValues(alpha: 0.06))]),
              child: SafeArea(
                right: false,
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: go,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 88,
                  groupAlignment: -0.85,
                  indicatorColor: t.primarySoft,
                  indicatorShape: const StadiumBorder(),
                  selectedIconTheme: IconThemeData(color: t.primary),
                  unselectedIconTheme: IconThemeData(color: t.muted),
                  selectedLabelTextStyle: TextStyle(fontFamily: PalabreType.body, fontSize: 11.5, fontWeight: FontWeight.w700, color: t.primary),
                  unselectedLabelTextStyle: TextStyle(fontFamily: PalabreType.body, fontSize: 11.5, fontWeight: FontWeight.w700, color: t.muted),
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 18),
                    child: Text('Palabre', style: PalabreType.wordmark(t.primary).copyWith(fontSize: 14)),
                  ),
                  destinations: [
                    for (final (icon, selected, label) in items)
                      NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
                  ],
                ),
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

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
