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
      hp: json['hp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      spAttack: json['spAttack'] as int,
      spDefense: json['spDefense'] as int,
      speed: json['speed'] as int,
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
/// In the real game this is server-authoritative; here it backs the UI shell.
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
    this.heldItem,
    this.shiny = false,
  });

  final String id;
  final int dexNumber;
  final String name;
  final List<PokemonType> types;
  final int level;
  final PokemonStats ivs;
  final PokemonStats evs;

  /// Computed battle stats (level-scaled, server-side in production).
  final PokemonStats stats;
  final int maxHp;
  final int currentHp;
  final List<String> moves;
  final String nature;
  final String ability;
  final String? heldItem;
  final bool shiny;

  bool get isFainted => currentHp <= 0;

  double get hpFraction {
    if (maxHp <= 0) return 0;
    return (currentHp / maxHp).clamp(0.0, 1.0);
  }

  String get dexLabel => '#${dexNumber.toString().padLeft(3, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'dexNumber': dexNumber,
        'name': name,
        'types': types.map((type) => type.name).toList(),
        'level': level,
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
      };

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'] as String,
      dexNumber: json['dexNumber'] as int,
      name: json['name'] as String,
      types: (json['types'] as List<dynamic>)
          .map((raw) => PokemonType.values.byName(raw as String))
          .toList(growable: false),
      level: json['level'] as int,
      ivs: PokemonStats.fromJson(json['ivs'] as Map<String, dynamic>),
      evs: PokemonStats.fromJson(json['evs'] as Map<String, dynamic>),
      stats: PokemonStats.fromJson(json['stats'] as Map<String, dynamic>),
      maxHp: json['maxHp'] as int,
      currentHp: json['currentHp'] as int,
      moves: (json['moves'] as List<dynamic>).cast<String>(),
      nature: json['nature'] as String,
      ability: json['ability'] as String,
      heldItem: json['heldItem'] as String?,
      shiny: json['shiny'] as bool? ?? false,
    );
  }

  Pokemon copyWith({
    String? id,
    String? name,
    int? level,
    int? currentHp,
    int? maxHp,
    bool? shiny,
  }) {
    return Pokemon(
      id: id ?? this.id,
      dexNumber: dexNumber,
      name: name ?? this.name,
      types: types,
      level: level ?? this.level,
      ivs: ivs,
      evs: evs,
      stats: stats,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      moves: moves,
      nature: nature,
      ability: ability,
      heldItem: heldItem,
      shiny: shiny ?? this.shiny,
    );
  }
}
