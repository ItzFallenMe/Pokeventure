import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/battle/battle_screen.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/party/party_screen.dart';
import '../features/social/social_screen.dart';
import '../state/theme_provider.dart';
import '../ui/tokens/layout.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    HomeScreen(onOpenParty: () => _select(1)),
    const PartyScreen(),
    BattleScreen(onOpenSocial: () => _select(3)),
    const SocialScreen(),
    const MoreScreen(),
  ];

  void _select(int index) {
    if (index == _index) return;
    ref.read(soundServiceProvider).tap();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppMotion.base,
        switchInCurve: AppMotion.emphasizedDecelerate,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.catching_pokemon_outlined),
              selectedIcon: Icon(Icons.catching_pokemon_rounded),
              label: 'Party',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_mma_outlined),
              selectedIcon: Icon(Icons.sports_mma_rounded),
              label: 'Battle',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Social',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
