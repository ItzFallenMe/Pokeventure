import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/party_provider.dart';
import 'models/dex_entry.dart';
import 'models/move_entry.dart';

/// Loads the generated snapshot from `assets/data/dex.json`.
final dexProvider = FutureProvider<List<DexEntry>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/dex.json');
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((entry) => DexEntry.fromJson(entry as Map<String, dynamic>))
      .toList(growable: false);
});

/// Loads move data from `assets/data/moves.json`.
final moveLookupProvider = FutureProvider<Map<String, MoveEntry>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/moves.json');
  final decoded = jsonDecode(raw) as List<dynamic>;
  return {
    for (final entry in decoded)
      (entry as Map<String, dynamic>)['name'].toString().toLowerCase():
          MoveEntry.fromJson(entry),
  };
});

/// Species name (lowercase) → entry, for battle sprites and types.
final dexLookupProvider = FutureProvider<Map<String, DexEntry>>((ref) async {
  final entries = await ref.watch(dexProvider.future);
  return {
    for (final entry in entries) entry.name.toLowerCase(): entry,
  };
});

/// Species numbers currently in the party or the PC.
final ownedDexProvider = Provider<Set<int>>((ref) {
  final state = ref.watch(partyProvider);
  return {
    for (final pokemon in [...state.party, ...state.box]) pokemon.dexNumber,
  };
});
