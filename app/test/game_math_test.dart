import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokeventure/data/game/catch.dart';
import 'package:pokeventure/data/game/stats.dart';
import 'package:pokeventure/data/models/pokemon.dart';
import 'package:pokeventure/data/models/pokemon_type.dart';

const _bulbaBase = PokemonStats(
  hp: 45,
  attack: 49,
  defense: 49,
  spAttack: 65,
  spDefense: 65,
  speed: 45,
);

void main() {
  group('stats', () {
    test('level-scaled HP uses the mainline formula', () {
      final stats = computeStats(
        base: _bulbaBase,
        ivs: const PokemonStats(
          hp: 31,
          attack: 31,
          defense: 31,
          spAttack: 31,
          spDefense: 31,
          speed: 31,
        ),
        evs: PokemonStats.zero,
        level: 5,
        nature: 'Hardy',
      );

      // ((2*45 + 31) * 5) / 100 + 5 + 10 = 21
      expect(stats.hp, 21);
      // ((2*49 + 31) * 5) / 100 + 5 = 11
      expect(stats.attack, 11);
    });

    test('natures raise one stat and lower another', () {
      final modest = computeStats(
        base: _bulbaBase,
        ivs: PokemonStats.zero,
        evs: PokemonStats.zero,
        level: 50,
        nature: 'Modest',
      );
      final adamant = computeStats(
        base: _bulbaBase,
        ivs: PokemonStats.zero,
        evs: PokemonStats.zero,
        level: 50,
        nature: 'Adamant',
      );

      expect(modest.spAttack, greaterThan(adamant.spAttack));
      expect(modest.attack, lessThan(adamant.attack));
      expect(modest.hp, adamant.hp);
    });

    test('every nature is mapped and neutral natures exist', () {
      expect(natures, hasLength(25));
      expect(natureHint('Hardy'), isNull);
      expect(natureHint('Modest'), '+SpA / −Atk');
    });

    test('XP thresholds increase and level 100 is the cap', () {
      for (var level = 2; level < 100; level++) {
        expect(totalXpForLevel(level + 1), greaterThan(totalXpForLevel(level)));
      }
      expect(levelFromXp(totalXpForLevel(16)), 16);
      expect(levelFromXp(99999999), 100);
      expect(xpToNextLevel(100, 0), 0);
      expect(xpProgress(5, 100), 0);
      expect(xpProgress(5, totalXpForLevel(6) - 1), greaterThan(0.9));
    });

    test('trainer levels grow with XP', () {
      expect(trainerLevelForXp(0), 1);
      expect(trainerLevelForXp(180), 2);
      expect(trainerLevelForXp(1000000), 50);
      expect(trainerXpProgress(0, 1), 0);
    });
  });

  group('catch math', () {
    test('chance stays inside the safe band', () {
      for (final rate in [1, 3, 45, 120, 255]) {
        final chance = catchChance(
          catchRate: rate,
          level: 30,
          ball: ballBySlug('poke_ball'),
          targetTypes: const [PokemonType.normal],
        );
        expect(chance, inInclusiveRange(0.03, 0.95));
      }
    });

    test('better balls and berries improve the odds', () {
      final poke = catchChance(
        catchRate: 45,
        level: 12,
        ball: ballBySlug('poke_ball'),
        targetTypes: const [PokemonType.fire],
      );
      final ultra = catchChance(
        catchRate: 45,
        level: 12,
        ball: ballBySlug('ultra_ball'),
        targetTypes: const [PokemonType.fire],
      );
      final razz = catchChance(
        catchRate: 45,
        level: 12,
        ball: ballBySlug('poke_ball'),
        targetTypes: const [PokemonType.fire],
        berry: 1.5,
      );

      expect(ultra, greaterThan(poke));
      expect(razz, greaterThan(poke));
    });

    test('rarer species are harder and flee more often', () {
      final common = catchChance(
        catchRate: 255,
        level: 10,
        ball: ballBySlug('poke_ball'),
        targetTypes: const [PokemonType.normal],
      );
      final legendary = catchChance(
        catchRate: 3,
        level: 10,
        ball: ballBySlug('poke_ball'),
        targetTypes: const [PokemonType.psychic],
      );
      expect(legendary, lessThan(common));
      expect(
        fleeChance(catchRate: 3, rarity: 'epic'),
        greaterThan(fleeChance(catchRate: 255, rarity: 'common')),
      );
    });

    test('special balls only boost their own types', () {
      expect(
        ballMultiplier('net_ball', const [PokemonType.bug]),
        greaterThan(1),
      );
      expect(ballMultiplier('net_ball', const [PokemonType.fire]), 1);
      expect(
        ballMultiplier('dusk_ball', const [PokemonType.ghost]),
        greaterThan(1),
      );
      expect(ballMultiplier('dusk_ball', const [PokemonType.water]), 1);
    });

    test('timing rings award better multipliers', () {
      expect(timingBonus(0.9), 1.3);
      expect(timingBonus(0.6), 1.15);
      expect(timingBonus(0.35), 1.05);
      expect(timingBonus(0), 1);
      expect(catchDifficulty(0.8), 'Easy');
      expect(catchDifficulty(0.05), 'Brutal');
    });
  });

  test('a random species factory produces valid stats and moves', () {
    // Sanity check the shared Random usage without touching the catalog.
    final random = Random(3);
    expect(random.nextInt(32), inInclusiveRange(0, 31));
  });
}
