import 'pokemon.dart';
import 'pokemon_type.dart';

/// One way a species can evolve.
class Evolution {
  const Evolution({
    required this.to,
    required this.name,
    required this.method,
    required this.condition,
    this.level,
    this.item,
  });

  factory Evolution.fromJson(Map<String, dynamic> json) {
    return Evolution(
      to: json['to'] as int,
      name: json['name'] as String,
      method: json['method'] as String? ?? 'special',
      condition: json['condition'] as String? ?? '',
      level: (json['level'] as num?)?.toInt(),
      item: json['item'] as String?,
    );
  }

  final int to;
  final String name;

  /// `level-up`, `use-item`, `trade`, `friendship`, `level-hold` or `special`.
  final String method;
  final String condition;
  final int? level;
  final String? item;

  bool get isLevelUp => method == 'level-up' && level != null;
}

class LearnableMove {
  const LearnableMove({required this.name, required this.level});

  factory LearnableMove.fromJson(Map<String, dynamic> json) {
    return LearnableMove(
      name: json['name'] as String,
      level: (json['level'] as num?)?.toInt() ?? 1,
    );
  }

  final String name;
  final int level;
}

/// A species as shipped in the generated dex snapshot (`assets/data/dex.json`).
class DexEntry {
  const DexEntry({
    required this.number,
    required this.name,
    required this.types,
    required this.baseStats,
    required this.generation,
    this.slug = '',
    this.normalAbility,
    this.hiddenAbility,
    this.catchRate = 45,
    this.baseExp = 0,
    this.growthRate = 'medium',
    this.height,
    this.weight,
    this.genus = '',
    this.description = '',
    this.legendary = false,
    this.mythical = false,
    this.evolvesFrom,
    this.evolutions = const [],
    this.moves = const [],
  });

  factory DexEntry.fromJson(Map<String, dynamic> json) {
    final stats = json['baseStats'] as Map<String, dynamic>;
    final abilities = json['abilities'] as Map<String, dynamic>? ?? const {};
    final types = (json['types'] as List<dynamic>)
        .map((raw) => _typeFromName(raw as String))
        .toList(growable: false);

    return DexEntry(
      number: json['num'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      types: types,
      baseStats: PokemonStats(
        hp: stats['hp'] as int,
        attack: stats['atk'] as int,
        defense: stats['def'] as int,
        spAttack: stats['spa'] as int,
        spDefense: stats['spd'] as int,
        speed: stats['spe'] as int,
      ),
      generation: json['gen'] as int,
      normalAbility: abilities['normal'] as String?,
      hiddenAbility: abilities['hidden'] as String?,
      catchRate: (json['catchRate'] as num?)?.toInt() ?? 45,
      baseExp: (json['baseExp'] as num?)?.toInt() ?? 0,
      growthRate: json['growthRate'] as String? ?? 'medium',
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      genus: json['genus'] as String? ?? '',
      description: json['description'] as String? ?? '',
      legendary: json['legendary'] as bool? ?? false,
      mythical: json['mythical'] as bool? ?? false,
      evolvesFrom: _stringOrNull(json['evolvesFrom']),
      evolutions: ((json['evolutions'] as List<dynamic>?) ?? const [])
          .map((raw) => Evolution.fromJson(raw as Map<String, dynamic>))
          .toList(growable: false),
      moves: ((json['moves'] as List<dynamic>?) ?? const [])
          .map((raw) => LearnableMove.fromJson(raw as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int number;
  final String name;
  final String slug;
  final List<PokemonType> types;
  final PokemonStats baseStats;
  final int generation;
  final String? normalAbility;
  final String? hiddenAbility;
  final int catchRate;
  final int baseExp;
  final String growthRate;
  final String? height;
  final String? weight;
  final String genus;
  final String description;
  final bool legendary;
  final bool mythical;

  /// Previous species name, when this is an evolution.
  final String? evolvesFrom;
  final List<Evolution> evolutions;

  /// Level-up learnset, sorted by level.
  final List<LearnableMove> moves;

  String get dexLabel => '#${number.toString().padLeft(4, '0')}';

  int get statTotal => baseStats.total;

  bool get isLegendary => legendary || mythical;

  String get ability => normalAbility ?? '—';

  String get rarityLabel {
    if (mythical) return 'Mythical';
    if (legendary) return 'Legendary';
    if (statTotal >= 600) return 'Pseudo-legendary';
    if (catchRate <= 25) return 'Epic';
    if (catchRate <= 60) return 'Rare';
    if (catchRate <= 120) return 'Uncommon';
    return 'Common';
  }

  /// The last four moves this species knows by [level], with earlier moves
  /// filling the gaps for low-level catches.
  List<String> movesAtLevel(int level) {
    final learned = <String>[];
    for (final move in moves) {
      if (move.level > level) break;
      if (!learned.contains(move.name)) learned.add(move.name);
    }
    if (learned.length >= 4) return learned.sublist(learned.length - 4);
    for (final move in moves) {
      if (learned.length >= 4) break;
      if (!learned.contains(move.name)) learned.add(move.name);
    }
    return learned;
  }

  bool matches(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    if (name.toLowerCase().contains(trimmed)) return true;
    if (dexLabel.contains(trimmed)) return true;
    return number.toString() == trimmed;
  }

  static String? _stringOrNull(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  static PokemonType _typeFromName(String raw) {
    final key = raw.toLowerCase();
    return PokemonType.values.asNameMap()[key] ?? PokemonType.normal;
  }
}
