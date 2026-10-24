import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pokemon.dart';
import '../../state/party_provider.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/pokemon_orb.dart';
import '../../ui/widgets/pokemon_row.dart';
import '../../ui/widgets/type_chip.dart';

Future<void> showPcSwapSheet(BuildContext context, int partyIndex) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PcSwapSheet(partyIndex: partyIndex),
  );
}

Future<void> showPcBoxSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PcBoxSheet(),
  );
}

class PcSwapSheet extends ConsumerWidget {
  const PcSwapSheet({super.key, required this.partyIndex});

  final int partyIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(partyProvider);
    final outgoing = state.party[partyIndex];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Swap with the PC', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${outgoing.name} goes to the box and the party stays at six.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.box.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final candidate = state.box[index];
                  return PokemonRow(
                    pokemon: candidate,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      ref
                          .read(partyProvider.notifier)
                          .swapWithBox(partyIndex, candidate.id);
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '${candidate.name} joined the party · '
                            '${outgoing.name} stored in the PC.',
                          ),
                        ),
                      );
                    },
                    trailing: const Icon(Icons.swap_horiz_rounded),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PcBoxSheet extends ConsumerWidget {
  const PcBoxSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(partyProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'PC Boxes',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                Text(
                  '${state.box.length} stored',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a Pokémon to bring it into the party. Someone has to go.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.42,
                ),
                itemCount: state.box.length,
                itemBuilder: (context, index) {
                  final pokemon = state.box[index];
                  return _BoxCard(
                    pokemon: pokemon,
                    onTap: () => _promptPartySlot(context, ref, pokemon),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptPartySlot(
    BuildContext context,
    WidgetRef ref,
    Pokemon incoming,
  ) async {
    final party = ref.read(partyProvider).party;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final slot = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Who goes to the PC?',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              for (var i = 0; i < party.length; i++)
                ListTile(
                  leading: PokemonOrb(pokemon: party[i], size: 40),
                  title: Text(party[i].name),
                  subtitle: Text('Lv. ${party[i].level}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(sheetContext).pop(i),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );

    if (slot == null || !context.mounted) return;

    final outgoingName = party[slot].name;
    ref.read(partyProvider.notifier).swapWithBox(slot, incoming.id);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${incoming.name} joined the party · '
          '$outgoingName stored in the PC.',
        ),
      ),
    );
  }
}

class _BoxCard extends StatelessWidget {
  const _BoxCard({required this.pokemon, required this.onTap});

  final Pokemon pokemon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Row(
            children: [
              PokemonOrb(pokemon: pokemon, size: 42),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pokemon.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (pokemon.shiny)
                          const Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: AppTheme.shiny,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      'Lv. ${pokemon.level} · ${pokemon.dexLabel}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 3,
                      children: [
                        for (final type in pokemon.types)
                          TypeChip(type: type, dense: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
