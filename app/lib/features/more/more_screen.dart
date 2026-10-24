import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/party_provider.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/common.dart';
import '../bag/bag_screen.dart';
import '../dex/pokedex_screen.dart';
import '../shop/shop_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature ships in the next milestone.')),
      );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(partyProvider);
    final itemCount =
        state.inventory.values.fold<int>(0, (sum, count) => sum + count);

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
            child: Text('More', style: theme.textTheme.displaySmall),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        'TR',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trainer', style: theme.textTheme.titleLarge),
                          Text(
                            'Level 24 · Season 1 · ${state.caught} caught',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PillBadge(
                      label: 'Great Ball',
                      icon: Icons.workspace_premium_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 2,
            child: _MoreGroup(
              title: 'Collection',
              tiles: [
                _MoreTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Pokédex',
                  subtitle: '${state.caught} of 1,025 registered',
                  onTap: () => _push(context, const PokedexScreen()),
                ),
                _MoreTile(
                  icon: Icons.backpack_rounded,
                  title: 'Bag',
                  subtitle: '$itemCount items across 6 categories',
                  onTap: () => _push(context, const BagScreen()),
                ),
                _MoreTile(
                  icon: Icons.handyman_rounded,
                  title: 'Crafting',
                  subtitle: 'Apricorns to balls, berries to potions',
                  badge: 'M5',
                  onTap: () => _soon(context, 'Crafting'),
                ),
                _MoreTile(
                  icon: Icons.eco_rounded,
                  title: 'Berry farm',
                  subtitle: 'Grow berries in your hideout',
                  badge: 'M5',
                  onTap: () => _soon(context, 'Farming'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 3,
            child: _MoreGroup(
              title: 'Economy',
              tiles: [
                _MoreTile(
                  icon: Icons.storefront_rounded,
                  title: 'Shop',
                  subtitle: 'Spend ${state.coins} coins on supplies',
                  onTap: () => _push(context, const ShopScreen()),
                ),
                _MoreTile(
                  icon: Icons.sell_rounded,
                  title: 'Market',
                  subtitle: 'Buy, sell and auction Pokémon',
                  badge: 'M4',
                  onTap: () => _soon(context, 'The market'),
                ),
                _MoreTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Wonder Trade',
                  subtitle: 'One free random swap per hour',
                  badge: 'M4',
                  onTap: () => _soon(context, 'Wonder Trade'),
                ),
                _MoreTile(
                  icon: Icons.confirmation_number_rounded,
                  title: 'Season pass',
                  subtitle: 'Free and premium tracks',
                  badge: 'M5',
                  onTap: () => _soon(context, 'The season pass'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 4,
            child: _MoreGroup(
              title: 'Account',
              tiles: [
                _MoreTile(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  subtitle: 'Theme, local save and about',
                  onTap: () => _push(context, const SettingsScreen()),
                ),
                _MoreTile(
                  icon: Icons.description_outlined,
                  title: 'Licenses',
                  subtitle: 'Open-source notices',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Pokéventure',
                    applicationVersion: '1.0.0 (dev)',
                  ),
                ),
              ],
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
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i != tiles.length - 1)
                  Divider(
                    height: 1,
                    indent: 60,
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
              ],
            ],
          ),
        ),
      ],
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
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Icon(icon, size: 19, color: scheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: badge == null
          ? Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
    );
  }
}
