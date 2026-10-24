import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dex_repository.dart';
import '../../data/models/dex_entry.dart';
import '../../data/models/pokemon_type.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/pokemon_sprite.dart';
import '../../ui/widgets/type_chip.dart';
import 'dex_entry_sheet.dart';

enum _OwnedFilter { all, caught, missing }

class PokedexScreen extends ConsumerStatefulWidget {
  const PokedexScreen({super.key});

  @override
  ConsumerState<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends ConsumerState<PokedexScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  PokemonType? _type;
  _OwnedFilter _owned = _OwnedFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _type = null;
      _owned = _OwnedFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dex = ref.watch(dexProvider);
    final owned = ref.watch(ownedDexProvider);
    final seen = ref.watch(seenDexProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex'), scrolledUnderElevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name or number',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SegmentedButton<_OwnedFilter>(
              segments: const [
                ButtonSegment(value: _OwnedFilter.all, label: Text('All')),
                ButtonSegment(
                  value: _OwnedFilter.caught,
                  label: Text('Caught'),
                ),
                ButtonSegment(
                  value: _OwnedFilter.missing,
                  label: Text('Missing'),
                ),
              ],
              selected: {_owned},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _owned = selection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('All types'),
                    selected: _type == null,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _type = null),
                  ),
                ),
                for (final type in PokemonType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: CircleAvatar(
                        radius: 6,
                        backgroundColor: TypePalette.of(type),
                      ),
                      label: Text(type.label),
                      selected: _type == type,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _type = _type == type ? null : type);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: owned.length / 1025),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(owned.length / 1025 * 100).toStringAsFixed(1)}% complete',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dex.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Could not load the dex.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
              data: (entries) {
                final filtered = entries
                    .where((entry) {
                      if (!entry.matches(_query)) return false;
                      if (_type != null && !entry.types.contains(_type)) {
                        return false;
                      }
                      final isOwned = owned.contains(entry.number);
                      return switch (_owned) {
                        _OwnedFilter.all => true,
                        _OwnedFilter.caught => isOwned,
                        _OwnedFilter.missing => !isOwned,
                      };
                    })
                    .toList(growable: false);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No species match',
                          style: theme.textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
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
                          Text(
                            '${filtered.length} species',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${owned.length} caught',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.sm,
                              crossAxisSpacing: AppSpacing.sm,
                              childAspectRatio: 1.55,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          return _DexCard(
                            entry: entry,
                            owned: owned.contains(entry.number),
                            seen: seen.contains(entry.number),
                            onTap: () => showDexEntrySheet(
                              context,
                              entry,
                              owned: owned.contains(entry.number),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DexCard extends StatelessWidget {
  const _DexCard({
    required this.entry,
    required this.owned,
    required this.seen,
    required this.onTap,
  });

  final DexEntry entry;
  final bool owned;
  final bool seen;
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
              PokemonSprite(
                dexNumber: entry.number,
                fallbackTypes: entry.types,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          owned
                              ? Icons.check_circle_rounded
                              : seen
                              ? Icons.visibility_rounded
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: owned
                              ? AppTheme.teal
                              : seen
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ],
                    ),
                    Text(
                      '${entry.dexLabel} · Gen ${entry.generation}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: [
                        for (final type in entry.types)
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
