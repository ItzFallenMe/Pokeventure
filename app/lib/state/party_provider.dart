import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/item_catalog.dart';
import '../data/local/key_value_store.dart';
import '../data/mock_pokemon.dart';
import '../data/models/pokemon.dart';

const int kPartyLimit = 6;

class PartyState {
  const PartyState({
    required this.party,
    required this.box,
    required this.caught,
    required this.coins,
    required this.gems,
    required this.inventory,
  });

  final List<Pokemon> party;
  final List<Pokemon> box;
  final int caught;
  final int coins;
  final int gems;
  final Map<String, int> inventory;

  bool get hasSpace => party.length < kPartyLimit;

  int quantityOf(String slug) => inventory[slug] ?? 0;

  PartyState copyWith({
    List<Pokemon>? party,
    List<Pokemon>? box,
    int? caught,
    int? coins,
    int? gems,
    Map<String, int>? inventory,
  }) {
    return PartyState(
      party: party ?? this.party,
      box: box ?? this.box,
      caught: caught ?? this.caught,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      inventory: inventory ?? this.inventory,
    );
  }

  Map<String, dynamic> toJson() => {
        'party': party.map((p) => p.toJson()).toList(),
        'box': box.map((p) => p.toJson()).toList(),
        'caught': caught,
        'coins': coins,
        'gems': gems,
        'inventory': inventory,
      };

  factory PartyState.fromJson(Map<String, dynamic> json) {
    return PartyState(
      party: (json['party'] as List<dynamic>)
          .map((raw) => Pokemon.fromJson(raw as Map<String, dynamic>))
          .toList(),
      box: (json['box'] as List<dynamic>)
          .map((raw) => Pokemon.fromJson(raw as Map<String, dynamic>))
          .toList(),
      caught: json['caught'] as int,
      coins: json['coins'] as int,
      gems: json['gems'] as int,
      inventory: (json['inventory'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
  }
}

class PartyNotifier extends Notifier<PartyState> {
  static const _stateKey = 'party_state_v1';

  KeyValueStore get _store => ref.read(storeProvider);

  @override
  PartyState build() {
    final raw = _store.read(_stateKey);
    if (raw != null) {
      try {
        return PartyState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on Object {
        // Corrupt or older save: fall back to the demo state.
      }
    }
    return const PartyState(
      party: mockParty,
      box: mockBox,
      caught: 14,
      coins: 12480,
      gems: 240,
      inventory: demoInventory,
    );
  }

  void _commit(PartyState next) {
    state = next;
    unawaited(_store.write(_stateKey, jsonEncode(next.toJson())));
  }

  /// Reorders the party. [newIndex] is already adjusted for the removed item,
  /// matching [ReorderableListView.onReorderItem].
  void reorder(int oldIndex, int newIndex) {
    final length = state.party.length;
    if (oldIndex < 0 || oldIndex >= length) return;
    if (newIndex < 0) return;

    final target = newIndex.clamp(0, length - 1);
    if (target == oldIndex) return;

    final next = List.of(state.party);
    final item = next.removeAt(oldIndex);
    next.insert(target, item);
    _commit(state.copyWith(party: next));
  }

  /// Swaps a party member with a PC Pokémon, keeping the party at six.
  void swapWithBox(int partyIndex, String boxPokemonId) {
    if (partyIndex < 0 || partyIndex >= state.party.length) return;

    final nextParty = List.of(state.party);
    final nextBox = List.of(state.box);
    final boxIndex = nextBox.indexWhere((pokemon) => pokemon.id == boxPokemonId);
    if (boxIndex < 0) return;

    final incoming = nextBox.removeAt(boxIndex);
    final outgoing = nextParty[partyIndex];
    nextParty[partyIndex] = incoming;
    nextBox.insert(boxIndex, outgoing);

    _commit(state.copyWith(party: nextParty, box: nextBox));
  }

  void healAll() {
    _commit(
      state.copyWith(
        party: [
          for (final pokemon in state.party)
            pokemon.copyWith(currentHp: pokemon.maxHp),
        ],
      ),
    );
  }

  /// Adds a caught Pokémon to the party, or the PC when the party is full.
  /// Returns true when it went into the party.
  bool addCaught(Pokemon pokemon) {
    final nextParty = List.of(state.party);
    final nextBox = List.of(state.box);
    final joinedParty = nextParty.length < kPartyLimit;
    if (joinedParty) {
      nextParty.add(pokemon);
    } else {
      nextBox.add(pokemon);
    }
    _commit(
      state.copyWith(
        party: nextParty,
        box: nextBox,
        caught: state.caught + 1,
        coins: state.coins + 40,
      ),
    );
    return joinedParty;
  }

  bool buyItem(ItemDef item) {
    if (item.price <= 0 || state.coins < item.price) return false;

    final nextInventory = Map.of(state.inventory);
    nextInventory[item.slug] = (nextInventory[item.slug] ?? 0) + 1;
    _commit(
      state.copyWith(
        coins: state.coins - item.price,
        inventory: nextInventory,
      ),
    );
    return true;
  }

  bool spendCoins(int amount) {
    if (amount <= 0 || state.coins < amount) return false;
    _commit(state.copyWith(coins: state.coins - amount));
    return true;
  }

  /// Clears the local save and restores the demo state.
  void resetProgress() {
    unawaited(_store.delete(_stateKey));
    state = const PartyState(
      party: mockParty,
      box: mockBox,
      caught: 14,
      coins: 12480,
      gems: 240,
      inventory: demoInventory,
    );
  }
}

final partyProvider = NotifierProvider<PartyNotifier, PartyState>(
  PartyNotifier.new,
);
