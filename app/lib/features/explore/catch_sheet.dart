import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dex_repository.dart';
import '../../data/game/catch.dart';
import '../../data/game/wild.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/motion/motion.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/pokemon_sprite.dart';
import '../../ui/widgets/type_chip.dart';

Future<CatchReport?> showCatchSheet(BuildContext context, WildSpawn spawn) {
  return showModalBottomSheet<CatchReport>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CatchSheet(spawn: spawn),
  );
}

enum _Stage { aiming, throwing, wobbling, brokeFree, fled }

class CatchSheet extends ConsumerStatefulWidget {
  const CatchSheet({super.key, required this.spawn});

  final WildSpawn spawn;

  @override
  ConsumerState<CatchSheet> createState() => _CatchSheetState();
}

class _CatchSheetState extends ConsumerState<CatchSheet>
    with TickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat();

  late final AnimationController _throw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  final Random _random = Random();

  _Stage _stage = _Stage.aiming;
  String _ballSlug = 'poke_ball';
  bool _useRazz = false;
  double _timing = 1;
  bool _claimed = false;
  bool _busy = false;
  int _wobbles = 0;

  @override
  void initState() {
    super.initState();
    final state = ref.read(trainerProvider);
    for (final ball in ballCatalog) {
      if (state.quantityOf(ball.slug) > 0) {
        _ballSlug = ball.slug;
        break;
      }
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    _throw.dispose();
    _wobble.dispose();
    super.dispose();
  }

  BallDef get _ball => ballBySlug(_ballSlug);

  double get _chance {
    final spawn = widget.spawn.pokemon;
    return catchChance(
      catchRate:
          ref.read(dexCatalogProvider).speciesAt(spawn.dexNumber)?.catchRate ??
          45,
      level: spawn.level,
      ball: _ball,
      targetTypes: spawn.types,
      berry: _useRazz && ref.read(trainerProvider).quantityOf('razz_berry') > 0
          ? berryMultipliers['razz_berry']!
          : 1,
      timing: _timing,
      currentHp: spawn.currentHp,
      maxHp: spawn.maxHp,
    );
  }

  Future<void> _throwBall() async {
    if (_stage != _Stage.aiming || _busy) return;
    final trainer = ref.read(trainerProvider.notifier);
    final state = ref.read(trainerProvider);
    if (state.quantityOf(_ballSlug) <= 0) {
      ref.read(soundServiceProvider).error();
      _toast('No ${_ball.name} left — buy more in the shop.');
      return;
    }

    final tightness = _ring.value;
    _timing = timingBonus(tightness);
    final sound = ref.read(soundServiceProvider);
    sound.play('throw');
    sound.impact();

    _ring.stop();
    if (_useRazz && state.quantityOf('razz_berry') > 0) {
      trainer.consumeItem('razz_berry');
    }
    trainer.consumeBall(_ballSlug);

    setState(() {
      _stage = _Stage.throwing;
      _busy = true;
    });

    await _throw.forward(from: 0);
    if (!mounted) return;

    final caught = _random.nextDouble() < _chance;
    setState(() => _stage = _Stage.wobbling);

    _wobble.repeat(reverse: true);
    for (var i = 0; i < 3; i++) {
      setState(() => _wobbles = i + 1);
      sound.play('wobble', volume: 0.5);
      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
    }
    _wobble.stop();

    if (caught) {
      _registerCatch();
      return;
    }

    final species = ref
        .read(dexCatalogProvider)
        .speciesAt(widget.spawn.pokemon.dexNumber);
    final flee =
        _random.nextDouble() <
        fleeChance(
          catchRate: species?.catchRate ?? 45,
          rarity: widget.spawn.rarity,
        );

    if (!mounted) return;
    sound.failure();
    setState(() {
      _stage = flee ? _Stage.fled : _Stage.brokeFree;
      _busy = false;
    });
  }

  void _registerCatch() {
    if (_claimed) return;
    _claimed = true;
    final sound = ref.read(soundServiceProvider);
    final report = ref
        .read(trainerProvider.notifier)
        .recordCatch(
          pokemon: widget.spawn.pokemon,
          ball: _ball.name,
          zone: widget.spawn.zoneSlug,
          rarity: widget.spawn.rarity,
          random: _random,
        );
    sound.success();
    sound.cry(widget.spawn.pokemon.name.toLowerCase());
    _showResult(report);
  }

  Future<void> _showResult(CatchReport report) async {
    final pokemon = report.pokemon;
    if (!mounted) return;
    await showCelebration(
      context,
      title: pokemon.shiny ? 'SHINY ${pokemon.name.toUpperCase()}!' : 'Gotcha!',
      message: [
        if (pokemon.shiny)
          'A shiny ${pokemon.name} — 1 in 2,048 odds.'
        else
          '${pokemon.name} was caught.',
        if (report.newSpecies) 'New species registered in the Pokédex.',
        if (!report.joinedParty) 'Party is full, so they went to the PC.',
        '+${report.coins} coins · +${report.trainerXp} trainer XP',
      ].join('\n'),
      icon: pokemon.shiny
          ? Icons.auto_awesome_rounded
          : Icons.catching_pokemon_rounded,
      tint: pokemon.shiny
          ? AppTheme.shiny
          : TypePalette.of(pokemon.types.first),
      actionLabel: 'Nice',
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PokemonSprite(
            dexNumber: pokemon.dexNumber,
            fallbackTypes: pokemon.types,
            size: 74,
            shiny: pokemon.shiny,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lv. ${pokemon.level} · ${pokemon.nature}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 4,
                children: [
                  for (final type in pokemon.types)
                    TypeChip(type: type, dense: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(report);
  }

  void _retry() {
    _throw.reset();
    setState(() {
      _stage = _Stage.aiming;
      _wobbles = 0;
    });
    _ring
      ..reset()
      ..repeat();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spawn = widget.spawn.pokemon;
    final state = ref.watch(trainerProvider);
    final tint = TypePalette.of(spawn.types.first);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          color: scheme.surfaceContainerLow,
          border: Border.all(color: tint.withValues(alpha: 0.35)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'WILD ENCOUNTER',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.6,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  PillBadge(
                    label: widget.spawn.rarity.toUpperCase(),
                    color: tint,
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              _Arena(
                spawn: widget.spawn,
                stage: _stage,
                ring: _ring,
                throwAnimation: _throw,
                wobble: _wobble,
                wobbles: _wobbles,
                tint: tint,
                onTap: _stage == _Stage.aiming ? _throwBall : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final type in spawn.types)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: TypeChip(type: type),
                    ),
                  if (spawn.shiny) ...[
                    const SizedBox(width: 6),
                    const _ShinyBadge(),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _stage == _Stage.aiming
                  ? _AimingControls(
                      chance: _chance,
                      ballSlug: _ballSlug,
                      useRazz: _useRazz,
                      inventory: state.inventory,
                      onBall: (slug) {
                        ref.read(soundServiceProvider).tap();
                        setState(() => _ballSlug = slug);
                      },
                      onRazz: (value) {
                        ref.read(soundServiceProvider).tap();
                        setState(() => _useRazz = value);
                      },
                      onThrow: _throwBall,
                    )
                  : _StageMessage(
                      stage: _stage,
                      wobbles: _wobbles,
                      spawn: widget.spawn,
                      onRetry: _retry,
                      onLeave: () => Navigator.of(context).pop(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AimingControls extends StatelessWidget {
  const _AimingControls({
    required this.chance,
    required this.ballSlug,
    required this.useRazz,
    required this.inventory,
    required this.onBall,
    required this.onRazz,
    required this.onThrow,
  });

  final double chance;
  final String ballSlug;
  final bool useRazz;
  final Map<String, int> inventory;
  final ValueChanged<String> onBall;
  final ValueChanged<bool> onRazz;
  final VoidCallback onThrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final balls = ballCatalog.where((ball) => (inventory[ball.slug] ?? 0) > 0);
    final razz = inventory['razz_berry'] ?? 0;
    final difficulty = catchDifficulty(chance);

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Catch chance',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${(chance * 100).round()}% · $difficulty',
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: chance),
            duration: AppMotion.slow,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  chance > 0.5
                      ? AppTheme.teal
                      : chance > 0.25
                      ? AppTheme.gold
                      : scheme.error,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (balls.isEmpty)
          Text(
            'Your bag is empty. Buy balls in the shop.',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          )
        else
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: balls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final ball = balls.elementAt(index);
                final count = inventory[ball.slug] ?? 0;
                return _BallChip(
                  ball: ball,
                  count: count,
                  selected: ball.slug == ballSlug,
                  onTap: () => onBall(ball.slug),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: razz <= 0 ? null : () => onRazz(!useRazz),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: useRazz && razz > 0
                  ? AppTheme.rose.withValues(alpha: 0.16)
                  : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: useRazz && razz > 0
                    ? AppTheme.rose.withValues(alpha: 0.5)
                    : scheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.energy_savings_leaf_rounded,
                  size: 18,
                  color: useRazz && razz > 0
                      ? AppTheme.rose
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    razz > 0
                        ? 'Razz Berry · 1.5× chance'
                        : 'Razz Berry · none in the bag',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Text(
                  '×$razz',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Checkbox(
                  value: useRazz && razz > 0,
                  onChanged: razz <= 0 ? null : (v) => onRazz(v ?? false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: balls.isEmpty ? null : onThrow,
            icon: const Icon(Icons.catching_pokemon_rounded),
            label: const Text('Throw · tap the ring'),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap when the ring is tight for a timing bonus.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BallChip extends StatelessWidget {
  const _BallChip({
    required this.ball,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final BallDef ball;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 92,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.catching_pokemon_rounded, size: 22),
              const SizedBox(height: 4),
              Text(
                ball.shortName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '×$count · ${ball.multiplier}×',
                style: const TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageMessage extends StatelessWidget {
  const _StageMessage({
    required this.stage,
    required this.wobbles,
    required this.spawn,
    required this.onRetry,
    required this.onLeave,
  });

  final _Stage stage;
  final int wobbles;
  final WildSpawn spawn;
  final VoidCallback onRetry;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = spawn.pokemon.name;

    final (title, message) = switch (stage) {
      _Stage.throwing => ('Here it goes…', 'A clean throw.'),
      _Stage.wobbling => ('Wobble $wobbles of 3…', 'Will it hold?'),
      _Stage.brokeFree => (
        'It broke free!',
        '$name is still there. Try again.',
      ),
      _Stage.fled => ('$name fled!', 'That was your only chance at this one.'),
      _ => ('Ready', ''),
    };

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onLeave,
                child: const Text('Leave'),
              ),
            ),
            if (stage == _Stage.brokeFree) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Arena extends StatelessWidget {
  const _Arena({
    required this.spawn,
    required this.stage,
    required this.ring,
    required this.throwAnimation,
    required this.wobble,
    required this.wobbles,
    required this.tint,
    this.onTap,
  });

  final WildSpawn spawn;
  final _Stage stage;
  final Animation<double> ring;
  final Animation<double> throwAnimation;
  final Animation<double> wobble;
  final int wobbles;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = stage == _Stage.aiming;

    return SizedBox(
      height: 250,
      child: AnimatedContainer(
        duration: AppMotion.slow,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: [
              tint.withValues(alpha: 0.22),
              scheme.surfaceContainerLow.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([ring, throwAnimation, wobble]),
          builder: (context, _) {
            final throwing = stage == _Stage.throwing;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  CustomPaint(
                    size: const Size.square(206),
                    painter: _CatchRingPainter(
                      progress: ring.value,
                      color: tint,
                    ),
                  ),
                if (active)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SparklePainter(tint: tint, time: ring.value),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(0, 6 * math.sin(ring.value * math.pi * 2)),
                  child: AnimatedScale(
                    scale: throwing
                        ? 1 - throwAnimation.value * 0.5
                        : stage == _Stage.wobbling
                        ? 0.5
                        : 1,
                    duration: AppMotion.base,
                    curve: Curves.easeOut,
                    child: GestureDetector(
                      onTap: onTap,
                      child: PokemonSprite(
                        dexNumber: spawn.pokemon.dexNumber,
                        fallbackTypes: spawn.pokemon.types,
                        size: 136,
                        shiny: spawn.pokemon.shiny,
                      ),
                    ),
                  ),
                ),
                if (stage == _Stage.throwing)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ThrowPainter(
                        progress: throwAnimation.value,
                        color: tint,
                      ),
                    ),
                  ),
                if (stage == _Stage.wobbling)
                  Transform.rotate(
                    angle: math.sin(wobble.value * math.pi * 2) * 0.22,
                    child: const Icon(
                      Icons.catching_pokemon_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                if (stage == _Stage.wobbling || stage == _Stage.throwing)
                  Positioned(bottom: 16, child: PulseDots(color: tint)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PulseDots extends StatefulWidget {
  const PulseDots({super.key, required this.color});

  final Color color;

  @override
  State<PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<PulseDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Opacity(
                  opacity:
                      0.25 +
                      0.75 *
                          ((math.sin(
                                    (_controller.value * 2 * math.pi) - i * 0.9,
                                  ) +
                                  1) /
                              2),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CatchRingPainter extends CustomPainter {
  _CatchRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.width / 2;
    final radius = base * (0.98 - 0.4 * progress);
    final alpha = 0.16 + 0.55 * progress;

    canvas.drawCircle(
      center,
      base * 0.94,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = color.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant _CatchRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.tint, required this.time});

  final Color tint;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..color = tint.withValues(alpha: 0.5);
    for (var i = 0; i < 7; i++) {
      final angle = time * 2 * math.pi + i * (2 * math.pi / 7);
      final distance =
          size.width * (0.28 + 0.16 * math.sin(time * math.pi * 2 + i));
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(point, 1.6 + (i % 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

/// Ball arcs from the trainer's hand to the target.
class _ThrowPainter extends CustomPainter {
  _ThrowPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.16, size.height * 0.92);
    final end = Offset(size.width * 0.5, size.height * 0.46);
    final control = Offset(size.width * 0.5, size.height * 0.02);
    final t = progress;
    final point = Offset(
      (1 - t) * (1 - t) * start.dx +
          2 * (1 - t) * t * control.dx +
          t * t * end.dx,
      (1 - t) * (1 - t) * start.dy +
          2 * (1 - t) * t * control.dy +
          t * t * end.dy,
    );

    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.rotate(progress * math.pi * 5);
    final radius = 13.0;
    canvas.drawCircle(Offset.zero, radius, Paint()..color = Colors.white);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFFE84B4B),
    );
    canvas.drawLine(
      Offset(-radius, 0),
      Offset(radius, 0),
      Paint()
        ..color = const Color(0xFF2B2B2B)
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 0.26,
      Paint()..color = color.withValues(alpha: 0.9),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThrowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ShinyBadge extends StatelessWidget {
  const _ShinyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.shiny.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.shiny.withValues(alpha: 0.55)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: AppTheme.shiny),
          SizedBox(width: 4),
          Text(
            'Shiny',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.shiny,
            ),
          ),
        ],
      ),
    );
  }
}
