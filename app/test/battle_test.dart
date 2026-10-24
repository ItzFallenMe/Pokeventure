import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokeventure/app/pokeventure_app.dart';
import 'package:pokeventure/data/battle_api.dart';
import 'package:pokeventure/data/battle_log.dart';
import 'package:pokeventure/data/models/battle.dart';
import 'package:pokeventure/data/models/move_entry.dart';
import 'package:pokeventure/data/models/pokemon_type.dart';
import 'package:pokeventure/data/type_chart.dart';
import 'package:pokeventure/features/battle/battle_arena_screen.dart';
import 'package:pokeventure/ui/widgets/pokemon_sprite.dart';

const _move = BattleMove(
  name: 'Earthquake',
  pp: 10,
  maxPp: 10,
  disabled: false,
);

const _active = BattleMember(
  slot: 1,
  species: 'Garchomp',
  level: 78,
  condition: '120/180',
  hp: 0.66,
  status: null,
  active: true,
  fainted: false,
  moves: [
    _move,
    BattleMove(name: 'Dragon Claw', pp: 15, maxPp: 15, disabled: false),
    BattleMove(name: 'Swords Dance', pp: 20, maxPp: 20, disabled: false),
    BattleMove(name: 'Stone Edge', pp: 5, maxPp: 5, disabled: true),
  ],
);

const _bench = BattleMember(
  slot: 2,
  species: 'Rotom-Wash',
  level: 76,
  condition: '0 fnt',
  hp: 0,
  status: null,
  active: false,
  fainted: true,
  moves: [],
);

final _snapshot = BattleSnapshot(
  id: 'battle-1',
  format: 'gen9randombattle',
  turn: 3,
  ended: false,
  winner: null,
  canAct: true,
  waiting: false,
  forceSwitch: false,
  playerName: 'Trainer',
  team: const [_active, _bench],
  active: _active,
  opponent: const BattleOpponent(
    species: 'Corviknight',
    level: 80,
    hp: 0.5,
    condition: '90/180',
    status: 'par',
    fainted: false,
  ),
  log: const [
    '|turn|3',
    '|move|p1a: Garchomp|Earthquake|p2a: Corviknight',
    '|-damage|p2a: Corviknight|90/180 par',
  ],
);

void main() {
  setUp(() {
    SpriteConfig.enabled = false;
  });

  group('prettifyBattleLogLine', () {
    test('formats moves, switches, damage and results', () {
      expect(
        prettifyBattleLogLine('|move|p1a: Garchomp|Earthquake|p2a: X'),
        'Garchomp used Earthquake!',
      );
      expect(
        prettifyBattleLogLine('|switch|p2a: Corviknight|Corviknight, L80|90/180'),
        'Foe sent out Corviknight.',
      );
      expect(
        prettifyBattleLogLine('|-damage|p1a: Garchomp|63/180'),
        'Garchomp took damage (63/180).',
      );
      expect(
        prettifyBattleLogLine('|faint|p2a: Corviknight'),
        "Foe's Corviknight fainted!",
      );
      expect(prettifyBattleLogLine('|win|Trainer'), 'You won the battle!');
    });

    test('skips turn ticks and unknown lines', () {
      expect(prettifyBattleLogLine('|turn|9'), isNull);
      expect(prettifyBattleLogLine('|upkeep'), isNull);
      expect(prettifyBattleLogLine('not protocol'), isNull);
    });
  });

  group('type chart', () {
    test('multiplies across dual types', () {
      expect(
        typeEffectiveness(PokemonType.fire, [
          PokemonType.grass,
          PokemonType.ice,
        ]),
        4,
      );
      expect(
        typeEffectiveness(PokemonType.water, [
          PokemonType.dragon,
          PokemonType.flying,
        ]),
        0.5,
      );
    });

    test('immunities are zero', () {
      expect(
        typeEffectiveness(PokemonType.electric, [PokemonType.ground]),
        0,
      );
      expect(typeEffectiveness(PokemonType.normal, [PokemonType.ghost]), 0);
    });

    test('labels fractions and multipliers', () {
      expect(effectivenessLabel(4), '4×');
      expect(effectivenessLabel(2), '2×');
      expect(effectivenessLabel(0.5), '½×');
      expect(effectivenessLabel(0.25), '¼×');
      expect(effectivenessLabel(0), '0×');
      expect(effectivenessLabel(1), '1×');
    });
  });

  test('move data parses type, category and accuracy', () {
    final entry = MoveEntry.fromJson({
      'name': 'Earthquake',
      'type': 'ground',
      'category': 'Physical',
      'power': 100,
      'accuracy': 100,
      'pp': 10,
      'priority': 0,
    });

    expect(entry.type, PokemonType.ground);
    expect(entry.power, 100);
    expect(entry.accuracy, 100);
    expect(entry.isStatus, isFalse);

    final status = MoveEntry.fromJson({
      'name': 'Swords Dance',
      'type': 'Normal',
      'category': 'Status',
      'power': null,
      'accuracy': null,
      'pp': 20,
    });
    expect(status.isStatus, isTrue);
    expect(status.accuracy, isNull);
  });

  test('battle API parses a snapshot', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/battles');
      return http.Response(
        jsonEncode({
          'id': 'abc',
          'format': 'gen9randombattle',
          'turn': 1,
          'ended': false,
          'winner': null,
          'canAct': true,
          'waiting': false,
          'forceSwitch': false,
          'player': {
            'name': 'Trainer',
            'team': [
              {
                'slot': 1,
                'species': 'Garchomp',
                'level': 78,
                'condition': '120/180',
                'hp': 0.66,
                'active': true,
                'fainted': false,
                'moves': [
                  {'name': 'Earthquake', 'pp': 10, 'maxPp': 10, 'disabled': false},
                ],
              },
            ],
          },
          'opponent': {
            'species': 'Corviknight',
            'level': 80,
            'hp': 0.5,
            'condition': '90/180',
            'fainted': false,
          },
          'log': ['|turn|1'],
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = BattleApi(baseUrl: 'http://test.local', client: client);
    final snapshot = await api.createBattle();

    expect(snapshot.id, 'abc');
    expect(snapshot.active?.species, 'Garchomp');
    expect(snapshot.opponent?.species, 'Corviknight');
    expect(snapshot.canAct, isTrue);
  });

  testWidgets('battle tab queues a server battle and opens the arena',
      (tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'id': 'live-1',
          'format': 'gen9randombattle',
          'turn': 1,
          'ended': false,
          'winner': null,
          'canAct': true,
          'waiting': false,
          'forceSwitch': false,
          'player': {
            'name': 'Trainer',
            'team': [
              {
                'slot': 1,
                'species': 'Garchomp',
                'level': 78,
                'condition': '180/180',
                'hp': 1.0,
                'active': true,
                'fainted': false,
                'moves': [
                  {
                    'name': 'Earthquake',
                    'pp': 10,
                    'maxPp': 10,
                    'disabled': false,
                  },
                ],
              },
            ],
          },
          'opponent': {
            'species': 'Corviknight',
            'level': 80,
            'hp': 1.0,
            'condition': '180/180',
            'fainted': false,
          },
          'log': ['|turn|1'],
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          battleApiProvider.overrideWithValue(
            BattleApi(baseUrl: 'http://test.local', client: client),
          ),
        ],
        child: const PokeventureApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.text('Battle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.textContaining('Battle AI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Corviknight'), findsOneWidget);
    expect(find.text('Earthquake'), findsOneWidget);
    expect(find.textContaining('Turn 1'), findsOneWidget);
  });

  testWidgets('arena renders both sides and the four moves', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: BattleArenaScreen(initial: _snapshot)),
      ),
    );
    await tester.pump();

    expect(find.text('Garchomp'), findsOneWidget);
    expect(find.text('Corviknight'), findsOneWidget);
    expect(find.text('Earthquake'), findsOneWidget);
    expect(find.text('Dragon Claw'), findsOneWidget);
    expect(find.text('Stone Edge'), findsOneWidget);
    expect(find.text('Garchomp used Earthquake!'), findsOneWidget);
    expect(find.text('Victory!'), findsNothing);
  });
}
