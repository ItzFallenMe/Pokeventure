import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'battle_api.dart';
import 'models/battle.dart';

class FriendBattleInvite {
  const FriendBattleInvite({
    required this.id,
    required this.code,
    required this.token,
  });

  final String id;
  final String code;
  final String token;
}

class FriendBattleUpdate {
  const FriendBattleUpdate({
    required this.waiting,
    this.snapshot,
    this.code,
    this.token,
    this.id,
  });

  final bool waiting;
  final BattleSnapshot? snapshot;
  final String? code;
  final String? token;
  final String? id;
}

class FriendBattleConnection {
  const FriendBattleConnection({
    required this.api,
    required this.id,
    required this.token,
  });

  final FriendBattleApi api;
  final String id;
  final String token;

  Future<BattleSnapshot> choose(String choice) =>
      api.choose(id: id, token: token, choice: choice);

  Future<BattleSnapshot> refresh() async {
    final update = await api.poll(id: id, token: token);
    final snapshot = update.snapshot;
    if (snapshot == null) {
      throw const BattleApiException('The battle is not ready yet.');
    }
    return snapshot;
  }
}

class FriendBattleApi {
  FriendBattleApi({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? BattleApi.defaultBaseUrl,
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers([String? token]) => {
    'content-type': 'application/json',
    'x-battle-token': ?token,
  };

  Future<FriendBattleInvite> create({
    required String name,
    String format = 'gen9randombattle',
  }) async {
    final body = await _send(
      'POST',
      '/api/friend-battles',
      body: {'format': format, 'name': name},
    );
    return FriendBattleInvite(
      id: body['id'] as String,
      code: body['code'] as String,
      token: body['token'] as String,
    );
  }

  Future<FriendBattleUpdate> join({
    required String code,
    required String name,
  }) async {
    final body = await _send(
      'POST',
      '/api/friend-battles/join',
      body: {'code': code.trim().toUpperCase(), 'name': name},
    );
    return FriendBattleUpdate(
      waiting: body['status'] != 'active',
      snapshot: body['snapshot'] is Map<String, dynamic>
          ? BattleSnapshot.fromJson(body['snapshot'] as Map<String, dynamic>)
          : null,
      code: body['code'] as String?,
      token: body['token'] as String?,
      id: body['id'] as String?,
    );
  }

  Future<FriendBattleUpdate> poll({
    required String id,
    required String token,
  }) async {
    final body = await _send('GET', '/api/friend-battles/$id', token: token);
    return FriendBattleUpdate(
      waiting: body['status'] != 'active',
      snapshot: body['snapshot'] is Map<String, dynamic>
          ? BattleSnapshot.fromJson(body['snapshot'] as Map<String, dynamic>)
          : null,
      code: body['code'] as String?,
    );
  }

  Future<BattleSnapshot> choose({
    required String id,
    required String token,
    required String choice,
  }) async {
    final body = await _send(
      'POST',
      '/api/friend-battles/$id/choice',
      token: token,
      body: {'choice': choice},
    );
    final snapshot = body['snapshot'];
    if (snapshot is! Map<String, dynamic>) {
      throw const BattleApiException('The battle did not return a snapshot.');
    }
    return BattleSnapshot.fromJson(snapshot);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late final http.Response response;

    try {
      response = switch (method) {
        'GET' => await _client.get(uri, headers: _headers(token)),
        _ => await _client.post(
          uri,
          headers: _headers(token),
          body: jsonEncode(body ?? const {}),
        ),
      };
    } catch (error) {
      throw BattleApiException('Cannot reach the battle server ($error).');
    }

    Map<String, dynamic> decoded = const {};
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw const BattleApiException('The server returned an invalid reply.');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded['message'] ?? decoded['error'] ?? 'request failed';
      throw BattleApiException(message.toString());
    }
    return decoded;
  }
}

final friendBattleApiProvider = Provider<FriendBattleApi>(
  (ref) => FriendBattleApi(),
);
