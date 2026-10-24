import 'package:flutter/material.dart';

import '../../data/models/pokemon_type.dart';
import '../theme/app_theme.dart';
import '../tokens/type_palette.dart';

/// A type-tinted Pokéball orb. Stands in for sprites until the sprite pipeline
/// ships, and doubles as the compact avatar everywhere else.
class TypeOrb extends StatefulWidget {
  const TypeOrb({
    super.key,
    required this.types,
    this.size = 56,
    this.active = false,
    this.shiny = false,
  });

  final List<PokemonType> types;
  final double size;
  final bool active;
  final bool shiny;

  @override
  State<TypeOrb> createState() => _TypeOrbState();
}

class _TypeOrbState extends State<TypeOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TypeOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _pulse.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.types.isEmpty ? PokemonType.normal : widget.types.first;
    final glow = TypePalette.of(type);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final size = widget.size;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: TypePalette.gradient(type),
            ),
            border: widget.shiny
                ? Border.all(color: AppTheme.shiny, width: size * 0.05)
                : null,
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.26 + 0.22 * t),
                blurRadius: size * 0.22 + size * 0.18 * t,
                spreadRadius: size * 0.02 + size * 0.04 * t,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _PokeballPainter()),
              ),
              if (widget.shiny)
                Positioned(
                  top: size * 0.05,
                  right: size * 0.01,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: size * 0.26,
                    color: AppTheme.shiny,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PokeballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final ink = const Color(0xFF1B1727).withValues(alpha: 0.66);

    canvas.drawCircle(
      center,
      radius * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.07
        ..color = Colors.white.withValues(alpha: 0.5),
    );

    canvas.drawRect(
      Rect.fromLTWH(
        radius * 0.16,
        radius - radius * 0.055,
        size.width * 0.68,
        radius * 0.11,
      ),
      Paint()..color = ink,
    );

    canvas.drawCircle(
      center,
      radius * 0.27,
      Paint()..color = Colors.white.withValues(alpha: 0.94),
    );
    canvas.drawCircle(center, radius * 0.17, Paint()..color = ink);
    canvas.drawCircle(
      center,
      radius * 0.095,
      Paint()..color = Colors.white.withValues(alpha: 0.96),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.74),
      -2.7,
      1.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 0.1
        ..color = Colors.white.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _PokeballPainter oldDelegate) => false;
}
