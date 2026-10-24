import 'package:flutter/material.dart';

import '../../data/models/dex_entry.dart';
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
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                Color.alphaBlend(Colors.black.withValues(alpha: 0.12), base),
                Color.alphaBlend(Colors.black.withValues(alpha: 0.42), base),
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
              PokemonSprite(
                dexNumber: entry.number,
                fallbackTypes: entry.types,
                size: 130,
                artwork: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                entry.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Generation ${entry.generation}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final type in entry.types)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: TypeChip(type: type),
                    ),
                  const SizedBox(width: 6),
                  PillBadge(
                    label: owned ? 'In your collection' : 'Not caught',
                    icon: owned
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: owned ? scheme.tertiary : Colors.white,
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
              _AbilityRow(
                label: 'Normal',
                value: entry.normalAbility ?? '—',
              ),
              const SizedBox(height: AppSpacing.sm),
              _AbilityRow(
                label: 'Hidden',
                value: entry.hiddenAbility ?? '—',
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                owned
                    ? 'This species is already registered from a Pokémon in '
                        'your party or PC.'
                    : 'Catch one to register it. The dex fills in as your '
                        'collection grows.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
