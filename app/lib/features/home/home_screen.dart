import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_pokemon.dart';
import '../../state/party_provider.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/pokemon_orb.dart';
import '../../ui/widgets/type_chip.dart';
import '../dex/pokedex_screen.dart';
import '../explore/catch_sheet.dart';
import '../party/pokemon_detail_sheet.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onOpenParty});

  final VoidCallback onOpenParty;

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature ships in the next milestone.')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(partyProvider);
    final buddy = state.party.first;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME BACK',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.4,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Trainer',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.displaySmall,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const PillBadge(label: 'Lv. 24'),
                        ],
                      ),
                    ],
                  ),
                ),
                const PillBadge(
                  label: '5 days',
                  icon: Icons.local_fire_department_rounded,
                  color: AppTheme.gold,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredEntrance(
            index: 1,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                const CurrencyChip(
                  icon: Icons.monetization_on_rounded,
                  value: '12,480',
                  color: AppTheme.gold,
                ),
                const CurrencyChip(
                  icon: Icons.diamond_rounded,
                  value: '240',
                  color: AppTheme.teal,
                ),
                CurrencyChip(
                  icon: Icons.catching_pokemon_rounded,
                  value: '${state.caught} caught',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 2,
            child: _SpawnCard(
              onCatch: () => showCatchSheet(context, featuredSpawn),
              onInspect: () => showPokemonDetailSheet(context, featuredSpawn),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 3,
            child: Row(
              children: [
                _QuickAction(
                  icon: Icons.explore_rounded,
                  label: 'Explore',
                  onTap: () => _comingSoon(context, 'Zone exploration'),
                ),
                _QuickAction(
                  icon: Icons.inventory_2_rounded,
                  label: 'PC Box',
                  onTap: onOpenParty,
                ),
                _QuickAction(
                  icon: Icons.storefront_rounded,
                  label: 'Shop',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ShopScreen(),
                    ),
                  ),
                ),
                _QuickAction(
                  icon: Icons.menu_book_rounded,
                  label: 'Dex',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PokedexScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 4,
            child: const SectionHeader(
              title: "Today's quests",
              trailingLabel: '2 of 3',
            ),
          ),
          StaggeredEntrance(
            index: 5,
            child: _QuestCard(
              icon: Icons.catching_pokemon_rounded,
              title: 'Catch 5 Pokémon',
              progressLabel: '2 / 5',
              value: 0.4,
              reward: 120,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StaggeredEntrance(
            index: 6,
            child: _QuestCard(
              icon: Icons.sports_mma_rounded,
              title: 'Win 3 ranked battles',
              progressLabel: '0 / 3',
              value: 0.0,
              reward: 250,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StaggeredEntrance(
            index: 7,
            child: _QuestCard(
              icon: Icons.directions_walk_rounded,
              title: 'Walk 2 km with your buddy',
              progressLabel: '1.2 / 2 km',
              value: 0.6,
              reward: 80,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 8,
            child: const SectionHeader(title: 'Buddy'),
          ),
          StaggeredEntrance(
            index: 9,
            child: Card(
              child: InkWell(
                onTap: () => showPokemonDetailSheet(context, buddy),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      PokemonOrb(pokemon: buddy, size: 48, active: true),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${buddy.name} · friendship',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 2,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (var i = 0; i < 5; i++)
                                  Icon(
                                    i < 3
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 13,
                                    color: i < 3
                                        ? AppTheme.gold
                                        : scheme.onSurfaceVariant,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  '1.2 / 2 km today',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpawnCard extends StatelessWidget {
  const _SpawnCard({required this.onCatch, required this.onInspect});

  final VoidCallback onCatch;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final white = Colors.white;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.alphaBlend(
              scheme.tertiary.withValues(alpha: 0.7),
              scheme.primary,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const PillBadge(label: 'ROUTE 1', color: Colors.white),
                    const SizedBox(width: 6),
                    const PillBadge(
                      label: 'SUNNY',
                      icon: Icons.wb_sunny_rounded,
                      color: Colors.white,
                    ),
                    const Spacer(),
                    if (featuredSpawn.shiny)
                      const PillBadge(
                        label: 'SHINY',
                        icon: Icons.auto_awesome_rounded,
                        color: AppTheme.shiny,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A wild',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: white.withValues(alpha: 0.78),
                            ),
                          ),
                          Text(
                            featuredSpawn.name,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: white,
                              fontSize: 38,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final type in featuredSpawn.types)
                                TypeChip(type: type, dense: true),
                              Text(
                                'Lv. ${featuredSpawn.level}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: white.withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 13,
                                color: white.withValues(alpha: 0.75),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Flees in 1:42',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PokemonOrb(
                      pokemon: featuredSpawn,
                      size: 104,
                      active: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onCatch,
                        style: FilledButton.styleFrom(
                          backgroundColor: white,
                          foregroundColor: scheme.primary,
                        ),
                        icon: const Icon(Icons.catching_pokemon_rounded),
                        label: const Text('Catch'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      onPressed: onInspect,
                      tooltip: 'Inspect',
                      icon: const Icon(Icons.visibility_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: white.withValues(alpha: 0.16),
                        foregroundColor: white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Card(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.icon,
    required this.title,
    required this.progressLabel,
    required this.value,
    required this.reward,
  });

  final IconData icon;
  final String title;
  final String progressLabel;
  final double value;
  final int reward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 19,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        progressLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 12,
                        color: AppTheme.gold,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '+$reward',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
