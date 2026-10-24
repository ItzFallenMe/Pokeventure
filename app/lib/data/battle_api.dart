import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'models/battle.dart';

class BattleApiException implements Exception {
  const BattleApiException(this.message);

  final String message;

  @override
  String toString() => 'BattleApiException: $message';
}

class BattleApi {
  BattleApi({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  static String get defaultBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator reaches the host machine through 10.0.2.2.
      return 'http://10.0.2.2:8787';
    }
    return 'http://127.0.0.1:8787';
  }

  final String baseUrl;
  final http.Client _client;

  Future<BattleSnapshot> createBattle({
    String format = 'gen9randombattle',
  }) async {
    final response = await _post('/api/battles', {'format': format});
    return BattleSnapshot.fromJson(response);
  }

  Future<BattleSnapshot> choose(String battleId, String choice) async {
    final response = await _post(
      '/api/battles/$battleId/choice',
      {'choice': choice},
    );
    return BattleSnapshot.fromJson(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on Object catch (error) {
      throw BattleApiException(
        'Could not reach the battle server at $baseUrl.\n$error',
      );
    }

    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['error'] as String? ?? 'request_failed';
      throw BattleApiException(message);
    }
    return decoded;
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map<String, dynamic>) return value;
    } on FormatException {
      // Fall through to the shared error below.
    }
    throw BattleApiException('The battle server returned an invalid response.');
  }
}

final battleApiProvider = Provider<BattleApi>((ref) => BattleApi());
