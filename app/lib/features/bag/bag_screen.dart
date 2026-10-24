import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/item_catalog.dart';
import '../../data/models/pokemon.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/motion/motion.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/hp_bar.dart';
import '../../ui/widgets/pokemon_orb.dart';

class BagScreen extends ConsumerStatefulWidget {
  const BagScreen({super.key});

  @override
  ConsumerState<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends ConsumerState<BagScreen> {
  ItemCategory _category = ItemCategory.balls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(trainerProvider);
    final items = itemCatalog
        .where((item) => item.category == _category)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Bag')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                CurrencyChip(
                  icon: Icons.monetization_on_rounded,
                  value: '${state.coins}',
                  color: AppTheme.gold,
                ),
                const SizedBox(width: AppSpacing.sm),
                CurrencyChip(
                  icon: Icons.inventory_2_rounded,
                  value: '${state.itemCount} items',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                for (final category in ItemCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(category.label),
                      selected: _category == category,
                      showCheckmark: false,
                      onSelected: (_) {
                        ref.read(soundServiceProvider).tap();
                        setState(() => _category = category);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = items[index];
                final quantity = state.quantityOf(item.slug);
                final usable =
                    quantity > 0 &&
                    (item.category == ItemCategory.medicine ||
                        item.category == ItemCategory.berries);
                return PressScale(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: quantity == 0
                                  ? scheme.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    )
                                  : scheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: quantity == 0
                                        ? scheme.onSurfaceVariant
                                        : scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: quantity == 0
                                      ? scheme.surfaceContainerHighest
                                      : scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  quantity == 0 ? 'None' : '×$quantity',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: quantity == 0
                                        ? scheme.onSurfaceVariant
                                        : scheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              if (usable)
                                TextButton(
                                  onPressed: () => _useItem(context, ref, item),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 26),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  child: const Text('Use'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useItem(
    BuildContext context,
    WidgetRef ref,
    ItemDef item,
  ) async {
    final trainer = ref.read(trainerProvider);
    final candidates = <Pokemon>[...trainer.party, ...trainer.box];
    if (candidates.isEmpty) return;

    final chosen = await showModalBottomSheet<Pokemon>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
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
                  'Use ${item.name} on…',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final pokemon = candidates[index];
                    return ListTile(
                      leading: PokemonOrb(pokemon: pokemon, size: 40),
                      title: Text(pokemon.displayName),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: HpBar(
                                value: pokemon.hpFraction,
                                height: 4,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${pokemon.currentHp}/${pokemon.maxHp}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      trailing: pokemon.isFainted
                          ? const Icon(Icons.healing_rounded)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(pokemon),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (chosen == null || !context.mounted) return;
    final message = ref
        .read(trainerProvider.notifier)
        .useItem(item.slug, chosen.id);
    if (message == null) {
      ref.read(soundServiceProvider).error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} cannot be used on ${chosen.name}.'),
        ),
      );
      return;
    }
    ref.read(soundServiceProvider).purchase();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    setState(() {});
  }
}
