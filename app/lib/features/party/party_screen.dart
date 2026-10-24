import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/party_provider.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/pokemon_row.dart';
import 'pc_sheets.dart';
import 'pokemon_detail_sheet.dart';

class PartyScreen extends ConsumerWidget {
  const PartyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(partyProvider);

    return SafeArea(
      bottom: false,
      child: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        buildDefaultDragHandles: false,
        itemCount: state.party.length,
        onReorderItem: (oldIndex, newIndex) {
          ref.read(partyProvider.notifier).reorder(oldIndex, newIndex);
        },
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your party', style: theme.textTheme.displaySmall),
                      const SizedBox(height: 2),
                      Text(
                        'These six are the only Pokémon that can battle.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PillBadge(
                      label: '${state.party.length} / $kPartyLimit',
                      color: state.hasSpace ? scheme.primary : scheme.tertiary,
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () {
                        ref.read(partyProvider.notifier).healAll();
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Party restored to full health.'),
                            ),
                          );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.healing_rounded, size: 16),
                      label: const Text('Heal all'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const InfoBanner(
              icon: Icons.info_outline_rounded,
              text:
                  'Battles use this party only — every other Pokémon waits in '
                  'the PC. Drag a row to change the lead slot.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
        footer: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Card(
            child: InkWell(
              onTap: () => showPcBoxSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        size: 20,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PC Boxes',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${state.box.length} Pokémon in storage',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
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
        itemBuilder: (context, index) {
          final pokemon = state.party[index];

          return Padding(
            key: ValueKey(pokemon.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: StaggeredEntrance(
              index: index,
              child: PokemonRow(
                pokemon: pokemon,
                onTap: () => showPokemonDetailSheet(
                  context,
                  pokemon,
                  onSwap: () {
                    Navigator.of(context).pop();
                    showPcSwapSheet(context, index);
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Swap with PC',
                      onPressed: () => showPcSwapSheet(context, index),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.drag_handle_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
