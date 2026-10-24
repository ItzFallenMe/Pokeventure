import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dex_repository.dart';
import '../../data/game/wild.dart';
import '../../data/models/dex_entry.dart';
import '../../data/models/zone.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/motion/motion.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/pokemon_sprite.dart';
import '../../ui/widgets/type_chip.dart';
import 'catch_sheet.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final Random _random = Random();
  final List<_Recent> _recent = [];
  Timer? _ticker;

  String? _zoneSlug;
  WildSpawn? _spawn;
  DateTime? _nextSpawnAt;
  String _status = 'Searching the tall grass…';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selectZone(ref.read(dexCatalogProvider).zones.first, quiet: true);
      _spawnNow();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Zone? get _zone {
    final catalog = ref.read(dexCatalogProvider);
    if (catalog.zones.isEmpty) return null;
    return catalog.zone(_zoneSlug ?? '') ?? catalog.zones.first;
  }

  void _selectZone(Zone zone, {bool quiet = false}) {
    if (!quiet) ref.read(soundServiceProvider).tap();
    setState(() {
      _zoneSlug = zone.slug;
      _spawn = null;
      _nextSpawnAt = null;
      _status = 'Searching ${zone.name}…';
    });
  }

  void _tick() {
    if (!mounted) return;
    final spawn = _spawn;
    if (spawn != null && spawn.isExpired()) {
      setState(() {
        _spawn = null;
        _status = 'It slipped away. Keep looking…';
        _nextSpawnAt = DateTime.now().add(const Duration(seconds: 18));
      });
      return;
    }
    if (spawn == null &&
        _nextSpawnAt != null &&
        DateTime.now().isAfter(_nextSpawnAt!)) {
      _spawnNow();
    }
    if (spawn != null) setState(() {}); // refresh the TTL label
  }

  void _spawnNow() {
    final zone = _zone;
    final catalog = ref.read(dexCatalogProvider);
    if (zone == null || !catalog.isLoaded) return;
    final spawn = rollWildSpawn(
      zone: zone,
      byNumber: catalog.byNumber,
      random: _random,
    );
    if (spawn == null) return;
    setState(() {
      _spawn = spawn;
      _nextSpawnAt = null;
      _status = 'Something moved nearby.';
    });
    final sound = ref.read(soundServiceProvider);
    sound.impact();
    sound.cry(spawn.pokemon.name.toLowerCase(), volume: 0.4);
  }

  Future<void> _catch(WildSpawn spawn) async {
    if (_busy) return;
    setState(() => _busy = true);
    final report = await showCatchSheet(context, spawn);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (report != null) {
        _recent.insert(
          0,
          _Recent(
            name: report.pokemon.name,
            dexNumber: report.pokemon.dexNumber,
            shiny: report.pokemon.shiny,
            level: report.pokemon.level,
          ),
        );
        if (_recent.length > 3) _recent.removeLast();
        _spawn = null;
        _status = 'Nice catch. Next one is close.';
        _nextSpawnAt = DateTime.now().add(const Duration(seconds: 22));
      }
    });
  }

  void _incense() {
    final trainer = ref.read(trainerProvider.notifier);
    if (ref.read(trainerProvider).quantityOf('incense') <= 0) {
      ref.read(soundServiceProvider).error();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No incense. Buy one in the shop.')),
        );
      return;
    }
    trainer.consumeItem('incense');
    _spawnNow();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catalog = ref.watch(dexCatalogProvider);
    final trainer = ref.watch(trainerProvider);
    final zones = catalog.zones;
    final zone = _zone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: CurrencyChip(
                icon: Icons.catching_pokemon_rounded,
                value: '${trainer.quantityOf('poke_ball')} balls',
              ),
            ),
          ),
        ],
      ),
      body: zones.isEmpty
          ? Center(
              child: Text(
                'No zones in the dataset.',
                style: theme.textTheme.titleMedium,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                Text('Where to next?', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 2),
                Text(
                  'Every zone pulls from the real Pokédex. Higher zones mean '
                  'higher levels — and rarer finds.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 124,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: zones.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = zones[index];
                      return _ZoneCard(
                        zone: item,
                        selected: item.slug == zone?.slug,
                        onTap: () => _selectZone(item),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (zone != null) _ZoneBanner(zone: zone, level: trainer.level),
                const SizedBox(height: AppSpacing.lg),
                AnimatedSwitcher(
                  duration: AppMotion.slow,
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.96,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _spawn == null
                      ? _EmptySpawn(
                          key: const ValueKey('empty'),
                          status: _status,
                          nextSpawnAt: _nextSpawnAt,
                          zone: zone,
                          onSearch: _spawnNow,
                          onIncense: _incense,
                          incense: trainer.quantityOf('incense'),
                        )
                      : _SpawnPanel(
                          key: ValueKey(_spawn!.pokemon.id),
                          spawn: _spawn!,
                          entry: catalog.speciesAt(_spawn!.pokemon.dexNumber),
                          onCatch: () => _catch(_spawn!),
                          onIncense: _incense,
                        ),
                ),
                if (_recent.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Recent encounters'),
                  for (final recent in _recent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Card(
                        child: ListTile(
                          leading: PokemonSprite(
                            dexNumber: recent.dexNumber,
                            fallbackTypes: const [],
                            size: 38,
                          ),
                          title: Text(
                            recent.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Lv. ${recent.level}${recent.shiny ? ' · shiny' : ''}',
                          ),
                          trailing: const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.teal,
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.lg),
                InfoBanner(
                  icon: Icons.eco_rounded,
                  text:
                      'Spawns appear while you explore and stay for 90 seconds. '
                      '${_zone?.name ?? 'This zone'} currently has '
                      '${_zone?.speciesCount ?? 0} species in rotation.',
                ),
              ],
            ),
    );
  }
}

class _Recent {
  const _Recent({
    required this.name,
    required this.dexNumber,
    required this.shiny,
    required this.level,
  });

  final String name;
  final int dexNumber;
  final bool shiny;
  final int level;
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.selected,
    required this.onTap,
  });

  final Zone zone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = zone.accent.first;
    final icon = switch (zone.icon) {
      'volcano' => Icons.local_fire_department_rounded,
      'waves' => Icons.water_rounded,
      'cave' => Icons.dark_mode_rounded,
      'storm' => Icons.thunderstorm_rounded,
      'mist' => Icons.cloud_rounded,
      _ => Icons.forest_rounded,
    };

    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          width: 218,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: selected ? 0.95 : 0.72),
                zone.accent.last.withValues(alpha: selected ? 0.8 : 0.45),
              ],
            ),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const Spacer(),
                  Text(
                    'Lv ${zone.minLevel}–${zone.maxLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                zone.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${zone.speciesCount} species',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneBanner extends StatelessWidget {
  const _ZoneBanner({required this.zone, required this.level});

  final Zone zone;
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: zone.accent.first.withValues(alpha: 0.1),
        border: Border.all(color: zone.accent.first.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.subtitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Wild levels ${zone.minLevel}–${zone.maxLevel} · '
                  'your trainer level $level',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 4,
            children: [
              for (final type in zone.types.take(3))
                TypeChip(type: type, dense: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpawnPanel extends StatelessWidget {
  const _SpawnPanel({
    super.key,
    required this.spawn,
    required this.entry,
    required this.onCatch,
    required this.onIncense,
  });

  final WildSpawn spawn;
  final DexEntry? entry;
  final VoidCallback onCatch;
  final VoidCallback onIncense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pokemon = spawn.pokemon;
    final tint = TypePalette.of(pokemon.types.first);
    final seconds = spawn.remaining().inSeconds;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.24), scheme.surfaceContainerLow],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              PillBadge(
                label: spawn.rarity.toUpperCase(),
                color: tint,
                icon: spawn.rarity == 'epic'
                    ? Icons.auto_awesome_rounded
                    : null,
              ),
              const Spacer(),
              PillBadge(
                label: '${seconds}s',
                icon: Icons.timer_outlined,
                color: seconds < 25 ? scheme.error : scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GlowPulse(
            color: tint,
            min: 0.3,
            max: 0.6,
            child: PokemonSprite(
              dexNumber: pokemon.dexNumber,
              fallbackTypes: pokemon.types,
              size: 152,
              shiny: pokemon.shiny,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pokemon.shiny ? '✨ ${pokemon.name}' : pokemon.name,
                style: theme.textTheme.headlineSmall,
              ),
              if (pokemon.shiny) ...[
                const SizedBox(width: 6),
                const PillBadge(
                  label: 'SHINY',
                  color: AppTheme.shiny,
                  icon: Icons.auto_awesome_rounded,
                ),
              ],
            ],
          ),
          Text(
            'Lv. ${pokemon.level} · ${entry?.genus ?? 'Wild Pokémon'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [for (final type in pokemon.types) TypeChip(type: type)],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCatch,
                  icon: const Icon(Icons.catching_pokemon_rounded),
                  label: const Text('Catch'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: 'Use incense',
                onPressed: onIncense,
                icon: const Icon(Icons.air_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySpawn extends StatelessWidget {
  const _EmptySpawn({
    super.key,
    required this.status,
    required this.nextSpawnAt,
    required this.zone,
    required this.onSearch,
    required this.onIncense,
    required this.incense,
  });

  final String status;
  final DateTime? nextSpawnAt;
  final Zone? zone;
  final VoidCallback onSearch;
  final VoidCallback onIncense;
  final int incense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wait = nextSpawnAt?.difference(DateTime.now()).inSeconds ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 114,
                  height: 114,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (zone?.accent.first ?? scheme.primary).withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
                Icon(
                  Icons.travel_explore_rounded,
                  size: 44,
                  color: zone?.accent.first ?? scheme.primary,
                ),
                const Positioned(
                  right: 36,
                  top: 14,
                  child: Icon(Icons.grass_rounded, size: 18),
                ),
              ],
            ),
          ),
          Text(
            wait > 0 ? 'Next spawn in ${wait}s' : status,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Stay in the zone. Spawns refresh on their own, or use incense to '
            'force one now.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Search now'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onIncense,
                icon: const Icon(Icons.air_rounded, size: 18),
                label: Text('Incense · $incense'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
