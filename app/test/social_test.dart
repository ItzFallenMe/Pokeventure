import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokeventure/data/friend_battle_api.dart';
import 'package:pokeventure/data/models/battle.dart';
import 'package:pokeventure/data/social/social_models.dart';
import 'package:pokeventure/data/social/social_repository.dart';
import 'package:pokeventure/features/battle/battle_arena_screen.dart';
import 'package:pokeventure/features/social/qr_payload.dart';
import 'package:pokeventure/features/social/social_screen.dart';
import 'package:pokeventure/ui/widgets/pokemon_sprite.dart';
import 'package:qr_flutter/qr_flutter.dart';

final _me = TrainerProfile(
  id: 'me',
  name: 'Aria',
  friendCode: 'ABC123',
  lastSeen: DateTime.now(),
);

final _kai = TrainerProfile(
  id: 'kai',
  name: 'Kai',
  friendCode: 'DEF456',
  lastSeen: DateTime.now(),
);

final _nova = TrainerProfile(
  id: 'nova',
  name: 'Nova',
  friendCode: 'GHI789',
  lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
);

class FakeSocialRepository implements SocialRepository {
  FakeSocialRepository(this.snapshot);

  SocialSnapshot snapshot;
  final calls = <String>[];

  @override
  bool get isAvailable => true;

  @override
  Future<SocialSnapshot> load() async {
    calls.add('load');
    return snapshot;
  }

  @override
  Future<TrainerProfile> rename(String name) async {
    calls.add('rename:$name');
    snapshot = SocialSnapshot(
      me: snapshot.me.copyWith(name: name),
      friends: snapshot.friends,
      incoming: snapshot.incoming,
      outgoing: snapshot.outgoing,
    );
    return snapshot.me;
  }

  @override
  Future<void> sendRequest(String friendCode) async {
    calls.add('request:$friendCode');
  }

  @override
  Future<void> accept(String friendshipId) async {
    calls.add('accept:$friendshipId');
    final request = snapshot.incoming.firstWhere(
      (item) => item.id == friendshipId,
    );
    snapshot = SocialSnapshot(
      me: snapshot.me,
      friends: [
        ...snapshot.friends,
        Friendship(
          id: friendshipId,
          friend: request.friend,
          status: FriendshipStatus.accepted,
          outgoing: false,
        ),
      ],
      incoming: snapshot.incoming
          .where((item) => item.id != friendshipId)
          .toList(),
      outgoing: snapshot.outgoing,
    );
  }

  @override
  Future<void> decline(String friendshipId) async {
    calls.add('decline:$friendshipId');
    snapshot = SocialSnapshot(
      me: snapshot.me,
      friends: snapshot.friends,
      incoming: snapshot.incoming
          .where((item) => item.id != friendshipId)
          .toList(),
      outgoing: snapshot.outgoing
          .where((item) => item.id != friendshipId)
          .toList(),
    );
  }

  @override
  Future<void> remove(String friendshipId) async {
    calls.add('remove:$friendshipId');
  }
}

Widget _app(SocialRepository repository) {
  return ProviderScope(
    overrides: [socialRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: Scaffold(body: SocialScreen())),
  );
}

Future<void> _pumpSocial(
  WidgetTester tester,
  FakeSocialRepository repository,
) async {
  await tester.pumpWidget(_app(repository));
  await tester.pumpAndSettle();
}

void main() {
  test('QR payloads round-trip friend and battle codes', () {
    final friend = parseQrPayload(friendQrPayload('ABC123'));
    expect(friend?.kind, QrKind.friend);
    expect(friend?.code, 'ABC123');

    final battle = parseQrPayload(battleQrPayload('xyz789'));
    expect(battle?.kind, QrKind.battle);
    expect(battle?.code, 'XYZ789');

    final bare = parseQrPayload(' QWE456 ');
    expect(bare?.kind, QrKind.friend);
    expect(bare?.code, 'QWE456');

    expect(parseQrPayload('https://example.com'), isNull);
    expect(parseQrPayload(''), isNull);
  });

  test('friend battle API uses invite codes and tokens', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);

      if (request.url.path == '/api/friend-battles') {
        return http.Response(
          jsonEncode({
            'id': 'lobby-1',
            'code': 'ABC123',
            'side': 'p1',
            'token': 'host-token',
            'status': 'waiting',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.url.path == '/api/friend-battles/join') {
        return http.Response(
          jsonEncode({
            'id': 'lobby-1',
            'side': 'p2',
            'token': 'guest-token',
            'status': 'active',
            'snapshot': _snapshotJson(),
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.url.path.endsWith('/choice')) {
        expect(request.headers['x-battle-token'], 'host-token');
        return http.Response(
          jsonEncode({
            'id': 'lobby-1',
            'side': 'p1',
            'status': 'active',
            'snapshot': _snapshotJson(),
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(
        jsonEncode({'id': 'lobby-1', 'side': 'p1', 'status': 'waiting'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = FriendBattleApi(baseUrl: 'http://test.local', client: client);

    final invite = await api.create(name: 'Aria');
    expect(invite.code, 'ABC123');
    expect(invite.token, 'host-token');
    expect(requests.first.url.path, '/api/friend-battles');
    expect(jsonDecode(requests.first.body), containsPair('name', 'Aria'));

    final joined = await api.join(code: 'abc123', name: 'Kai');
    expect(joined.waiting, isFalse);
    expect(joined.token, 'guest-token');
    expect(joined.snapshot?.active?.species, 'Garchomp');
    expect(requests[1].headers['content-type'], contains('application/json'));

    final waiting = await api.poll(id: 'lobby-1', token: 'host-token');
    expect(waiting.waiting, isTrue);
    expect(requests[2].headers['x-battle-token'], 'host-token');

    final chosen = await api.choose(
      id: 'lobby-1',
      token: 'host-token',
      choice: 'move 1',
    );
    expect(chosen.turn, 3);
  });

  testWidgets('social screen shows the trainer, friends and requests', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      SocialSnapshot(
        me: _me,
        friends: [
          Friendship(
            id: 'f1',
            friend: _kai,
            status: FriendshipStatus.accepted,
            outgoing: false,
          ),
        ],
        incoming: [
          Friendship(
            id: 'r1',
            friend: _nova,
            status: FriendshipStatus.pending,
            outgoing: false,
          ),
        ],
      ),
    );

    await _pumpSocial(tester, repository);

    expect(find.text('Aria'), findsOneWidget);
    expect(find.textContaining('ABC123'), findsWidgets);
    expect(find.text('Kai'), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);
    expect(find.text('Requests for you'.toUpperCase()), findsOneWidget);
    expect(find.textContaining('Online now'), findsOneWidget);
  });

  testWidgets('accepting a request turns it into a friend', (tester) async {
    final repository = FakeSocialRepository(
      SocialSnapshot(
        me: _me,
        incoming: [
          Friendship(
            id: 'r1',
            friend: _nova,
            status: FriendshipStatus.pending,
            outgoing: false,
          ),
        ],
      ),
    );

    await _pumpSocial(tester, repository);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('accept:r1'));
    expect(find.text('Requests for you'.toUpperCase()), findsNothing);
    expect(find.text('Nova'), findsOneWidget);
  });

  testWidgets('adding a friend by code sends the request', (tester) async {
    final repository = FakeSocialRepository(SocialSnapshot(me: _me));

    await _pumpSocial(tester, repository);
    await tester.tap(find.text('Add friend'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'def456');
    await tester.pump();
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('request:DEF456'));
  });

  testWidgets('friend battle arena polls for the friend move', (tester) async {
    SpriteConfig.enabled = false;
    var polls = 0;

    final api = FriendBattleApi(
      baseUrl: 'http://test.local',
      client: MockClient((request) async {
        polls += 1;
        expect(request.headers['x-battle-token'], 'token-1');
        return http.Response(
          jsonEncode({
            'id': 'lobby-1',
            'side': 'p1',
            'status': 'active',
            'snapshot': _snapshotJson(turn: 4, canAct: false, waiting: true),
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: BattleArenaScreen(
            initial: BattleSnapshot.fromJson(_snapshotJson()),
            friend: FriendBattleConnection(
              api: api,
              id: 'lobby-1',
              token: 'token-1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Turn 3'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    expect(polls, greaterThan(0));
    expect(find.textContaining('Turn 4'), findsOneWidget);
    expect(find.text('Waiting for the opponent…'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the trainer QR sheet renders a scannable code', (tester) async {
    final repository = FakeSocialRepository(SocialSnapshot(me: _me));

    await _pumpSocial(tester, repository);
    await tester.tap(find.text('Show my QR'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('Code copied'), findsNothing);
  });
}

Map<String, dynamic> _snapshotJson({
  int turn = 3,
  bool canAct = true,
  bool waiting = false,
}) => {
  'id': 'lobby-1',
  'format': 'gen9randombattle',
  'turn': turn,
  'ended': false,
  'winner': null,
  'canAct': canAct,
  'waiting': waiting,
  'forceSwitch': false,
  'player': {
    'name': 'Aria',
    'team': [
      {
        'slot': 1,
        'species': 'Garchomp',
        'level': 78,
        'condition': '120/180',
        'hp': 0.66,
        'status': null,
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
    'status': null,
    'fainted': false,
  },
  'log': ['|turn|3'],
};
