import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../tokens/layout.dart';

bool reduceMotion(BuildContext context) {
  return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// Scales its child down while pressed without stealing the tap.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.scale = 0.96,
    this.duration = AppMotion.fast,
  });

  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed && !reduceMotion(context) ? widget.scale : 1,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Animates a number when it changes, with optional thousands separators.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.commas = true,
    this.duration = AppMotion.slow,
  });

  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final bool commas;
  final Duration duration;

  static String format(int value, {bool commas = true}) {
    final raw = value.abs().toString();
    if (!commas) return value < 0 ? '-$raw' : raw;
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
      buffer.write(raw[i]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return Text(
          '$prefix${format(animated.round(), commas: commas)}$suffix',
          style: style,
        );
      },
      child: Text(
        '$prefix${format(value, commas: commas)}$suffix',
        style: style,
      ),
    );
  }
}

/// A slow breathing glow, used behind featured cards and the buddy.
class GlowPulse extends StatefulWidget {
  const GlowPulse({
    super.key,
    required this.child,
    this.color,
    this.min = 0.35,
    this.max = 0.7,
    this.period = const Duration(milliseconds: 2600),
  });

  final Widget child;
  final Color? color;
  final double min;
  final double max;
  final Duration period;

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final glow = widget.min + (widget.max - widget.min) * t;
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: tint.withValues(alpha: glow * 0.55),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Two drifting colour blobs behind hero content.
class AuroraBackdrop extends StatefulWidget {
  const AuroraBackdrop({
    super.key,
    required this.child,
    this.colors,
    this.opacity = 0.55,
  });

  final Widget child;
  final List<Color>? colors;
  final double opacity;

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors =
        widget.colors ??
        (isDark
            ? const [Color(0xFF4F46E5), Color(0xFF9A3FB0), Color(0xFF0E7490)]
            : const [Color(0xFF6D5BFF), Color(0xFFF472B6), Color(0xFF2DD4BF)]);
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * 2 * math.pi;
          return Stack(
            children: [
              Positioned(
                left: -60 + 34 * math.sin(t),
                top: -80 + 26 * math.cos(t * 0.8),
                child: _Blob(
                  color: colors[0].withValues(alpha: widget.opacity * 0.5),
                  size: 230,
                ),
              ),
              Positioned(
                right: -70 + 30 * math.cos(t * 0.7),
                top: 40 + 30 * math.sin(t),
                child: _Blob(
                  color: colors[1].withValues(alpha: widget.opacity * 0.4),
                  size: 210,
                ),
              ),
              Positioned(
                right: 60,
                bottom: -90 + 22 * math.sin(t * 1.2),
                child: _Blob(
                  color: colors[2].withValues(alpha: widget.opacity * 0.32),
                  size: 200,
                ),
              ),
              child!,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Shimmering placeholder for loading cards.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final slide = _controller.value * 2 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(slide - 1, 0),
              end: Alignment(slide + 1, 0),
              colors: [
                scheme.surfaceContainerHigh,
                scheme.surfaceContainerHighest,
                scheme.surfaceContainerHigh,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A one-shot confetti burst. Draws behind whatever is stacked above it.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.count = 34,
    this.colors,
    this.duration = const Duration(milliseconds: 1600),
  });

  final int count;
  final List<Color>? colors;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final List<_Particle> _particles = _buildParticles(widget.count);

  static List<_Particle> _buildParticles(int count) {
    final random = math.Random(7);
    return List.generate(count, (index) {
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * 2.4;
      final speed = 160 + random.nextDouble() * 240;
      return _Particle(
        angle: angle,
        speed: speed,
        size: 4 + random.nextDouble() * 5,
        spin: (random.nextDouble() - 0.5) * 10,
        colorIndex: index,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return const SizedBox.shrink();
    final palette =
        widget.colors ??
        const [
          AppTheme.gold,
          AppTheme.teal,
          AppTheme.rose,
          Color(0xFF8B5CF6),
          Colors.white,
        ];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              progress: Curves.easeOutCubic.transform(_controller.value),
              particles: _particles,
              palette: palette,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.colorIndex,
  });

  final double angle;
  final double speed;
  final double size;
  final double spin;
  final int colorIndex;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.particles,
    required this.palette,
  });

  final double progress;
  final List<_Particle> particles;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.34);
    final paint = Paint();
    for (final particle in particles) {
      final distance = particle.speed * progress;
      final x = origin.dx + math.cos(particle.angle) * distance;
      final y =
          origin.dy +
          math.sin(particle.angle) * distance +
          260 * progress * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = palette[particle.colorIndex % palette.length].withValues(
        alpha: opacity,
      );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.spin * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 1.8,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// A spring-in modal used for catches, level-ups, shiny reveals and rewards.
Future<void> showCelebration(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.auto_awesome_rounded,
  Color? tint,
  String actionLabel = 'Continue',
  Widget? content,
  bool confetti = true,
}) {
  final color = tint ?? AppTheme.gold;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: AppMotion.slow,
    pageBuilder: (dialogContext, _, _) {
      final media = MediaQuery.of(dialogContext);
      return Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: media.size.height * 0.8,
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (confetti) const Positioned.fill(child: ConfettiBurst()),
                  _CelebrationCard(
                    title: title,
                    message: message,
                    icon: icon,
                    tint: color,
                    actionLabel: actionLabel,
                    content: content,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.tint,
    required this.actionLabel,
    this.content,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color tint;
  final String actionLabel;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.35),
            blurRadius: 44,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  tint.withValues(alpha: 0.35),
                  tint.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(color: tint.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, size: 36, color: tint),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (content != null) ...[
            const SizedBox(height: AppSpacing.lg),
            content!,
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft fade-through push used for full-screen game views.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: AppMotion.slow,
        reverseTransitionDuration: AppMotion.base,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasizedDecelerate,
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      );
}
