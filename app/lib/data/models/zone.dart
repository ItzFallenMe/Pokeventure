import 'package:flutter/painting.dart';

import 'pokemon_type.dart';

/// A species entry in a zone's spawn table.
class ZoneSpawn {
  const ZoneSpawn({
    required this.number,
    required this.rarity,
    required this.weight,
  });

  factory ZoneSpawn.fromJson(Map<String, dynamic> json) {
    return ZoneSpawn(
      number: json['num'] as int,
      rarity: json['rarity'] as String? ?? 'common',
      weight: (json['weight'] as num?)?.toInt() ?? 1,
    );
  }

  final int number;

  /// `common`, `uncommon`, `rare` or `epic`.
  final String rarity;
  final int weight;
}

class Zone {
  const Zone({
    required this.slug,
    required this.name,
    required this.subtitle,
    required this.types,
    required this.minLevel,
    required this.maxLevel,
    required this.accent,
    required this.icon,
    required this.spawns,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    final levels = (json['levels'] as List<dynamic>?) ?? const [3, 10];
    final accent =
        (json['accent'] as List<dynamic>?) ?? const ['#2FA36B', '#A8E063'];
    return Zone(
      slug: json['slug'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      types: (json['types'] as List<dynamic>)
          .map(
            (raw) =>
                PokemonType.values.asNameMap()[raw.toString().toLowerCase()] ??
                PokemonType.normal,
          )
          .toList(growable: false),
      minLevel: (levels.first as num).toInt(),
      maxLevel: (levels.last as num).toInt(),
      accent: accent
          .map((raw) => _parseColor(raw as String))
          .toList(growable: false),
      icon: json['icon'] as String? ?? 'forest',
      spawns: (json['spawns'] as List<dynamic>)
          .map((raw) => ZoneSpawn.fromJson(raw as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String slug;
  final String name;
  final String subtitle;
  final List<PokemonType> types;
  final int minLevel;
  final int maxLevel;

  /// Two brand colours for gradients.
  final List<Color> accent;
  final String icon;
  final List<ZoneSpawn> spawns;

  int get totalWeight => spawns.fold(0, (sum, spawn) => sum + spawn.weight);

  int get speciesCount => spawns.length;

  static Color _parseColor(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}
