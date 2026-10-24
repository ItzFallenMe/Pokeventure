import 'dart:math' as math;

import '../models/pokemon_type.dart';

class BallDef {
  const BallDef({
    required this.slug,
    required this.name,
    required this.shortName,
    required this.multiplier,
    required this.description,
  });

  final String slug;
  final String name;
  final String shortName;
  final double multiplier;
  final String description;
}

const ballCatalog = <BallDef>[
  BallDef(
    slug: 'poke_ball',
    name: 'Poké Ball',
    shortName: 'Poké',
    multiplier: 1,
    description: 'The standard ball. 1× catch rate.',
  ),
  BallDef(
    slug: 'great_ball',
    name: 'Great Ball',
    shortName: 'Great',
    multiplier: 1.5,
    description: 'Better performance. 1.5× catch rate.',
  ),
  BallDef(
    slug: 'ultra_ball',
    name: 'Ultra Ball',
    shortName: 'Ultra',
    multiplier: 2,
    description: 'High-performance ball. 2× catch rate.',
  ),
  BallDef(
    slug: 'net_ball',
    name: 'Net Ball',
    shortName: 'Net',
    multiplier: 3.5,
    description: '3.5× against Water and Bug types.',
  ),
  BallDef(
    slug: 'dusk_ball',
    name: 'Dusk Ball',
    shortName: 'Dusk',
    multiplier: 3,
    description: '3× on Dark and Ghost types.',
  ),
];

BallDef ballBySlug(String slug) {
  return ballCatalog.firstWhere(
    (ball) => ball.slug == slug,
    orElse: () => ballCatalog.first,
  );
}

/// The effective multiplier for a ball against a specific target.
double ballMultiplier(String slug, List<PokemonType> types) {
  final ball = ballBySlug(slug);
  switch (ball.slug) {
    case 'net_ball':
      final matches = types.any(
        (type) => type == PokemonType.water || type == PokemonType.bug,
      );
      return matches ? ball.multiplier : 1;
    case 'dusk_ball':
      final matches = types.any(
        (type) => type == PokemonType.dark || type == PokemonType.ghost,
      );
      return matches ? ball.multiplier : 1;
    default:
      return ball.multiplier;
  }
}

/// Razz berries feed into the same roll; the golden one is a rare reward.
const Map<String, double> berryMultipliers = {
  'razz_berry': 1.5,
  'golden_razz': 2.5,
};

/// The chance to catch a wild Pokémon this throw, clamped so every species is
/// possible and nothing is a guaranteed catch.
double catchChance({
  required int catchRate,
  required int level,
  required BallDef ball,
  required List<PokemonType> targetTypes,
  double berry = 1,
  double timing = 1,
  int currentHp = 0,
  int maxHp = 0,
}) {
  final rate = catchRate.clamp(1, 255);
  final levelFactor = (1 - (level - 5) * 0.004).clamp(0.65, 1.0);
  final hpFactor = maxHp > 0
      ? (0.82 + 0.18 * (1 - currentHp / maxHp)).clamp(0.82, 1.0)
      : 1.0;

  final chance =
      (rate / 255) *
      ballMultiplier(ball.slug, targetTypes) *
      berry *
      timing *
      levelFactor *
      hpFactor *
      1.9;

  return chance.clamp(0.03, 0.95);
}

String catchDifficulty(double chance) {
  if (chance >= 0.75) return 'Easy';
  if (chance >= 0.5) return 'Fair';
  if (chance >= 0.3) return 'Tricky';
  if (chance >= 0.15) return 'Hard';
  return 'Brutal';
}

/// How likely a failed catch makes the Pokémon run away.
double fleeChance({required int catchRate, required String rarity}) {
  final base = 0.04 + (255 - catchRate.clamp(1, 255)) / 1200;
  final bonus = switch (rarity) {
    'epic' => 0.06,
    'rare' => 0.03,
    _ => 0.0,
  };
  return (base + bonus).clamp(0.04, 0.32);
}

/// Timing rings: tighter ring, better multiplier.
double timingBonus(double tightness) {
  if (tightness >= 0.82) return 1.3; // excellent
  if (tightness >= 0.55) return 1.15; // great
  if (tightness >= 0.3) return 1.05; // nice
  return 1.0;
}

String timingLabel(double tightness) {
  if (tightness >= 0.82) return 'Excellent!';
  if (tightness >= 0.55) return 'Great!';
  if (tightness >= 0.3) return 'Nice!';
  return 'Too early';
}

int xpFromCatch({required int baseExp, required int level}) {
  return math.max(12, (baseExp * (level + 4) / 9).round());
}

int coinsFromCatch({required int level, required bool newSpecies}) {
  return 35 + level * 2 + (newSpecies ? 80 : 0);
}
