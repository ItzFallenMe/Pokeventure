import 'pokemon_type.dart';

/// Base stats, IVs or EVs share the same shape.
class PokemonStats {
  const PokemonStats({
    required this.hp,
    required this.attack,
    required this.defense,
    required this.spAttack,
    required this.spDefense,
    required this.speed,
  });

  final int hp;
  final int attack;
  final int defense;
  final int spAttack;
  final int spDefense;
  final int speed;

  int get total => hp + attack + defense + spAttack + spDefense + speed;

  static const zero = PokemonStats(
    hp: 0,
    attack: 0,
    defense: 0,
    spAttack: 0,
    spDefense: 0,
    speed: 0,
  );

  Map<String, dynamic> toJson() => {
    'hp': hp,
    'attack': attack,
    'defense': defense,
    'spAttack': spAttack,
    'spDefense': spDefense,
    'speed': speed,
  };

  factory PokemonStats.fromJson(Map<String, dynamic> json) {
    return PokemonStats(
      hp: (json['hp'] as num).toInt(),
      attack: (json['attack'] as num).toInt(),
      defense: (json['defense'] as num).toInt(),
      spAttack: (json['spAttack'] as num).toInt(),
      spDefense: (json['spDefense'] as num).toInt(),
      speed: (json['speed'] as num).toInt(),
    );
  }

  PokemonStats copyWith({
    int? hp,
    int? attack,
    int? defense,
    int? spAttack,
    int? spDefense,
    int? speed,
  }) {
    return PokemonStats(
      hp: hp ?? this.hp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      spAttack: spAttack ?? this.spAttack,
      spDefense: spDefense ?? this.spDefense,
      speed: speed ?? this.speed,
    );
  }
}

/// A single owned Pokémon instance.
///
/// Saves are device-local for now; the same shape is meant to move to the
/// server without changes when accounts land.
class Pokemon {
  const Pokemon({
    required this.id,
    required this.dexNumber,
    required this.name,
    required this.types,
    required this.level,
    required this.ivs,
    required this.evs,
    required this.stats,
    required this.maxHp,
    required this.currentHp,
    required this.moves,
    required this.nature,
    required this.ability,
    this.nickname,
    this.xp = 0,
    this.baseStats = PokemonStats.zero,
    this.heldItem,
    this.shiny = false,
    this.metLevel,
    this.metZone,
    this.caughtAt,
    this.ball = 'Poké Ball',
    this.isFavorite = false,
    this.isLocked = false,
  });

  final String id;
  final int dexNumber;
  final String name;
  final String? nickname;
  final List<PokemonType> types;
  final int level;

  /// XP earned inside the current level.
  final int xp;

  /// The species' base stats, kept on the instance so level-ups work offline.
  final PokemonStats baseStats;

  final PokemonStats ivs;
  final PokemonStats evs;

  /// Computed battle stats.
  final PokemonStats stats;
  final int maxHp;
  final int currentHp;
  final List<String> moves;
  final String nature;
  final String ability;
  final String? heldItem;
  final bool shiny;
  final int? metLevel;
  final String? metZone;
  final DateTime? caughtAt;
  final String ball;
  final bool isFavorite;
  final bool isLocked;

  String get displayName => nickname ?? name;

  bool get isFainted => currentHp <= 0;

  double get hpFraction {
    if (maxHp <= 0) return 0;
    return (currentHp / maxHp).clamp(0.0, 1.0);
  }

  String get dexLabel => '#${dexNumber.toString().padLeft(4, '0')}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'dexNumber': dexNumber,
    'name': name,
    'nickname': nickname,
    'types': types.map((type) => type.name).toList(),
    'level': level,
    'xp': xp,
    'baseStats': baseStats.toJson(),
    'ivs': ivs.toJson(),
    'evs': evs.toJson(),
    'stats': stats.toJson(),
    'maxHp': maxHp,
    'currentHp': currentHp,
    'moves': moves,
    'nature': nature,
    'ability': ability,
    'heldItem': heldItem,
    'shiny': shiny,
    'metLevel': metLevel,
    'metZone': metZone,
    'caughtAt': caughtAt?.toIso8601String(),
    'ball': ball,
    'isFavorite': isFavorite,
    'isLocked': isLocked,
  };

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'] as String,
      dexNumber: json['dexNumber'] as int,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      types: (json['types'] as List<dynamic>)
          .map((raw) => PokemonType.values.byName(raw as String))
          .toList(growable: false),
      level: (json['level'] as num).toInt(),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      baseStats: json['baseStats'] == null
          ? PokemonStats.zero
          : PokemonStats.fromJson(json['baseStats'] as Map<String, dynamic>),
      ivs: PokemonStats.fromJson(json['ivs'] as Map<String, dynamic>),
      evs: PokemonStats.fromJson(json['evs'] as Map<String, dynamic>),
      stats: PokemonStats.fromJson(json['stats'] as Map<String, dynamic>),
      maxHp: (json['maxHp'] as num).toInt(),
      currentHp: (json['currentHp'] as num).toInt(),
      moves: (json['moves'] as List<dynamic>).cast<String>(),
      nature: json['nature'] as String,
      ability: json['ability'] as String,
      heldItem: json['heldItem'] as String?,
      shiny: json['shiny'] as bool? ?? false,
      metLevel: (json['metLevel'] as num?)?.toInt(),
      metZone: json['metZone'] as String?,
      caughtAt: json['caughtAt'] == null
          ? null
          : DateTime.tryParse(json['caughtAt'] as String),
      ball: json['ball'] as String? ?? 'Poké Ball',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  Pokemon copyWith({
    String? id,
    int? dexNumber,
    String? name,
    String? nickname,
    List<PokemonType>? types,
    int? level,
    int? xp,
    PokemonStats? baseStats,
    PokemonStats? ivs,
    PokemonStats? evs,
    PokemonStats? stats,
    int? maxHp,
    int? currentHp,
    List<String>? moves,
    String? nature,
    String? ability,
    String? heldItem,
    bool? shiny,
    int? metLevel,
    String? metZone,
    DateTime? caughtAt,
    String? ball,
    bool? isFavorite,
    bool? isLocked,
  }) {
    return Pokemon(
      id: id ?? this.id,
      dexNumber: dexNumber ?? this.dexNumber,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      types: types ?? this.types,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      baseStats: baseStats ?? this.baseStats,
      ivs: ivs ?? this.ivs,
      evs: evs ?? this.evs,
      stats: stats ?? this.stats,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      moves: moves ?? this.moves,
      nature: nature ?? this.nature,
      ability: ability ?? this.ability,
      heldItem: heldItem ?? this.heldItem,
      shiny: shiny ?? this.shiny,
      metLevel: metLevel ?? this.metLevel,
      metZone: metZone ?? this.metZone,
      caughtAt: caughtAt ?? this.caughtAt,
      ball: ball ?? this.ball,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
