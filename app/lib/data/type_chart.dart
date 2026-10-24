import 'models/pokemon_type.dart';

/// Damage multiplier for [attack] against one or two defending types.
double typeEffectiveness(PokemonType attack, List<PokemonType> defenders) {
  var multiplier = 1.0;
  for (final defender in defenders) {
    multiplier *= _chart[attack]?[defender] ?? 1.0;
  }
  return multiplier;
}

String effectivenessLabel(double multiplier) {
  if (multiplier == 0) return '0×';
  if (multiplier == 4) return '4×';
  if (multiplier > 1) return '2×';
  if (multiplier == 0.25) return '¼×';
  if (multiplier < 1) return '½×';
  return '1×';
}

/// Only non-neutral matchups are listed; anything missing is 1×.
const Map<PokemonType, Map<PokemonType, double>> _chart = {
  PokemonType.normal: {
    PokemonType.rock: 0.5,
    PokemonType.ghost: 0,
    PokemonType.steel: 0.5,
  },
  PokemonType.fire: {
    PokemonType.fire: 0.5,
    PokemonType.water: 0.5,
    PokemonType.grass: 2,
    PokemonType.ice: 2,
    PokemonType.bug: 2,
    PokemonType.rock: 0.5,
    PokemonType.dragon: 0.5,
    PokemonType.steel: 2,
  },
  PokemonType.water: {
    PokemonType.fire: 2,
    PokemonType.water: 0.5,
    PokemonType.grass: 0.5,
    PokemonType.ground: 2,
    PokemonType.rock: 2,
    PokemonType.dragon: 0.5,
  },
  PokemonType.electric: {
    PokemonType.water: 2,
    PokemonType.electric: 0.5,
    PokemonType.grass: 0.5,
    PokemonType.ground: 0,
    PokemonType.flying: 2,
    PokemonType.dragon: 0.5,
  },
  PokemonType.grass: {
    PokemonType.fire: 0.5,
    PokemonType.water: 2,
    PokemonType.grass: 0.5,
    PokemonType.poison: 0.5,
    PokemonType.ground: 2,
    PokemonType.flying: 0.5,
    PokemonType.bug: 0.5,
    PokemonType.rock: 2,
    PokemonType.dragon: 0.5,
    PokemonType.steel: 0.5,
  },
  PokemonType.ice: {
    PokemonType.fire: 0.5,
    PokemonType.water: 0.5,
    PokemonType.grass: 2,
    PokemonType.ice: 0.5,
    PokemonType.ground: 2,
    PokemonType.flying: 2,
    PokemonType.dragon: 2,
    PokemonType.steel: 0.5,
  },
  PokemonType.fighting: {
    PokemonType.normal: 2,
    PokemonType.ice: 2,
    PokemonType.poison: 0.5,
    PokemonType.flying: 0.5,
    PokemonType.psychic: 0.5,
    PokemonType.bug: 0.5,
    PokemonType.rock: 2,
    PokemonType.ghost: 0,
    PokemonType.dark: 2,
    PokemonType.steel: 2,
    PokemonType.fairy: 0.5,
  },
  PokemonType.poison: {
    PokemonType.grass: 2,
    PokemonType.poison: 0.5,
    PokemonType.ground: 0.5,
    PokemonType.rock: 0.5,
    PokemonType.ghost: 0.5,
    PokemonType.steel: 0,
    PokemonType.fairy: 2,
  },
  PokemonType.ground: {
    PokemonType.fire: 2,
    PokemonType.electric: 2,
    PokemonType.grass: 0.5,
    PokemonType.poison: 2,
    PokemonType.flying: 0,
    PokemonType.bug: 0.5,
    PokemonType.rock: 2,
    PokemonType.steel: 2,
  },
  PokemonType.flying: {
    PokemonType.electric: 0.5,
    PokemonType.grass: 2,
    PokemonType.fighting: 2,
    PokemonType.bug: 2,
    PokemonType.rock: 0.5,
    PokemonType.steel: 0.5,
  },
  PokemonType.psychic: {
    PokemonType.fighting: 2,
    PokemonType.poison: 2,
    PokemonType.psychic: 0.5,
    PokemonType.dark: 0,
    PokemonType.steel: 0.5,
  },
  PokemonType.bug: {
    PokemonType.fire: 0.5,
    PokemonType.grass: 2,
    PokemonType.fighting: 0.5,
    PokemonType.poison: 0.5,
    PokemonType.flying: 0.5,
    PokemonType.psychic: 2,
    PokemonType.ghost: 0.5,
    PokemonType.dark: 2,
    PokemonType.steel: 0.5,
    PokemonType.fairy: 0.5,
  },
  PokemonType.rock: {
    PokemonType.fire: 2,
    PokemonType.ice: 2,
    PokemonType.fighting: 0.5,
    PokemonType.ground: 0.5,
    PokemonType.flying: 2,
    PokemonType.bug: 2,
    PokemonType.steel: 0.5,
  },
  PokemonType.ghost: {
    PokemonType.normal: 0,
    PokemonType.psychic: 2,
    PokemonType.ghost: 2,
    PokemonType.dark: 0.5,
  },
  PokemonType.dragon: {
    PokemonType.dragon: 2,
    PokemonType.steel: 0.5,
    PokemonType.fairy: 0,
  },
  PokemonType.dark: {
    PokemonType.fighting: 0.5,
    PokemonType.psychic: 2,
    PokemonType.ghost: 2,
    PokemonType.dark: 0.5,
    PokemonType.fairy: 0.5,
  },
  PokemonType.steel: {
    PokemonType.fire: 0.5,
    PokemonType.water: 0.5,
    PokemonType.electric: 0.5,
    PokemonType.ice: 2,
    PokemonType.rock: 2,
    PokemonType.steel: 0.5,
    PokemonType.fairy: 2,
  },
  PokemonType.fairy: {
    PokemonType.fire: 0.5,
    PokemonType.fighting: 2,
    PokemonType.poison: 0.5,
    PokemonType.dragon: 2,
    PokemonType.dark: 2,
    PokemonType.steel: 0.5,
  },
};
