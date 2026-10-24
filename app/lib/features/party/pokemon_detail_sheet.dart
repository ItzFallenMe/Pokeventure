import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dex_repository.dart';
import '../../data/game/stats.dart';
import '../../data/models/move_entry.dart';
import '../../data/models/pokemon.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/motion/motion.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/hp_bar.dart';
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
        initialChildSize: 0.9,
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

class _PokemonDetail extends ConsumerWidget {
  const _PokemonDetail({
    required this.pokemon,
    required this.scrollController,
    this.onSwap,
  });

  final Pokemon pokemon;
  final ScrollController scrollController;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trainer = ref.watch(trainerProvider);
    final current = trainer.pokemonById(pokemon.id) ?? pokemon;
    final catalog = ref.watch(dexCatalogProvider);
    final entry = catalog.speciesAt(current.dexNumber);
    final inParty = trainer.party.any((p) => p.id == current.id);
    final type = current.types.first;
    final base = TypePalette.of(type);

    final stats = <(String, int, int)>[
      ('HP', current.stats.hp, 255),
      ('Atk', current.stats.attack, 255),
      ('Def', current.stats.defense, 255),
      ('SpA', current.stats.spAttack, 255),
      ('SpD', current.stats.spDefense, 255),
      ('Spe', current.stats.speed, 255),
    ];
    final ivs = <(String, int)>[
      ('HP', current.ivs.hp),
      ('Atk', current.ivs.attack),
      ('Def', current.ivs.defense),
      ('SpA', current.ivs.spAttack),
      ('SpD', current.ivs.spDefense),
      ('Spe', current.ivs.speed),
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
                Color.alphaBlend(Colors.black.withValues(alpha: 0.46), base),
                const Color(0xFF17122A),
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
                        PillBadge(label: current.dexLabel, color: Colors.white),
                        if (current.shiny) ...[
                          const SizedBox(width: 6),
                          const PillBadge(
                            label: 'SHINY',
                            color: AppTheme.shiny,
                            icon: Icons.auto_awesome_rounded,
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          tooltip: current.isFavorite
                              ? 'Unfavourite'
                              : 'Favourite',
                          onPressed: () {
                            ref
                                .read(trainerProvider.notifier)
                                .toggleFavorite(current.id);
                            ref.read(soundServiceProvider).tap();
                          },
                          icon: Icon(
                            current.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: current.isFavorite
                                ? AppTheme.rose
                                : Colors.white,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    GlowPulse(
                      color: base,
                      min: 0.3,
                      max: 0.55,
                      child: PokemonOrb(pokemon: current, size: 124),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            current.displayName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Nickname',
                          onPressed: () => _nickname(context, ref, current),
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Lv. ${current.level} · ${current.nature}'
                      '${natureHint(current.nature) == null ? '' : ' · ${natureHint(current.nature)}'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: xpProgress(current.level, current.xp),
                              ),
                              duration: AppMotion.slow,
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    minHeight: 5,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.2,
                                    ),
                                    valueColor: const AlwaysStoppedAnimation(
                                      AppTheme.gold,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            current.level >= 100
                                ? 'Max level'
                                : '${current.xp} / ${totalXpForLevel(current.level + 1) - totalXpForLevel(current.level)} XP to Lv. ${current.level + 1}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final type in current.types) TypeChip(type: type),
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
                    value: current.nature,
                  ),
                  _MetaChip(
                    icon: Icons.bolt_rounded,
                    label: 'Ability',
                    value: current.ability,
                  ),
                  _MetaChip(
                    icon: Icons.inventory_2_rounded,
                    label: 'Held item',
                    value: current.heldItem ?? 'None',
                  ),
                  _MetaChip(
                    icon: Icons.public_rounded,
                    label: 'Met',
                    value: current.metZone ?? 'Unknown',
                  ),
                  _MetaChip(
                    icon: Icons.catching_pokemon_rounded,
                    label: 'Ball',
                    value: current.ball,
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
                          'HP ${current.currentHp} / ${current.maxHp}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        HpBar(value: current.hpFraction, height: 7),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Stats',
                trailingLabel: 'Total ${current.stats.total}',
              ),
              for (final stat in stats)
                StatBar(
                  label: stat.$1,
                  value: stat.$2,
                  max: stat.$3,
                  valueLabel: '${stat.$2}',
                  color: base,
                ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'IVs',
                trailingLabel: '${current.ivs.total} / 186',
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
              SectionHeader(title: 'Moves', trailingLabel: entry?.genus ?? ''),
              for (final moveName in current.moves)
                _MoveRow(
                  name: moveName,
                  move: catalog.move(moveName),
                  fallbackColor: base,
                ),
              if (entry != null && entry.evolutions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Evolution'),
                for (final evolution in entry.evolutions)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.surfaceContainerHigh,
                        child: Text(
                          '#${evolution.to}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        evolution.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(evolution.condition),
                    ),
                  ),
              ],
              if (entry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  entry.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (onSwap != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onSwap,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Swap with a PC Pokémon'),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        if (inParty) {
                          final moved = ref
                              .read(trainerProvider.notifier)
                              .moveToBox(current.id);
                          if (!moved) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You need at least one Pokémon in the party.',
                                ),
                              ),
                            );
                            return;
                          }
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('${current.name} moved to the PC.'),
                            ),
                          );
                        } else {
                          final moved = ref
                              .read(trainerProvider.notifier)
                              .moveToParty(current.id);
                          if (!moved) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Party is full — make room first.',
                                ),
                              ),
                            );
                            return;
                          }
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '${current.name} joined the party.',
                              ),
                            ),
                          );
                        }
                        ref.read(soundServiceProvider).tap();
                      },
                      icon: Icon(
                        inParty
                            ? Icons.inventory_2_rounded
                            : Icons.add_circle_outline_rounded,
                      ),
                      label: Text(inParty ? 'Move to PC' : 'Add to party'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.outlined(
                    tooltip: 'Release',
                    onPressed: () => _release(context, ref, current, inParty),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: scheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _nickname(
    BuildContext context,
    WidgetRef ref,
    Pokemon pokemon,
  ) async {
    final controller = TextEditingController(text: pokemon.nickname ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nickname'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 12,
            decoration: InputDecoration(hintText: pokemon.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null) return;
    ref.read(trainerProvider.notifier).setNickname(pokemon.id, name);
  }

  Future<void> _release(
    BuildContext context,
    WidgetRef ref,
    Pokemon pokemon,
    bool inParty,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Release ${pokemon.displayName}?'),
          content: Text(
            inParty
                ? 'They leave your party and are gone forever. You get coins.'
                : 'They leave the PC and are gone forever. You get coins.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Release'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final coins = ref.read(trainerProvider.notifier).release(pokemon.id);
    if (!context.mounted) return;
    if (coins == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not release that Pokémon.')),
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${pokemon.name} released · +$coins coins')),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.name,
    required this.move,
    required this.fallbackColor,
  });

  final String name;
  final MoveEntry? move;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = move == null ? fallbackColor : TypePalette.of(move!.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.22),
            ),
            child: Icon(
              move?.isStatus ?? false
                  ? Icons.auto_fix_high_rounded
                  : Icons.flash_on_rounded,
              size: 16,
              color: tint,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleSmall),
                if (move != null)
                  Text(
                    '${move!.type.label} · ${move!.category}'
                    '${move!.power > 0 ? ' · ${move!.power} power' : ''}'
                    '${move!.accuracy != null ? ' · ${move!.accuracy}%' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'PP ${move?.pp ?? '—'}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
