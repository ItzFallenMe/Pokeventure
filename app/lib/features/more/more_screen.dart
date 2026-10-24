import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/credits.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/motion/motion.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/avatars.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/common.dart';
import '../bag/bag_screen.dart';
import '../dex/pokedex_screen.dart';
import '../explore/explore_screen.dart';
import '../shop/shop_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(AppPageRoute(builder: (_) => screen));
  }

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature is on the roadmap after the core loop.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trainer = ref.watch(trainerProvider);
    final settings = ref.watch(settingsProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          StaggeredEntrance(
            index: 0,
            child: Row(
              children: [
                Text('More', style: theme.textTheme.displaySmall),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'Settings',
                  onPressed: () => _push(context, const SettingsScreen()),
                  icon: const Icon(Icons.settings_rounded, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 1,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                gradient: AppTheme.heroGradient(theme.brightness),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.28),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    child: Icon(
                      trainerAvatarIcon(settings.avatar),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trainer.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${settings.title} · Level ${trainer.level} · '
                          '${trainer.caughtCount} caught',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: trainer.levelProgress),
                            duration: AppMotion.slow,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                                  value: value,
                                  minHeight: 5,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.22,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppTheme.gold,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PillBadge(
                    label: '${trainer.streak}d streak',
                    icon: Icons.local_fire_department_rounded,
                    color: AppTheme.gold,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 2,
            child: _MoreGroup(
              title: 'Play',
              tiles: [
                _MoreTile(
                  icon: Icons.travel_explore_rounded,
                  title: 'Explore',
                  subtitle: 'Zones, live spawns and rare encounters',
                  onTap: () => _push(context, const ExploreScreen()),
                ),
                _MoreTile(
                  icon: Icons.storefront_rounded,
                  title: 'Shop',
                  subtitle: 'Balls, potions, berries and incense',
                  onTap: () => _push(context, const ShopScreen()),
                ),
              ],
            ),
          ),
          StaggeredEntrance(
            index: 3,
            child: _MoreGroup(
              title: 'Collection',
              tiles: [
                _MoreTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Pokédex',
                  subtitle: '${trainer.caughtCount} of 1,025 registered',
                  onTap: () => _push(context, const PokedexScreen()),
                ),
                _MoreTile(
                  icon: Icons.backpack_rounded,
                  title: 'Bag',
                  subtitle: '${trainer.itemCount} items across 6 categories',
                  onTap: () => _push(context, const BagScreen()),
                ),
              ],
            ),
          ),
          StaggeredEntrance(
            index: 4,
            child: _MoreGroup(
              title: 'Roadmap',
              tiles: [
                _MoreTile(
                  icon: Icons.handyman_rounded,
                  title: 'Crafting',
                  subtitle: 'Apricorns to balls, berries to potions',
                  badge: 'Planned',
                  onTap: () => _soon(context, 'Crafting'),
                ),
                _MoreTile(
                  icon: Icons.storefront_rounded,
                  title: 'Market & trades',
                  subtitle: 'List, bid, wonder trade and GTS',
                  badge: 'Planned',
                  onTap: () => _soon(context, 'The market'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 5,
            child: Card(
              child: InkWell(
                onTap: () async {
                  ref.read(soundServiceProvider).tap();
                  await Credits.openCreator();
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppTheme.heroGradient(theme.brightness),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'IF',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created by ItzFallenMe',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              'github.com/ItzFallenMe',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredEntrance(
            index: 6,
            child: Text(
              'Pokéventure 1.1.0 · fan project. Pokémon is a trademark of '
              'Nintendo, Creators, Game Freak and The Pokémon Company.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreGroup extends StatelessWidget {
  const _MoreGroup({required this.title, required this.tiles});

  final String title;
  final List<_MoreTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  tiles[i],
                  if (i != tiles.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 19, color: scheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: badge != null
          ? PillBadge(label: badge!, color: scheme.onSurfaceVariant)
          : Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
    );
  }
}
