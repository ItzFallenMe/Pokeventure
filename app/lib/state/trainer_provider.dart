import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dex_repository.dart';
import '../data/game/catch.dart';
import '../data/game/quests.dart';
import '../data/game/stats.dart';
import '../data/game/wild.dart';
import '../data/item_catalog.dart';
import '../data/local/key_value_store.dart';
import '../data/models/dex_entry.dart';
import '../data/models/pokemon.dart';
import '../data/models/pokemon_type.dart';

const int kPartyLimit = 6;

class TrainerCounters {
  const TrainerCounters({
    this.catches = 0,
    this.newSpecies = 0,
    this.greatBallCatches = 0,
    this.battles = 0,
    this.wins = 0,
    this.typeCatches = const {},
  });

  factory TrainerCounters.fromJson(Map<String, dynamic> json) {
    return TrainerCounters(
      catches: (json['catches'] as num?)?.toInt() ?? 0,
      newSpecies: (json['newSpecies'] as num?)?.toInt() ?? 0,
      greatBallCatches: (json['greatBallCatches'] as num?)?.toInt() ?? 0,
      battles: (json['battles'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      typeCatches: ((json['typeCatches'] as Map<String, dynamic>?) ?? const {})
          .map((key, value) => MapEntry(key, (value as num).toInt())),
    );
  }

  final int catches;
  final int newSpecies;
  final int greatBallCatches;
  final int battles;
  final int wins;
  final Map<String, int> typeCatches;

  Map<String, dynamic> toJson() => {
    'catches': catches,
    'newSpecies': newSpecies,
    'greatBallCatches': greatBallCatches,
    'battles': battles,
    'wins': wins,
    'typeCatches': typeCatches,
  };

  TrainerCounters copyWith({
    int? catches,
    int? newSpecies,
    int? greatBallCatches,
    int? battles,
    int? wins,
    Map<String, int>? typeCatches,
  }) {
    return TrainerCounters(
      catches: catches ?? this.catches,
      newSpecies: newSpecies ?? this.newSpecies,
      greatBallCatches: greatBallCatches ?? this.greatBallCatches,
      battles: battles ?? this.battles,
      wins: wins ?? this.wins,
      typeCatches: typeCatches ?? this.typeCatches,
    );
  }
}

class TrainerState {
  const TrainerState({
    required this.started,
    required this.name,
    required this.xp,
    required this.coins,
    required this.gems,
    required this.party,
    required this.box,
    required this.seen,
    required this.caught,
    required this.inventory,
    required this.quests,
    required this.questDay,
    required this.streak,
    required this.lastActiveDay,
    required this.dailyGiftClaimed,
    required this.counters,
    required this.totalCatches,
    required this.totalBattles,
    required this.totalWins,
    required this.createdAt,
  });

  factory TrainerState.newTrainer() {
    return const TrainerState(
      started: false,
      name: '',
      xp: 0,
      coins: 0,
      gems: 0,
      party: [],
      box: [],
      seen: {},
      caught: {},
      inventory: {},
      quests: [],
      questDay: '',
      streak: 0,
      lastActiveDay: '',
      dailyGiftClaimed: false,
      counters: TrainerCounters(),
      totalCatches: 0,
      totalBattles: 0,
      totalWins: 0,
      createdAt: null,
    );
  }

  final bool started;
  final String name;
  final int xp;
  final int coins;
  final int gems;
  final List<Pokemon> party;
  final List<Pokemon> box;
  final Set<int> seen;
  final Set<int> caught;
  final Map<String, int> inventory;
  final List<DailyQuest> quests;
  final String questDay;
  final int streak;
  final String lastActiveDay;
  final bool dailyGiftClaimed;
  final TrainerCounters counters;
  final int totalCatches;
  final int totalBattles;
  final int totalWins;
  final DateTime? createdAt;

  int get level => trainerLevelForXp(xp);

  double get levelProgress => trainerXpProgress(xp, level);

  bool get hasSpace => party.length < kPartyLimit;

  int get caughtCount => caught.length;

  int get shinyCount => [...party, ...box].where((p) => p.shiny).length;

  int get itemCount => inventory.values.fold(0, (sum, count) => sum + count);

  int get claimableQuests => quests.where((quest) => quest.isClaimable).length;

  double get dexProgress => caught.length / 1025;

  int quantityOf(String slug) => inventory[slug] ?? 0;

  Pokemon? pokemonById(String id) {
    for (final pokemon in party) {
      if (pokemon.id == id) return pokemon;
    }
    for (final pokemon in box) {
      if (pokemon.id == id) return pokemon;
    }
    return null;
  }

  TrainerState copyWith({
    bool? started,
    String? name,
    int? xp,
    int? coins,
    int? gems,
    List<Pokemon>? party,
    List<Pokemon>? box,
    Set<int>? seen,
    Set<int>? caught,
    Map<String, int>? inventory,
    List<DailyQuest>? quests,
    String? questDay,
    int? streak,
    String? lastActiveDay,
    bool? dailyGiftClaimed,
    TrainerCounters? counters,
    int? totalCatches,
    int? totalBattles,
    int? totalWins,
    DateTime? createdAt,
  }) {
    return TrainerState(
      started: started ?? this.started,
      name: name ?? this.name,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      party: party ?? this.party,
      box: box ?? this.box,
      seen: seen ?? this.seen,
      caught: caught ?? this.caught,
      inventory: inventory ?? this.inventory,
      quests: quests ?? this.quests,
      questDay: questDay ?? this.questDay,
      streak: streak ?? this.streak,
      lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      dailyGiftClaimed: dailyGiftClaimed ?? this.dailyGiftClaimed,
      counters: counters ?? this.counters,
      totalCatches: totalCatches ?? this.totalCatches,
      totalBattles: totalBattles ?? this.totalBattles,
      totalWins: totalWins ?? this.totalWins,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 3,
    'started': started,
    'name': name,
    'xp': xp,
    'coins': coins,
    'gems': gems,
    'party': party.map((p) => p.toJson()).toList(),
    'box': box.map((p) => p.toJson()).toList(),
    'seen': seen.toList(),
    'caught': caught.toList(),
    'inventory': inventory,
    'quests': quests.map((q) => q.toJson()).toList(),
    'questDay': questDay,
    'streak': streak,
    'lastActiveDay': lastActiveDay,
    'dailyGiftClaimed': dailyGiftClaimed,
    'counters': counters.toJson(),
    'totalCatches': totalCatches,
    'totalBattles': totalBattles,
    'totalWins': totalWins,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory TrainerState.fromJson(Map<String, dynamic> json) {
    return TrainerState(
      started: json['started'] as bool? ?? false,
      name: json['name'] as String? ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      party: ((json['party'] as List<dynamic>?) ?? const [])
          .map((raw) => Pokemon.fromJson(raw as Map<String, dynamic>))
          .toList(),
      box: ((json['box'] as List<dynamic>?) ?? const [])
          .map((raw) => Pokemon.fromJson(raw as Map<String, dynamic>))
          .toList(),
      seen: ((json['seen'] as List<dynamic>?) ?? const [])
          .map((raw) => (raw as num).toInt())
          .toSet(),
      caught: ((json['caught'] as List<dynamic>?) ?? const [])
          .map((raw) => (raw as num).toInt())
          .toSet(),
      inventory: ((json['inventory'] as Map<String, dynamic>?) ?? const {}).map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      quests: ((json['quests'] as List<dynamic>?) ?? const [])
          .map((raw) => DailyQuest.fromJson(raw as Map<String, dynamic>))
          .toList(),
      questDay: json['questDay'] as String? ?? '',
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastActiveDay: json['lastActiveDay'] as String? ?? '',
      dailyGiftClaimed: json['dailyGiftClaimed'] as bool? ?? false,
      counters: TrainerCounters.fromJson(
        (json['counters'] as Map<String, dynamic>?) ?? const {},
      ),
      totalCatches: (json['totalCatches'] as num?)?.toInt() ?? 0,
      totalBattles: (json['totalBattles'] as num?)?.toInt() ?? 0,
      totalWins: (json['totalWins'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }
}

class CatchReport {
  const CatchReport({
    required this.pokemon,
    required this.joinedParty,
    required this.newSpecies,
    required this.coins,
    required this.trainerXp,
    this.learnedMoves = const [],
    this.evolvedInto,
  });

  final Pokemon pokemon;
  final bool joinedParty;
  final bool newSpecies;
  final int coins;
  final int trainerXp;
  final List<String> learnedMoves;
  final DexEntry? evolvedInto;
}

class LevelUpReport {
  const LevelUpReport({
    required this.pokemon,
    required this.levelsGained,
    this.learnedMoves = const [],
    this.evolvedInto,
  });

  final Pokemon pokemon;
  final int levelsGained;
  final List<String> learnedMoves;
  final DexEntry? evolvedInto;
}

class TrainerNotifier extends Notifier<TrainerState> {
  static const _stateKey = 'trainer_state_v3';

  KeyValueStore get _store => ref.read(storeProvider);

  @override
  TrainerState build() {
    final raw = _store.read(_stateKey);
    if (raw == null) return TrainerState.newTrainer();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return _ensureDaily(TrainerState.fromJson(decoded));
    } on Object {
      return TrainerState.newTrainer();
    }
  }

  void _commit(TrainerState next) {
    state = next;
    unawaited(_store.write(_stateKey, jsonEncode(next.toJson())));
  }

  /// Resets counters and rolls new quests when the calendar day changes.
  TrainerState _ensureDaily(TrainerState current, {DateTime? now}) {
    if (!current.started) return current;
    final today = dayKeyString(now ?? DateTime.now());
    if (current.questDay == today) return current;

    final yesterday = dayKeyString(
      (now ?? DateTime.now()).subtract(const Duration(days: 1)),
    );
    final streak = current.lastActiveDay == yesterday ? current.streak + 1 : 1;
    return current.copyWith(
      quests: generateDailyQuests(now ?? DateTime.now()),
      questDay: today,
      lastActiveDay: today,
      streak: streak,
      dailyGiftClaimed: false,
      counters: const TrainerCounters(),
    );
  }

  void refreshDaily() {
    final next = _ensureDaily(state);
    if (!identical(next, state)) _commit(next);
  }

  void startJourney({
    required String name,
    required DexEntry starter,
    Random? random,
  }) {
    final now = DateTime.now();
    final partner = createStarter(starter, random: random);
    final trimmed = name.trim();
    _commit(
      TrainerState(
        started: true,
        name: trimmed.isEmpty ? 'Trainer' : trimmed,
        xp: 0,
        coins: 600,
        gems: 20,
        party: [partner],
        box: const [],
        seen: {starter.number},
        caught: {starter.number},
        inventory: const {
          'poke_ball': 20,
          'great_ball': 5,
          'ultra_ball': 1,
          'potion': 3,
          'revive': 1,
          'razz_berry': 3,
        },
        quests: generateDailyQuests(now),
        questDay: dayKeyString(now),
        streak: 1,
        lastActiveDay: dayKeyString(now),
        dailyGiftClaimed: false,
        counters: const TrainerCounters(),
        totalCatches: 1,
        totalBattles: 0,
        totalWins: 0,
        createdAt: now,
      ),
    );
  }

  void rename(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _commit(state.copyWith(name: trimmed));
  }

  bool buyItem(ItemDef item, {int quantity = 1}) {
    if (item.price <= 0 || quantity <= 0) return false;
    final cost = item.price * quantity;
    if (state.coins < cost) return false;

    final nextInventory = Map.of(state.inventory);
    nextInventory[item.slug] = (nextInventory[item.slug] ?? 0) + quantity;
    _commit(
      _ensureDaily(
        state,
      ).copyWith(coins: state.coins - cost, inventory: nextInventory),
    );
    return true;
  }

  bool consumeItem(String slug, {int quantity = 1}) {
    if (quantity <= 0) return false;
    final have = state.quantityOf(slug);
    if (have < quantity) return false;

    final nextInventory = Map.of(state.inventory);
    final left = have - quantity;
    if (left <= 0) {
      nextInventory.remove(slug);
    } else {
      nextInventory[slug] = left;
    }
    _commit(state.copyWith(inventory: nextInventory));
    return true;
  }

  void addItem(String slug, int quantity) {
    if (quantity <= 0) return;
    final nextInventory = Map.of(state.inventory);
    nextInventory[slug] = (nextInventory[slug] ?? 0) + quantity;
    _commit(state.copyWith(inventory: nextInventory));
  }

  /// Consumes a ball for a throw. Returns false when the bag is empty.
  bool consumeBall(String slug) => consumeItem(slug);

  CatchReport recordCatch({
    required Pokemon pokemon,
    required String ball,
    required String zone,
    required String rarity,
    Random? random,
  }) {
    var current = _ensureDaily(state);
    final newSpecies = !current.caught.contains(pokemon.dexNumber);

    final caughtPokemon = pokemon.copyWith(
      ball: ball,
      metZone: zone,
      caughtAt: DateTime.now(),
    );
    final joinedParty = current.party.length < kPartyLimit;
    final nextParty = List<Pokemon>.of(current.party);
    final nextBox = List<Pokemon>.of(current.box);
    if (joinedParty) {
      nextParty.add(caughtPokemon);
    } else {
      nextBox.add(caughtPokemon);
    }

    final coins = coinsFromCatch(level: pokemon.level, newSpecies: newSpecies);
    final trainerXp = 12 + (pokemon.level * 2) + (newSpecies ? 25 : 0);
    final counters = current.counters.copyWith(
      catches: current.counters.catches + 1,
      newSpecies: current.counters.newSpecies + (newSpecies ? 1 : 0),
      greatBallCatches:
          current.counters.greatBallCatches +
          (ball == 'Great Ball' || ball == 'Ultra Ball' ? 1 : 0),
      typeCatches: {
        ...current.counters.typeCatches,
        for (final type in pokemon.types)
          type.name: (current.counters.typeCatches[type.name] ?? 0) + 1,
      },
    );

    current = current.copyWith(
      party: nextParty,
      box: nextBox,
      seen: {...current.seen, pokemon.dexNumber},
      caught: {...current.caught, pokemon.dexNumber},
      coins: current.coins + coins,
      xp: current.xp + trainerXp,
      counters: counters,
      totalCatches: current.totalCatches + 1,
      quests: _progressQuests(
        current.quests,
        kind: QuestKind.catchAny,
        amount: 1,
      ),
    );
    current = current.copyWith(
      quests: _progressQuests(
        current.quests,
        kind: QuestKind.catchType,
        type: pokemon.types.isEmpty ? null : pokemon.types.first,
        amount: 1,
      ),
    );
    if (newSpecies) {
      current = current.copyWith(
        quests: _progressQuests(
          current.quests,
          kind: QuestKind.catchNew,
          amount: 1,
        ),
      );
    }
    if (ball == 'Great Ball' || ball == 'Ultra Ball' || ball == 'Net Ball') {
      current = current.copyWith(
        quests: _progressQuests(
          current.quests,
          kind: QuestKind.greatBall,
          amount: 1,
        ),
      );
    }

    // A catch also feeds the caught Pokémon, which can level it up on the spot.
    final grown = _grantXp(
      caughtPokemon,
      xpFromCatch(
        baseExp: _speciesBaseExp(caughtPokemon.dexNumber, pokemon.level),
        level: pokemon.level,
      ),
    );
    current = _replacePokemon(current, grown.pokemon);
    current = _registerEvolution(current, grown.evolvedInto);

    _commit(current);
    return CatchReport(
      pokemon: grown.pokemon,
      joinedParty: joinedParty,
      newSpecies: newSpecies,
      coins: coins,
      trainerXp: trainerXp,
      learnedMoves: grown.learnedMoves,
      evolvedInto: grown.evolvedInto,
    );
  }

  int _speciesBaseExp(int dexNumber, int level) {
    final catalog = ref.read(dexCatalogProvider);
    return catalog.speciesAt(dexNumber)?.baseExp ?? 50;
  }

  void gainBattleRewards({required bool won}) {
    var current = _ensureDaily(state);
    final counters = current.counters.copyWith(
      battles: current.counters.battles + 1,
      wins: current.counters.wins + (won ? 1 : 0),
    );
    current = current.copyWith(
      coins: current.coins + (won ? 180 : 40),
      xp: current.xp + (won ? 140 : 30),
      counters: counters,
      totalBattles: current.totalBattles + 1,
      totalWins: current.totalWins + (won ? 1 : 0),
    );
    if (won) {
      current = current.copyWith(
        quests: _progressQuests(
          current.quests,
          kind: QuestKind.winBattle,
          amount: 1,
        ),
      );
    }
    _commit(current);
  }

  bool claimQuest(String id) {
    final current = _ensureDaily(state);
    final index = current.quests.indexWhere((quest) => quest.id == id);
    if (index < 0) return false;
    final quest = current.quests[index];
    if (!quest.isClaimable) return false;

    final quests = List<DailyQuest>.of(current.quests);
    quests[index] = quest.copyWith(claimed: true);
    final inventory = Map.of(current.inventory);
    if (quest.rewardItemSlug != null && quest.rewardItemQuantity > 0) {
      inventory[quest.rewardItemSlug!] =
          (inventory[quest.rewardItemSlug!] ?? 0) + quest.rewardItemQuantity;
    }

    _commit(
      current.copyWith(
        quests: quests,
        coins: current.coins + quest.rewardCoins,
        inventory: inventory,
      ),
    );
    return true;
  }

  bool claimDailyGift() {
    final current = _ensureDaily(state);
    if (current.dailyGiftClaimed) return false;
    final inventory = Map.of(current.inventory);
    inventory['poke_ball'] = (inventory['poke_ball'] ?? 0) + 5;
    _commit(
      current.copyWith(
        dailyGiftClaimed: true,
        coins: current.coins + 100 + current.streak * 10,
        inventory: inventory,
      ),
    );
    return true;
  }

  bool healParty() {
    final current = _ensureDaily(state);
    var healed = false;
    final party = <Pokemon>[];
    for (final pokemon in current.party) {
      if (pokemon.currentHp < pokemon.maxHp) {
        healed = true;
        party.add(pokemon.copyWith(currentHp: pokemon.maxHp));
      } else {
        party.add(pokemon);
      }
    }
    if (!healed) return false;
    _commit(current.copyWith(party: party));
    return true;
  }

  /// Uses a consumable on a specific Pokémon. Returns a short status message,
  /// or null when the item cannot be used.
  String? useItem(String slug, String pokemonId) {
    final item = itemBySlug(slug);
    final target = state.pokemonById(pokemonId);
    if (item == null || target == null) return null;
    if (state.quantityOf(slug) <= 0) {
      return 'No ${item.name} left in the bag.';
    }

    var updated = target;
    var evolved = false;
    String? message;
    switch (slug) {
      case 'potion':
        if (target.isFainted || target.currentHp >= target.maxHp) return null;
        updated = target.copyWith(
          currentHp: min(target.maxHp, target.currentHp + 20),
        );
        message = '${target.displayName} recovered 20 HP.';
      case 'super_potion':
        if (target.isFainted || target.currentHp >= target.maxHp) return null;
        updated = target.copyWith(
          currentHp: min(target.maxHp, target.currentHp + 60),
        );
        message = '${target.displayName} recovered 60 HP.';
      case 'hyper_potion':
        if (target.isFainted || target.currentHp >= target.maxHp) return null;
        updated = target.copyWith(
          currentHp: min(target.maxHp, target.currentHp + 120),
        );
        message = '${target.displayName} recovered 120 HP.';
      case 'full_restore':
        if (target.currentHp >= target.maxHp) return null;
        updated = target.copyWith(currentHp: target.maxHp);
        message = '${target.displayName} was fully restored.';
      case 'revive':
        if (!target.isFainted) return null;
        updated = target.copyWith(currentHp: target.maxHp ~/ 2);
        message = '${target.displayName} is back on their feet.';
      case 'rare_candy':
        final report = _grantLevels(target, 1);
        updated = report.pokemon;
        evolved = report.evolvedInto != null;
        message = '${target.displayName} reached level ${updated.level}.';
      case 'exp_candy_l':
        final report = _grantXp(target, 500);
        updated = report.pokemon;
        evolved = report.evolvedInto != null;
        message = report.levelsGained > 0
            ? '${target.displayName} reached level ${updated.level}.'
            : '${target.displayName} gained 500 EXP.';
      default:
        return null;
    }

    var current = _replacePokemon(state, updated);
    if (evolved) {
      current = _registerEvolution(current, _evolutionFor(target, updated));
    }
    final inventory = Map.of(current.inventory);
    final left = (inventory[slug] ?? 0) - 1;
    if (left <= 0) {
      inventory.remove(slug);
    } else {
      inventory[slug] = left;
    }
    _commit(current.copyWith(inventory: inventory));
    return message;
  }

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

  void swapWithBox(int partyIndex, String boxPokemonId) {
    if (partyIndex < 0 || partyIndex >= state.party.length) return;

    final nextParty = List.of(state.party);
    final nextBox = List.of(state.box);
    final boxIndex = nextBox.indexWhere(
      (pokemon) => pokemon.id == boxPokemonId,
    );
    if (boxIndex < 0) return;

    final incoming = nextBox.removeAt(boxIndex);
    final outgoing = nextParty[partyIndex];
    nextParty[partyIndex] = incoming;
    nextBox.insert(boxIndex, outgoing);

    _commit(state.copyWith(party: nextParty, box: nextBox));
  }

  bool moveToParty(String boxPokemonId) {
    if (!state.hasSpace) return false;
    final boxIndex = state.box.indexWhere((p) => p.id == boxPokemonId);
    if (boxIndex < 0) return false;
    final nextBox = List.of(state.box);
    final incoming = nextBox.removeAt(boxIndex);
    _commit(state.copyWith(party: [...state.party, incoming], box: nextBox));
    return true;
  }

  bool moveToBox(String pokemonId) {
    if (state.party.length <= 1) return false;
    final index = state.party.indexWhere((p) => p.id == pokemonId);
    if (index < 0) return false;
    final nextParty = List.of(state.party);
    final outgoing = nextParty.removeAt(index);
    _commit(state.copyWith(party: nextParty, box: [...state.box, outgoing]));
    return true;
  }

  void toggleFavorite(String pokemonId) {
    final pokemon = state.pokemonById(pokemonId);
    if (pokemon == null) return;
    _commit(
      _replacePokemon(state, pokemon.copyWith(isFavorite: !pokemon.isFavorite)),
    );
  }

  void setNickname(String pokemonId, String nickname) {
    final pokemon = state.pokemonById(pokemonId);
    if (pokemon == null) return;
    final trimmed = nickname.trim();
    _commit(
      _replacePokemon(
        state,
        pokemon.copyWith(nickname: trimmed.isEmpty ? null : trimmed),
      ),
    );
  }

  /// Releases a Pokémon for coins. Party releases keep at least one member.
  int release(String pokemonId) {
    final pokemon = state.pokemonById(pokemonId);
    if (pokemon == null || pokemon.isLocked) return 0;
    final inParty = state.party.any((p) => p.id == pokemonId);
    if (inParty && state.party.length <= 1) return 0;

    final reward = 40 + pokemon.level * 5 + (pokemon.shiny ? 500 : 0);
    _commit(
      state.copyWith(
        party: state.party.where((p) => p.id != pokemonId).toList(),
        box: state.box.where((p) => p.id != pokemonId).toList(),
        coins: state.coins + reward,
      ),
    );
    return reward;
  }

  void addToParty(String pokemonId) {
    moveToParty(pokemonId);
  }

  /// Gives XP to a party or box Pokémon. Used by TMs/candies and catch XP.
  LevelUpReport? grantXp(String pokemonId, int xp) {
    final pokemon = state.pokemonById(pokemonId);
    if (pokemon == null || xp <= 0) return null;
    final report = _grantXp(pokemon, xp);
    var next = _replacePokemon(state, report.pokemon);
    next = _registerEvolution(next, report.evolvedInto);
    _commit(next);
    return report;
  }

  void resetProgress() {
    unawaited(_store.delete(_stateKey));
    state = TrainerState.newTrainer();
  }

  bool get isReady => ref.read(dexCatalogProvider).isLoaded;

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  List<DailyQuest> _progressQuests(
    List<DailyQuest> quests, {
    required QuestKind kind,
    PokemonType? type,
    required int amount,
  }) {
    return [
      for (final quest in quests)
        if (quest.kind == kind &&
            (kind != QuestKind.catchType || quest.type == type) &&
            !quest.claimed)
          quest.copyWith(progress: min(quest.target, quest.progress + amount))
        else
          quest,
    ];
  }

  TrainerState _replacePokemon(TrainerState current, Pokemon updated) {
    return current.copyWith(
      party: [
        for (final pokemon in current.party)
          if (pokemon.id == updated.id) updated else pokemon,
      ],
      box: [
        for (final pokemon in current.box)
          if (pokemon.id == updated.id) updated else pokemon,
      ],
    );
  }

  TrainerState _registerEvolution(TrainerState current, DexEntry? evolved) {
    if (evolved == null) return current;
    return current.copyWith(
      seen: {...current.seen, evolved.number},
      caught: {...current.caught, evolved.number},
    );
  }

  DexEntry? _evolutionFor(Pokemon before, Pokemon after) {
    if (before.name == after.name) return null;
    return ref.read(dexCatalogProvider).speciesNamed(after.name);
  }

  LevelUpReport _grantXp(Pokemon pokemon, int amount) {
    if (pokemon.level >= 100) {
      return LevelUpReport(pokemon: pokemon, levelsGained: 0);
    }
    final total = totalXpForLevel(pokemon.level) + pokemon.xp + amount;
    final newLevel = levelFromXp(total).clamp(pokemon.level, 100);
    final xpIntoLevel = total - totalXpForLevel(newLevel);
    return _applyLevel(pokemon, newLevel, xpIntoLevel);
  }

  LevelUpReport _grantLevels(Pokemon pokemon, int levels) {
    return _applyLevel(
      pokemon,
      (pokemon.level + levels).clamp(1, 100),
      pokemon.xp,
    );
  }

  LevelUpReport _applyLevel(Pokemon pokemon, int newLevel, int xpIntoLevel) {
    if (newLevel <= pokemon.level) {
      return LevelUpReport(
        pokemon: pokemon.copyWith(xp: xpIntoLevel),
        levelsGained: 0,
      );
    }

    final catalog = ref.read(dexCatalogProvider);
    final species = catalog.speciesAt(pokemon.dexNumber);
    final stats = species == null
        ? pokemon.stats
        : computeStats(
            base: species.baseStats,
            ivs: pokemon.ivs,
            evs: pokemon.evs,
            level: newLevel,
            nature: pokemon.nature,
          );
    final hpGain = max(0, stats.hp - pokemon.maxHp);
    final moves = List<String>.of(pokemon.moves);
    final learned = <String>[];
    if (species != null) {
      for (final move in species.moves) {
        if (move.level > newLevel) break;
        if (moves.contains(move.name) || learned.contains(move.name)) continue;
        learned.add(move.name);
        moves.add(move.name);
      }
    }
    final trimmed = moves.length > 4 ? moves.sublist(moves.length - 4) : moves;

    var updated = pokemon.copyWith(
      level: newLevel,
      xp: xpIntoLevel,
      stats: stats,
      maxHp: stats.hp,
      currentHp: min(stats.hp, pokemon.currentHp + hpGain),
      moves: trimmed,
    );

    DexEntry? evolved;
    if (species != null && newLevel > pokemon.level) {
      for (final evolution in species.evolutions) {
        if (!evolution.isLevelUp) continue;
        if (newLevel < evolution.level!) continue;
        final target = catalog.speciesAt(evolution.to);
        if (target == null) continue;
        updated = evolvePokemon(updated, target);
        evolved = target;
        break;
      }
    }

    return LevelUpReport(
      pokemon: updated,
      levelsGained: newLevel - pokemon.level,
      learnedMoves: learned,
      evolvedInto: evolved,
    );
  }
}

final trainerProvider = NotifierProvider<TrainerNotifier, TrainerState>(
  TrainerNotifier.new,
);

/// Compatibility alias for screens that only need the party list.
final partyProvider = Provider<List<Pokemon>>((ref) {
  return ref.watch(trainerProvider).party;
});
