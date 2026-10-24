import 'dart:math';

import '../models/pokemon_type.dart';

enum QuestKind { catchAny, catchType, catchNew, greatBall, winBattle }

class DailyQuest {
  const DailyQuest({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.target,
    this.progress = 0,
    this.rewardCoins = 100,
    this.rewardItemSlug,
    this.rewardItemQuantity = 0,
    this.type,
    this.claimed = false,
  });

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      id: json['id'] as String,
      kind: QuestKind.values.asNameMap()[json['kind']] ?? QuestKind.catchAny,
      title: json['title'] as String,
      description: json['description'] as String,
      target: (json['target'] as num).toInt(),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
      rewardItemSlug: json['rewardItemSlug'] as String?,
      rewardItemQuantity: (json['rewardItemQuantity'] as num?)?.toInt() ?? 0,
      type: json['type'] == null
          ? null
          : PokemonType.values.asNameMap()[json['type'] as String],
      claimed: json['claimed'] as bool? ?? false,
    );
  }

  final String id;
  final QuestKind kind;
  final String title;
  final String description;
  final int target;
  final int progress;
  final int rewardCoins;
  final String? rewardItemSlug;
  final int rewardItemQuantity;
  final PokemonType? type;
  final bool claimed;

  bool get isComplete => progress >= target;

  bool get isClaimable => isComplete && !claimed;

  double get fraction => (progress / target).clamp(0.0, 1.0);

  DailyQuest copyWith({int? progress, bool? claimed}) {
    return DailyQuest(
      id: id,
      kind: kind,
      title: title,
      description: description,
      target: target,
      progress: progress ?? this.progress,
      rewardCoins: rewardCoins,
      rewardItemSlug: rewardItemSlug,
      rewardItemQuantity: rewardItemQuantity,
      type: type,
      claimed: claimed ?? this.claimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'description': description,
    'target': target,
    'progress': progress,
    'rewardCoins': rewardCoins,
    'rewardItemSlug': rewardItemSlug,
    'rewardItemQuantity': rewardItemQuantity,
    'type': type?.name,
    'claimed': claimed,
  };
}

const _rotatingTypes = [
  PokemonType.water,
  PokemonType.fire,
  PokemonType.grass,
  PokemonType.electric,
  PokemonType.psychic,
  PokemonType.bug,
  PokemonType.rock,
  PokemonType.ghost,
  PokemonType.dragon,
  PokemonType.fairy,
  PokemonType.ice,
  PokemonType.ground,
  PokemonType.poison,
  PokemonType.flying,
  PokemonType.fighting,
  PokemonType.normal,
  PokemonType.dark,
  PokemonType.steel,
];

int dayKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

String dayKeyString(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Three quests a day, stable for the date and different tomorrow.
List<DailyQuest> generateDailyQuests(DateTime date) {
  final seed = dayKey(date);
  final random = Random(seed);
  final type = _rotatingTypes[seed % _rotatingTypes.length];

  final pool = <DailyQuest>[
    DailyQuest(
      id: 'catch_any',
      kind: QuestKind.catchAny,
      title: 'Field research',
      description: 'Catch 3 Pokémon in any zone.',
      target: 3,
      rewardCoins: 140,
      rewardItemSlug: 'poke_ball',
      rewardItemQuantity: 5,
    ),
    DailyQuest(
      id: 'catch_${type.name}',
      kind: QuestKind.catchType,
      title: '${type.label} safari',
      description: 'Catch 2 ${type.label}-type Pokémon.',
      target: 2,
      type: type,
      rewardCoins: 180,
      rewardItemSlug: 'great_ball',
      rewardItemQuantity: 3,
    ),
    const DailyQuest(
      id: 'catch_new',
      kind: QuestKind.catchNew,
      title: 'New discovery',
      description: 'Register a species you have never caught.',
      target: 1,
      rewardCoins: 220,
      rewardItemSlug: 'razz_berry',
      rewardItemQuantity: 3,
    ),
    const DailyQuest(
      id: 'great_ball',
      kind: QuestKind.greatBall,
      title: 'Precision throw',
      description: 'Catch a Pokémon in a Great Ball or better.',
      target: 1,
      rewardCoins: 160,
      rewardItemSlug: 'ultra_ball',
      rewardItemQuantity: 2,
    ),
    const DailyQuest(
      id: 'win_battle',
      kind: QuestKind.winBattle,
      title: 'Practice match',
      description: 'Win a battle against the AI.',
      target: 1,
      rewardCoins: 200,
      rewardItemSlug: 'potion',
      rewardItemQuantity: 2,
    ),
  ];

  pool.shuffle(random);
  return pool.take(3).toList(growable: false);
}
