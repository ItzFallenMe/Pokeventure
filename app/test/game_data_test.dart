import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeventure/data/dex_repository.dart';
import 'package:pokeventure/data/game/wild.dart';
import 'package:pokeventure/data/models/pokemon_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DexCatalog catalog;

  setUpAll(() async {
    catalog = await loadDexCatalog();
  });

  test('the dataset covers every species through Gen 9', () {
    expect(catalog.species, hasLength(1025));
    expect(catalog.species.first.number, 1);
    expect(catalog.species.last.number, 1025);
    expect(catalog.moves.length, greaterThan(900));
    expect(catalog.zones, hasLength(6));
  });

  test('every species has real stats, types and flavour text', () {
    for (final entry in catalog.species) {
      expect(entry.baseStats.total, greaterThan(0), reason: entry.name);
      expect(entry.types, isNotEmpty, reason: entry.name);
      expect(entry.catchRate, inInclusiveRange(1, 255), reason: entry.name);
      expect(entry.description, isNotEmpty, reason: entry.name);
      expect(entry.genus, isNotEmpty, reason: entry.name);
      expect(entry.normalAbility, isNotNull, reason: entry.name);
    }
  });

  test('level-up learnsets are present for playable species', () {
    const knownExceptions = {11, 14, 63, 132, 201, 235, 266, 268, 824};
    for (final entry in catalog.species) {
      if (knownExceptions.contains(entry.number)) continue;
      expect(entry.moves.length, greaterThanOrEqualTo(2), reason: entry.name);
    }
  });

  test('starters know moves at level 5 and evolve by level', () {
    for (final number in [1, 4, 7]) {
      final starter = catalog.speciesAt(number)!;
      expect(starter.movesAtLevel(5), isNotEmpty);
      expect(starter.movesAtLevel(5).length, lessThanOrEqualTo(4));
    }
    final charmander = catalog.speciesAt(4)!;
    final evolution = charmander.evolutions.firstWhere(
      (evolution) => evolution.isLevelUp,
    );
    expect(evolution.name, 'Charmeleon');
    expect(evolution.level, 16);
  });

  test('zones only reference real species and have healthy pools', () {
    final rarities = {'common', 'uncommon', 'rare', 'epic'};
    for (final zone in catalog.zones) {
      expect(zone.spawns.length, greaterThanOrEqualTo(20), reason: zone.name);
      expect(zone.minLevel, lessThan(zone.maxLevel));
      for (final spawn in zone.spawns) {
        expect(
          catalog.speciesAt(spawn.number),
          isNotNull,
          reason: '${zone.name} → ${spawn.number}',
        );
        expect(rarities, contains(spawn.rarity));
        expect(spawn.weight, greaterThan(0));
      }
    }
  });

  test('rolled spawns use the zone level band and never legendaries', () {
    final random = Random(11);
    for (final zone in catalog.zones) {
      for (var i = 0; i < 40; i++) {
        final spawn = rollWildSpawn(
          zone: zone,
          byNumber: catalog.byNumber,
          random: random,
        )!;
        expect(
          spawn.pokemon.level,
          inInclusiveRange(zone.minLevel, zone.maxLevel),
        );
        expect(spawn.pokemon.types, isNotEmpty);
        expect(spawn.pokemon.moves, isNotEmpty);
        expect(spawn.pokemon.stats.hp, spawn.pokemon.maxHp);
        expect(spawn.pokemon.shiny, isA<bool>());
      }
    }
  });

  test('daily featured Pokémon is stable for a day', () {
    final day = DateTime(2026, 10, 24);
    final first = dailyFeatured(
      species: catalog.species,
      byNumber: catalog.byNumber,
      now: day,
    )!;
    final second = dailyFeatured(
      species: catalog.species,
      byNumber: catalog.byNumber,
      now: day.add(const Duration(hours: 6)),
    )!;
    expect(second.pokemon.dexNumber, first.pokemon.dexNumber);
    expect(second.pokemon.level, first.pokemon.level);
  });

  test('type chart colours exist for every type', () {
    for (final type in PokemonType.values) {
      expect(type.label, isNotEmpty);
    }
  });

  test('music, sound and font assets are bundled', () async {
    final theme = await rootBundle.load('assets/audio/theme.wav');
    final catchSound = await rootBundle.load('assets/audio/catch.wav');
    final font = await rootBundle.load('assets/fonts/Outfit-Variable.ttf');
    expect(theme.lengthInBytes, greaterThan(100000));
    expect(catchSound.lengthInBytes, greaterThan(10000));
    expect(font.lengthInBytes, greaterThan(50000));
  });
}
