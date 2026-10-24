import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokeventure/data/game/wild_battle.dart';
import 'package:pokeventure/data/models/move_entry.dart';
import 'package:pokeventure/data/models/pokemon.dart';
import 'package:pokeventure/data/models/pokemon_type.dart';

const _tackle = MoveEntry(
  name: 'Tackle',
  type: PokemonType.normal,
  category: 'Physical',
  power: 40,
  accuracy: 100,
  pp: 35,
  priority: 0,
);

const _ember = MoveEntry(
  name: 'Ember',
  type: PokemonType.fire,
  category: 'Special',
  power: 40,
  accuracy: 100,
  pp: 25,
  priority: 0,
);

const _growl = MoveEntry(
  name: 'Growl',
  type: PokemonType.normal,
  category: 'Status',
  power: 0,
  accuracy: 100,
  pp: 40,
  priority: 0,
);

const _stats = PokemonStats(
  hp: 40,
  attack: 40,
  defense: 40,
  spAttack: 40,
  spDefense: 40,
  speed: 40,
);

Pokemon _mon({
  required String name,
  required List<PokemonType> types,
  required List<String> moves,
  int currentHp = 40,
  int level = 20,
}) {
  return Pokemon(
    id: name.toLowerCase(),
    dexNumber: 1,
    name: name,
    types: types,
    level: level,
    ivs: PokemonStats.zero,
    evs: PokemonStats.zero,
    stats: _stats,
    maxHp: 40,
    currentHp: currentHp,
    moves: moves,
    nature: 'Hardy',
    ability: 'Overgrow',
  );
}

void main() {
  final moves = {'tackle': _tackle, 'ember': _ember, 'growl': _growl};

  test('a damaging move takes HP and preserves it for the catch sheet', () {
    final wild = _mon(
      name: 'Bulbasaur',
      types: [PokemonType.grass],
      moves: ['Tackle'],
    );
    final player = _mon(
      name: 'Charmander',
      types: [PokemonType.fire],
      moves: ['Ember'],
    );
    final battle = WildBattle(
      player: player,
      wild: wild,
      moves: moves,
      random: Random(4),
    );

    final lines = battle.useMove('Ember');

    expect(lines.join(' '), contains('Charmander used Ember'));
    expect(battle.wildHp, lessThan(wild.maxHp));
    expect(battle.catchTarget.currentHp, battle.wildHp);
  });

  test('super-effective damage beats a resisted move', () {
    final wild = _mon(
      name: 'Bulbasaur',
      types: [PokemonType.grass],
      moves: ['Tackle'],
    );
    final fireUser = _mon(
      name: 'Charmander',
      types: [PokemonType.fire],
      moves: ['Ember'],
    );
    final normalUser = _mon(
      name: 'Rattata',
      types: [PokemonType.normal],
      moves: ['Ember'],
    );

    final fireBattle = WildBattle(
      player: fireUser,
      wild: wild,
      moves: moves,
      random: Random(9),
    );
    final normalBattle = WildBattle(
      player: normalUser,
      wild: wild,
      moves: moves,
      random: Random(9),
    );

    fireBattle.useMove('Ember');
    normalBattle.useMove('Ember');

    expect(fireBattle.wildHp, lessThan(normalBattle.wildHp));
  });

  test('a wild Pokémon at 1 HP faints and ends the battle', () {
    final wild = _mon(
      name: 'Bulbasaur',
      types: [PokemonType.grass],
      moves: ['Tackle'],
      currentHp: 1,
    );
    final player = _mon(
      name: 'Charmander',
      types: [PokemonType.fire],
      moves: ['Ember'],
    );
    final battle = WildBattle(
      player: player,
      wild: wild,
      moves: moves,
      random: Random(1),
    );

    battle.useMove('Ember');

    expect(battle.wildFainted, isTrue);
    expect(battle.playerWon, isTrue);
    expect(battle.over, isTrue);
  });

  test('switching sends out the next party member', () {
    final wild = _mon(
      name: 'Bulbasaur',
      types: [PokemonType.grass],
      moves: ['Tackle'],
    );
    final first = _mon(
      name: 'Charmander',
      types: [PokemonType.fire],
      moves: ['Ember'],
    );
    final second = _mon(
      name: 'Squirtle',
      types: [PokemonType.water],
      moves: ['Tackle'],
      currentHp: 27,
    );
    final battle = WildBattle(
      player: first,
      wild: wild,
      moves: moves,
      random: Random(2),
    );

    final lines = battle.switchTo(second, wildAttacks: false);

    expect(lines.first, 'Go, Squirtle!');
    expect(battle.player.name, 'Squirtle');
    expect(battle.playerHp, 27);
  });

  test('wild win XP scales with the opponent', () {
    expect(xpFromWildWin(baseExp: 64, level: 10), greaterThan(0));
    expect(
      xpFromWildWin(baseExp: 200, level: 40),
      greaterThan(xpFromWildWin(baseExp: 64, level: 10)),
    );
  });
}
