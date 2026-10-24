import 'package:flutter/material.dart';

import '../../data/models/pokemon.dart';
import '../theme/app_theme.dart';
import '../tokens/layout.dart';
import 'hp_bar.dart';
import 'pokemon_orb.dart';
import 'type_chip.dart';

class PokemonRow extends StatelessWidget {
  const PokemonRow({
    super.key,
    required this.pokemon,
    this.onTap,
    this.trailing,
  });

  final Pokemon pokemon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              PokemonOrb(pokemon: pokemon, size: 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pokemon.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (pokemon.shiny)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: AppTheme.shiny,
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Lv. ${pokemon.level}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (final type in pokemon.types)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: TypeChip(type: type, dense: true),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: HpBar(value: pokemon.hpFraction, height: 5),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${pokemon.currentHp}/${pokemon.maxHp}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
