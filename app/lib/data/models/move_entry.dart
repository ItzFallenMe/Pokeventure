import 'pokemon_type.dart';

class MoveEntry {
  const MoveEntry({
    required this.name,
    required this.type,
    required this.category,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.priority,
  });

  factory MoveEntry.fromJson(Map<String, dynamic> json) {
    return MoveEntry(
      name: json['name'] as String,
      type: PokemonType.values.asNameMap()[
              (json['type'] as String).toLowerCase()] ??
          PokemonType.normal,
      category: json['category'] as String? ?? 'Status',
      power: (json['power'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toInt(),
      pp: (json['pp'] as num?)?.toInt() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );
  }

  final String name;
  final PokemonType type;
  final String category;
  final int power;
  final int? accuracy;
  final int pp;
  final int priority;

  bool get isStatus => category == 'Status';
}
