import 'package:flutter/material.dart';

import '../../data/models/pokemon_type.dart';

/// Semantic type colours. These never follow the Material You wallpaper tint —
/// a Fire type must read as Fire in every theme.
abstract final class TypePalette {
  static const Map<PokemonType, Color> _colors = {
    PokemonType.normal: Color(0xFFA8A77A),
    PokemonType.fire: Color(0xFFEE8130),
    PokemonType.water: Color(0xFF6390F0),
    PokemonType.electric: Color(0xFFF7D02C),
    PokemonType.grass: Color(0xFF7AC74C),
    PokemonType.ice: Color(0xFF96D9D6),
    PokemonType.fighting: Color(0xFFC22E28),
    PokemonType.poison: Color(0xFFA33EA1),
    PokemonType.ground: Color(0xFFE2BF65),
    PokemonType.flying: Color(0xFFA98FF3),
    PokemonType.psychic: Color(0xFFF95587),
    PokemonType.bug: Color(0xFFA6B91A),
    PokemonType.rock: Color(0xFFB6A136),
    PokemonType.ghost: Color(0xFF735797),
    PokemonType.dragon: Color(0xFF6F35FC),
    PokemonType.dark: Color(0xFF705746),
    PokemonType.steel: Color(0xFFB7B7CE),
    PokemonType.fairy: Color(0xFFD685AD),
  };

  static Color of(PokemonType type) => _colors[type]!;

  /// Readable text on a solid type-coloured surface.
  static Color on(PokemonType type) {
    return of(type).computeLuminance() > 0.55
        ? const Color(0xFF16131C)
        : Colors.white;
  }

  /// Tinted container used behind type chips and card accents.
  static Color soft(PokemonType type, Brightness brightness) {
    final base = of(type);
    final overlay = brightness == Brightness.dark
        ? base.withValues(alpha: 0.24)
        : base.withValues(alpha: 0.16);
    return Color.alphaBlend(
      overlay,
      brightness == Brightness.dark
          ? const Color(0xFF18151F)
          : const Color(0xFFFDFBFF),
    );
  }

  /// Type label colour, darkened in light mode for contrast.
  static Color text(PokemonType type, Brightness brightness) {
    final base = of(type);
    if (brightness == Brightness.dark) {
      return Color.alphaBlend(Colors.white.withValues(alpha: 0.35), base);
    }
    return Color.alphaBlend(Colors.black.withValues(alpha: 0.34), base);
  }

  /// Two-stop gradient for orbs and hero panels.
  static List<Color> gradient(PokemonType type) {
    final base = of(type);
    return [
      Color.alphaBlend(Colors.white.withValues(alpha: 0.22), base),
      Color.alphaBlend(Colors.black.withValues(alpha: 0.2), base),
    ];
  }
}
