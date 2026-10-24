import 'package:flutter/material.dart';

import '../../data/models/pokemon_type.dart';
import '../tokens/type_palette.dart';

class TypeChip extends StatelessWidget {
  const TypeChip({super.key, required this.type, this.dense = false});

  final PokemonType type;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final base = TypePalette.of(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: TypePalette.soft(type, brightness),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withValues(alpha: 0.38)),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: TypePalette.text(type, brightness),
        ),
      ),
    );
  }
}
