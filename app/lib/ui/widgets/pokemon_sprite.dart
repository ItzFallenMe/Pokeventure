import 'package:flutter/material.dart';

import '../../data/models/pokemon_type.dart';
import '../tokens/layout.dart';
import 'type_orb.dart';

/// Sprites come from the PokeAPI sprites repository. Set this to false in
/// widget tests so nothing hits the network.
abstract final class SpriteConfig {
  static bool enabled = true;
}

const String _spriteBase =
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon';

String pokemonSpriteUrl(
  int dexNumber, {
  bool shiny = false,
  bool artwork = false,
}) {
  if (artwork) {
    return '$_spriteBase/other/official-artwork/'
        '${shiny ? 'shiny/' : ''}$dexNumber.png';
  }
  return '$_spriteBase/${shiny ? 'shiny/' : ''}$dexNumber.png';
}

class PokemonSprite extends StatelessWidget {
  const PokemonSprite({
    super.key,
    required this.dexNumber,
    required this.fallbackTypes,
    this.size = 64,
    this.shiny = false,
    this.artwork = false,
  });

  final int dexNumber;
  final List<PokemonType> fallbackTypes;
  final double size;
  final bool shiny;
  final bool artwork;

  @override
  Widget build(BuildContext context) {
    if (!SpriteConfig.enabled || dexNumber <= 0) {
      return TypeOrb(types: fallbackTypes, size: size, shiny: shiny);
    }

    return Image.network(
      pokemonSpriteUrl(dexNumber, shiny: shiny, artwork: artwork),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return TypeOrb(types: fallbackTypes, size: size, shiny: shiny);
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: AppMotion.fast,
          child: frame == null
              ? TypeOrb(
                  key: const ValueKey('sprite-placeholder'),
                  types: fallbackTypes,
                  size: size,
                  shiny: shiny,
                )
              : child,
        );
      },
    );
  }
}
