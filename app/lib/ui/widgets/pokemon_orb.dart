import 'package:flutter/material.dart';

import '../../data/models/pokemon.dart';
import '../theme/app_theme.dart';
import '../tokens/type_palette.dart';
import 'pokemon_sprite.dart';
import 'type_orb.dart';

/// A type-tinted badge with the Pokémon's sprite. Falls back to a Pokéball
/// orb when sprites are disabled (tests) or fail to load.
class PokemonOrb extends StatelessWidget {
  const PokemonOrb({
    super.key,
    required this.pokemon,
    this.size = 56,
    this.active = false,
  });

  final Pokemon pokemon;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!SpriteConfig.enabled) {
      return TypeOrb(
        types: pokemon.types,
        size: size,
        active: active,
        shiny: pokemon.shiny,
      );
    }

    final type = pokemon.types.first;
    final tint = TypePalette.of(type);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: 0.26),
                  tint.withValues(alpha: 0.07),
                ],
              ),
              border: Border.all(color: tint.withValues(alpha: 0.38)),
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(alpha: 0.24),
                  blurRadius: size * 0.24,
                  spreadRadius: size * 0.02,
                ),
              ],
            ),
          ),
          PokemonSprite(
            dexNumber: pokemon.dexNumber,
            fallbackTypes: pokemon.types,
            size: size * 0.92,
            shiny: pokemon.shiny,
          ),
          if (pokemon.shiny)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: size * 0.24,
                color: AppTheme.shiny,
              ),
            ),
        ],
      ),
    );
  }
}
