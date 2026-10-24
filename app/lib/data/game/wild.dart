import 'dart:math';
import 'dart:math' as math;

import '../models/dex_entry.dart';
import '../models/pokemon.dart';
import '../models/zone.dart';
import 'stats.dart';

const double kShinyRate = 1 / 2048;

class WildSpawn {
  const WildSpawn({
    required this.pokemon,
    required this.rarity,
    required this.zoneSlug,
    required this.spawnedAt,
    required this.expiresAt,
  });

  final Pokemon pokemon;
  final String rarity;
  final String zoneSlug;
  final DateTime spawnedAt;
  final DateTime expiresAt;

  bool isExpired([DateTime? now]) {
    return (now ?? DateTime.now()).isAfter(expiresAt);
  }

  Duration remaining([DateTime? now]) {
    final left = expiresAt.difference(now ?? DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  WildSpawn copyWith({Pokemon? pokemon}) {
    return WildSpawn(
      pokemon: pokemon ?? this.pokemon,
      rarity: rarity,
      zoneSlug: zoneSlug,
      spawnedAt: spawnedAt,
      expiresAt: expiresAt,
    );
  }
}

String _newId(Random random, int dexNumber) {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final salt = random.nextInt(1 << 20).toRadixString(36);
  return 'pkm_${dexNumber}_${stamp.toRadixString(36)}_$salt';
}

PokemonStats _randomIvs(Random random) {
  int roll() => random.nextInt(32);
  return PokemonStats(
    hp: roll(),
    attack: roll(),
    defense: roll(),
    spAttack: roll(),
    spDefense: roll(),
    speed: roll(),
  );
}

String _randomNature(Random random) {
  final names = natureNames;
  return names[random.nextInt(names.length)];
}

/// Turns a species into a concrete level-[level] Pokémon with real IVs,
/// nature, ability, stats and level-up moves.
Pokemon createPokemon({
  required DexEntry species,
  required int level,
  required Random random,
  bool? shiny,
  String? zone,
  String? ability,
  String ball = 'Poké Ball',
}) {
  final safeLevel = level.clamp(1, 100);
  final ivs = _randomIvs(random);
  final evs = PokemonStats.zero;
  final nature = _randomNature(random);
  final stats = computeStats(
    base: species.baseStats,
    ivs: ivs,
    evs: evs,
    level: safeLevel,
    nature: nature,
  );
  final hidden = species.hiddenAbility;
  final chosenAbility =
      ability ??
      (hidden != null && random.nextInt(20) == 0
          ? hidden
          : species.normalAbility ?? '—');
  final isShiny = shiny ?? random.nextDouble() < kShinyRate;

  return Pokemon(
    id: _newId(random, species.number),
    dexNumber: species.number,
    name: species.name,
    types: species.types,
    level: safeLevel,
    xp: 0,
    baseStats: species.baseStats,
    ivs: ivs,
    evs: evs,
    stats: stats,
    maxHp: stats.hp,
    currentHp: stats.hp,
    moves: species.movesAtLevel(safeLevel),
    nature: nature,
    ability: chosenAbility,
    shiny: isShiny,
    metLevel: safeLevel,
    metZone: zone,
    caughtAt: DateTime.now(),
    ball: ball,
  );
}

/// A starter is just a normal Pokémon with a few guaranteed IVs so a new
/// trainer's first partner feels worth keeping.
Pokemon createStarter(DexEntry species, {Random? random, int level = 5}) {
  final rng = random ?? Random();
  final starter = createPokemon(
    species: species,
    level: level,
    random: rng,
    shiny: false,
    zone: 'Starter Lab',
    ability: species.normalAbility,
  );
  final ivs = PokemonStats(
    hp: math.max(20, starter.ivs.hp),
    attack: math.max(18, starter.ivs.attack),
    defense: math.max(18, starter.ivs.defense),
    spAttack: math.max(18, starter.ivs.spAttack),
    spDefense: math.max(18, starter.ivs.spDefense),
    speed: math.max(18, starter.ivs.speed),
  );
  final stats = computeStats(
    base: species.baseStats,
    ivs: ivs,
    evs: starter.evs,
    level: level,
    nature: starter.nature,
  );
  return starter.copyWith(
    ivs: ivs,
    stats: stats,
    maxHp: stats.hp,
    currentHp: stats.hp,
  );
}

/// Rolls a spawn from a zone's real species pool. Rarity comes from the
/// generated table, so swarms, rares and epics are not hardcoded in the UI.
WildSpawn? rollWildSpawn({
  required Zone zone,
  required Map<int, DexEntry> byNumber,
  required Random random,
  DateTime? now,
}) {
  if (zone.spawns.isEmpty) return null;
  final roll = random.nextInt(zone.totalWeight);
  var cursor = 0;
  ZoneSpawn? chosen;
  for (final spawn in zone.spawns) {
    cursor += spawn.weight;
    if (roll < cursor) {
      chosen = spawn;
      break;
    }
  }
  chosen ??= zone.spawns.last;

  final species = byNumber[chosen.number];
  if (species == null) return null;

  final level =
      zone.minLevel +
      random.nextInt(math.max(1, zone.maxLevel - zone.minLevel + 1).toInt());
  final pokemon = createPokemon(
    species: species,
    level: level,
    random: random,
    zone: zone.name,
  );
  final stamp = now ?? DateTime.now();
  return WildSpawn(
    pokemon: pokemon,
    rarity: chosen.rarity,
    zoneSlug: zone.slug,
    spawnedAt: stamp,
    expiresAt: stamp.add(const Duration(seconds: 90)),
  );
}

/// The daily featured Pokémon, stable for the whole day and built from the
/// real dex rather than a hardcoded showcase list.
WildSpawn? dailyFeatured({
  required List<DexEntry> species,
  required Map<int, DexEntry> byNumber,
  DateTime? now,
  int level = 12,
}) {
  final day = now ?? DateTime.now();
  final pool = species
      .where((entry) => !entry.isLegendary && entry.statTotal <= 520)
      .toList(growable: false);
  if (pool.isEmpty) return null;
  final seed = day.year * 10000 + day.month * 100 + day.day;
  final random = Random(seed);
  final entry = pool[random.nextInt(pool.length)];
  final pokemon = createPokemon(
    species: entry,
    level: level,
    random: random,
    shiny: false,
    zone: 'Daily habitat',
  );
  final stamp = now ?? DateTime.now();
  return WildSpawn(
    pokemon: pokemon,
    rarity: entry.rarityLabel.toLowerCase(),
    zoneSlug: 'daily',
    spawnedAt: stamp,
    expiresAt: stamp.add(const Duration(hours: 24)),
  );
}

/// Applies an evolution while keeping the Pokémon's identity and build.
Pokemon evolvePokemon(Pokemon pokemon, DexEntry target) {
  final stats = computeStats(
    base: target.baseStats,
    ivs: pokemon.ivs,
    evs: pokemon.evs,
    level: pokemon.level,
    nature: pokemon.nature,
  );
  final moves = List<String>.from(pokemon.moves);
  for (final move in target.movesAtLevel(pokemon.level)) {
    if (!moves.contains(move)) moves.add(move);
  }
  final trimmed = moves.length > 4 ? moves.sublist(moves.length - 4) : moves;
  return pokemon.copyWith(
    dexNumber: target.number,
    name: target.name,
    types: target.types,
    baseStats: target.baseStats,
    stats: stats,
    maxHp: stats.hp,
    currentHp: math.max(1, stats.hp - (pokemon.maxHp - pokemon.currentHp)),
    moves: trimmed,
  );
}
