import 'package:flutter/material.dart';

import '../tokens/layout.dart';

class HpBar extends StatelessWidget {
  const HpBar({
    super.key,
    required this.value,
    this.height = 6,
    this.animate = true,
  });

  final double value;
  final double height;
  final bool animate;

  static const _healthy = Color(0xFF35C46A);
  static const _warning = Color(0xFFF5B633);
  static const _critical = Color(0xFFEF4B5F);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = value.clamp(0.0, 1.0);
    final color = clamped > 0.5
        ? _healthy
        : clamped > 0.2
        ? _warning
        : _critical;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fill = Container(
            width: constraints.maxWidth * clamped,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.75), color],
              ),
            ),
          );

          return ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: height,
                  color: scheme.surfaceContainerHighest,
                ),
                if (!animate)
                  fill
                else
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: clamped),
                    duration: AppMotion.slow,
                    curve: AppMotion.emphasizedDecelerate,
                    builder: (context, animated, _) {
                      return Container(
                        width: constraints.maxWidth * animated,
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.75), color],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
