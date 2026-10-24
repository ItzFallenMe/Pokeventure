import 'package:flutter/material.dart';

import '../../data/models/dex_entry.dart';
import '../../ui/motion/motion.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/pokemon_sprite.dart';
import '../../ui/widgets/type_chip.dart';

Future<void> showDexEntrySheet(
  BuildContext context,
  DexEntry entry, {
  required bool owned,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, controller) {
          return _DexEntrySheet(
            entry: entry,
            owned: owned,
            scrollController: controller,
          );
        },
      );
    },
  );
}

class _DexEntrySheet extends StatelessWidget {
  const _DexEntrySheet({
    required this.entry,
    required this.owned,
    required this.scrollController,
  });

  final DexEntry entry;
  final bool owned;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = TypePalette.of(entry.types.first);

    final stats = <(String, int)>[
      ('HP', entry.baseStats.hp),
      ('Atk', entry.baseStats.attack),
      ('Def', entry.baseStats.defense),
      ('SpA', entry.baseStats.spAttack),
      ('SpD', entry.baseStats.spDefense),
      ('Spe', entry.baseStats.speed),
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
                Color.alphaBlend(Colors.black.withValues(alpha: 0.1), base),
                Color.alphaBlend(Colors.black.withValues(alpha: 0.45), base),
                const Color(0xFF17122A),
              ],
            ),
          ),
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
                  PillBadge(label: entry.dexLabel, color: Colors.white),
                  const Spacer(),
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
                min: 0.2,
                max: 0.4,
                child: PokemonSprite(
                  dexNumber: entry.number,
                  fallbackTypes: entry.types,
                  size: 154,
                  artwork: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                '${entry.genus} · Gen ${entry.generation}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final type in entry.types) TypeChip(type: type),
                  PillBadge(
                    label: owned ? 'Caught' : 'Not caught',
                    icon: owned
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: owned ? AppTheme.teal : Colors.white,
                  ),
                ],
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
              if (entry.description.isNotEmpty) ...[
                Text(
                  entry.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Row(
                children: [
                  _Fact(
                    icon: Icons.bolt_rounded,
                    label: 'Catch rate',
                    value: '${entry.catchRate}',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Fact(
                    icon: Icons.trending_up_rounded,
                    label: 'Base EXP',
                    value: '${entry.baseExp}',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Fact(
                    icon: Icons.scale_rounded,
                    label: 'Growth',
                    value: entry.growthRate,
                  ),
                ],
              ),
              if (entry.height != null || entry.weight != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (entry.height != null)
                      _Fact(
                        icon: Icons.height_rounded,
                        label: 'Height',
                        value: entry.height!,
                      ),
                    if (entry.height != null && entry.weight != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (entry.weight != null)
                      _Fact(
                        icon: Icons.fitness_center_rounded,
                        label: 'Weight',
                        value: entry.weight!,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Base stats',
                trailingLabel: 'Total ${entry.statTotal}',
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
              const SectionHeader(title: 'Abilities'),
              _AbilityRow(label: 'Normal', value: entry.normalAbility ?? '—'),
              const SizedBox(height: AppSpacing.sm),
              _AbilityRow(label: 'Hidden', value: entry.hiddenAbility ?? '—'),
              if (entry.evolutions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Evolution'),
                for (final evolution in entry.evolutions)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                      children: [
                        PokemonSprite(
                          dexNumber: evolution.to,
                          fallbackTypes: entry.types,
                          size: 36,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            evolution.name,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          evolution.condition,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (entry.moves.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Level-up moves',
                  trailingLabel: '${entry.moves.length} moves',
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final move in entry.moves.take(14))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          '${move.name} · ${move.level}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                if (entry.moves.length > 14)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${entry.moves.length - 14} more by level',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
              if (entry.evolvesFrom != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Evolves from ${entry.evolvesFrom}.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbilityRow extends StatelessWidget {
  const _AbilityRow({required this.label, required this.value});

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
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
