import 'package:flutter/material.dart';

import '../../data/models/pokemon.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/pokemon_orb.dart';
import '../../ui/widgets/type_chip.dart';

Future<void> showPokemonDetailSheet(
  BuildContext context,
  Pokemon pokemon, {
  VoidCallback? onSwap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.97,
        builder: (context, controller) {
          return _PokemonDetail(
            pokemon: pokemon,
            scrollController: controller,
            onSwap: onSwap,
          );
        },
      );
    },
  );
}

class _PokemonDetail extends StatelessWidget {
  const _PokemonDetail({
    required this.pokemon,
    required this.scrollController,
    this.onSwap,
  });

  final Pokemon pokemon;
  final ScrollController scrollController;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final type = pokemon.types.first;
    final base = TypePalette.of(type);

    final stats = <(String, int)>[
      ('HP', pokemon.stats.hp),
      ('Atk', pokemon.stats.attack),
      ('Def', pokemon.stats.defense),
      ('SpA', pokemon.stats.spAttack),
      ('SpD', pokemon.stats.spDefense),
      ('Spe', pokemon.stats.speed),
    ];
    final ivs = <(String, int)>[
      ('HP', pokemon.ivs.hp),
      ('Atk', pokemon.ivs.attack),
      ('Def', pokemon.ivs.defense),
      ('SpA', pokemon.ivs.spAttack),
      ('SpD', pokemon.ivs.spDefense),
      ('Spe', pokemon.ivs.speed),
    ];

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
      ),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(Colors.black.withValues(alpha: 0.12), base),
                Color.alphaBlend(Colors.black.withValues(alpha: 0.42), base),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        PillBadge(
                          label: pokemon.dexLabel,
                          color: Colors.white,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    PokemonOrb(pokemon: pokemon, size: 112),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pokemon.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (pokemon.shiny) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: AppTheme.shiny,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lv. ${pokemon.level} · ${pokemon.nature}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final type in pokemon.types)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: TypeChip(type: type),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MetaChip(
                    icon: Icons.psychology_alt_rounded,
                    label: 'Nature',
                    value: pokemon.nature,
                  ),
                  _MetaChip(
                    icon: Icons.bolt_rounded,
                    label: 'Ability',
                    value: pokemon.ability,
                  ),
                  _MetaChip(
                    icon: Icons.inventory_2_rounded,
                    label: 'Held item',
                    value: pokemon.heldItem ?? 'None',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Stats',
                trailingLabel: 'Total ${pokemon.stats.total}',
              ),
              for (final stat in stats)
                StatBar(
                  label: stat.$1,
                  value: stat.$2,
                  max: 255,
                  valueLabel: '${stat.$2}',
                  color: base,
                ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'IVs',
                trailingLabel: '${pokemon.ivs.total} / 186',
              ),
              for (final iv in ivs)
                StatBar(
                  label: iv.$1,
                  value: iv.$2,
                  max: 31,
                  valueLabel: '${iv.$2}',
                  color: scheme.tertiary,
                ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Moves'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final move in pokemon.moves)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text(
                        move,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
              if (onSwap != null) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onSwap,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Swap with a PC Pokémon'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
