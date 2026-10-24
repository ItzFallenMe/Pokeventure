import 'dart:math' as math;

import '../models/pokemon.dart';

enum Stat { hp, attack, defense, spAttack, spDefense, speed }

extension StatLabel on Stat {
  String get short => switch (this) {
    Stat.hp => 'HP',
    Stat.attack => 'Atk',
    Stat.defense => 'Def',
    Stat.spAttack => 'SpA',
    Stat.spDefense => 'SpD',
    Stat.speed => 'Spe',
  };

  String get label => switch (this) {
    Stat.hp => 'HP',
    Stat.attack => 'Attack',
    Stat.defense => 'Defense',
    Stat.spAttack => 'Sp. Atk',
    Stat.spDefense => 'Sp. Def',
    Stat.speed => 'Speed',
  };
}

int statValue(PokemonStats stats, Stat stat) => switch (stat) {
  Stat.hp => stats.hp,
  Stat.attack => stats.attack,
  Stat.defense => stats.defense,
  Stat.spAttack => stats.spAttack,
  Stat.spDefense => stats.spDefense,
  Stat.speed => stats.speed,
};

PokemonStats statsWith(PokemonStats stats, Stat stat, int value) {
  return switch (stat) {
    Stat.hp => stats.copyWith(hp: value),
    Stat.attack => stats.copyWith(attack: value),
    Stat.defense => stats.copyWith(defense: value),
    Stat.spAttack => stats.copyWith(spAttack: value),
    Stat.spDefense => stats.copyWith(spDefense: value),
    Stat.speed => stats.copyWith(speed: value),
  };
}

/// The 25 natures. `null` pairs are the five neutral natures.
const Map<String, ({Stat? up, Stat? down})> natures = {
  'Hardy': (up: null, down: null),
  'Lonely': (up: Stat.attack, down: Stat.defense),
  'Brave': (up: Stat.attack, down: Stat.speed),
  'Adamant': (up: Stat.attack, down: Stat.spAttack),
  'Naughty': (up: Stat.attack, down: Stat.spDefense),
  'Bold': (up: Stat.defense, down: Stat.attack),
  'Docile': (up: null, down: null),
  'Relaxed': (up: Stat.defense, down: Stat.speed),
  'Impish': (up: Stat.defense, down: Stat.spAttack),
  'Lax': (up: Stat.defense, down: Stat.spDefense),
  'Timid': (up: Stat.speed, down: Stat.attack),
  'Hasty': (up: Stat.speed, down: Stat.defense),
  'Serious': (up: null, down: null),
  'Jolly': (up: Stat.speed, down: Stat.spAttack),
  'Naive': (up: Stat.speed, down: Stat.spDefense),
  'Modest': (up: Stat.spAttack, down: Stat.attack),
  'Mild': (up: Stat.spAttack, down: Stat.defense),
  'Quiet': (up: Stat.spAttack, down: Stat.speed),
  'Bashful': (up: null, down: null),
  'Rash': (up: Stat.spAttack, down: Stat.spDefense),
  'Calm': (up: Stat.spDefense, down: Stat.attack),
  'Gentle': (up: Stat.spDefense, down: Stat.defense),
  'Sassy': (up: Stat.spDefense, down: Stat.speed),
  'Careful': (up: Stat.spDefense, down: Stat.spAttack),
  'Quirky': (up: null, down: null),
};

List<String> get natureNames => natures.keys.toList(growable: false);

String? natureHint(String nature) {
  final pair = natures[nature];
  if (pair == null || pair.up == null || pair.down == null) return null;
  return '+${pair.up!.short} / −${pair.down!.short}';
}

int _hpFor(int base, int iv, int ev, int level) {
  return ((2 * base + iv + ev ~/ 4) * level) ~/ 100 + level + 10;
}

int _statFor(int base, int iv, int ev, int level) {
  return ((2 * base + iv + ev ~/ 4) * level) ~/ 100 + 5;
}

double _natureMultiplier(String nature, Stat stat) {
  final pair = natures[nature];
  if (pair == null) return 1;
  if (pair.up == stat) return 1.1;
  if (pair.down == stat) return 0.9;
  return 1;
}

/// Full level-scaled stat block, exactly the mainline formula with the
/// nature applied to the five non-HP stats.
PokemonStats computeStats({
  required PokemonStats base,
  required PokemonStats ivs,
  required PokemonStats evs,
  required int level,
  required String nature,
}) {
  int calc(Stat stat, int baseValue, int iv, int ev) {
    if (stat == Stat.hp) return _hpFor(baseValue, iv, ev, level);
    return (_statFor(baseValue, iv, ev, level) *
            _natureMultiplier(nature, stat))
        .floor();
  }

  return PokemonStats(
    hp: calc(Stat.hp, base.hp, ivs.hp, evs.hp),
    attack: calc(Stat.attack, base.attack, ivs.attack, evs.attack),
    defense: calc(Stat.defense, base.defense, ivs.defense, evs.defense),
    spAttack: calc(Stat.spAttack, base.spAttack, ivs.spAttack, evs.spAttack),
    spDefense: calc(
      Stat.spDefense,
      base.spDefense,
      ivs.spDefense,
      evs.spDefense,
    ),
    speed: calc(Stat.speed, base.speed, ivs.speed, evs.speed),
  );
}

/// Total XP required to reach [level]. Level 5 starts at 100 XP.
int totalXpForLevel(int level) {
  if (level <= 1) return 0;
  return (0.8 * math.pow(level, 3)).round();
}

int levelFromXp(int xp) {
  var level = 1;
  while (level < 100 && xp >= totalXpForLevel(level + 1)) {
    level += 1;
  }
  return level;
}

int xpToNextLevel(int level, int xp) {
  if (level >= 100) return 0;
  return math.max(0, totalXpForLevel(level + 1) - xp);
}

double xpProgress(int level, int xp) {
  if (level >= 100) return 1;
  final floorXp = totalXpForLevel(level);
  final ceilXp = totalXpForLevel(level + 1);
  if (ceilXp <= floorXp) return 1;
  return ((xp - floorXp) / (ceilXp - floorXp)).clamp(0.0, 1.0);
}

/// Trainer levels are deliberately flatter than Pokémon levels, so catching a
/// few things early always moves the bar.
int trainerLevelForXp(int xp) {
  return (1 + math.sqrt(math.max(0, xp) / 180)).floor().clamp(1, 50);
}

int trainerXpForLevel(int level) {
  final clamped = level.clamp(1, 50);
  return 180 * (clamped - 1) * (clamped - 1);
}

double trainerXpProgress(int xp, int level) {
  if (level >= 50) return 1;
  final floorXp = trainerXpForLevel(level);
  final ceilXp = trainerXpForLevel(level + 1);
  return ((xp - floorXp) / (ceilXp - floorXp)).clamp(0.0, 1.0);
}
