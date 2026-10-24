import 'pokemon.dart';
import 'pokemon_type.dart';

/// A species as shipped in the generated dex snapshot (`assets/data/dex.json`).
class DexEntry {
  const DexEntry({
    required this.number,
    required this.name,
    required this.types,
    required this.baseStats,
    required this.generation,
    this.normalAbility,
    this.hiddenAbility,
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
    );
  }

  final int number;
  final String name;
  final List<PokemonType> types;
  final PokemonStats baseStats;
  final int generation;
  final String? normalAbility;
  final String? hiddenAbility;

  String get dexLabel => '#${number.toString().padLeft(4, '0')}';

  int get statTotal => baseStats.total;

  bool matches(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    if (name.toLowerCase().contains(trimmed)) return true;
    if (dexLabel.contains(trimmed)) return true;
    return number.toString() == trimmed;
  }

  static PokemonType _typeFromName(String raw) {
    final key = raw.toLowerCase();
    return PokemonType.values.asNameMap()[key] ?? PokemonType.normal;
  }
}
