import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pokemon.dart';
import '../../state/party_provider.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/pokemon_orb.dart';
import '../../ui/widgets/type_chip.dart';

Future<void> showCatchSheet(BuildContext context, Pokemon spawn) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => CatchSheet(spawn: spawn),
  );
}

enum _Stage { aiming, thrown, caught, fled }

class _Ball {
  const _Ball(this.name, this.shortName, this.rate);

  final String name;
  final String shortName;
  final double rate;
}

const _balls = <_Ball>[
  _Ball('Poké Ball', 'Poké', 0.62),
  _Ball('Great Ball', 'Great', 0.74),
  _Ball('Ultra Ball', 'Ultra', 0.84),
];

class CatchSheet extends ConsumerStatefulWidget {
  const CatchSheet({super.key, required this.spawn});

  final Pokemon spawn;

  @override
  ConsumerState<CatchSheet> createState() => _CatchSheetState();
}

class _CatchSheetState extends ConsumerState<CatchSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  final Random _random = Random();

  _Stage _stage = _Stage.aiming;
  int _ballIndex = 0;
  double _timingBonus = 1;
  bool _claimed = false;

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  Future<void> _throw() async {
    if (_stage != _Stage.aiming) return;

    final tightness = _ring.value;
    _ring.stop();
    final bonus = tightness > 0.55 ? 1.15 : 1.0;

    setState(() {
      _stage = _Stage.thrown;
      _timingBonus = bonus;
    });
    HapticFeedback.lightImpact();

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final chance =
        (_balls[_ballIndex].rate * _timingBonus).clamp(0.05, 0.95);
    final caught = _random.nextDouble() < chance;

    setState(() => _stage = caught ? _Stage.caught : _Stage.fled);
    HapticFeedback.mediumImpact();
  }

  void _retry() {
    setState(() => _stage = _Stage.aiming);
    _ring.repeat();
  }

  void _claim() {
    if (_claimed) return;
    _claimed = true;

    final joinedParty =
        ref.read(partyProvider.notifier).addCaught(widget.spawn);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          joinedParty
              ? '${widget.spawn.name} joined your party!'
              : '${widget.spawn.name} was sent to the PC — party is full.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spawn = widget.spawn;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'WILD ENCOUNTER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            _Arena(
              spawn: spawn,
              stage: _stage,
              ring: _ring,
              onTap: _stage == _Stage.aiming ? _throw : null,
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
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.emphasizedDecelerate,
              child: _stageContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spawn = widget.spawn;

    switch (_stage) {
      case _Stage.aiming:
        return Column(
          key: const ValueKey('aim'),
          children: [
            Text(
              '${spawn.name} appeared!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap when the ring is tight for a bonus. Throwing now: '
              '${_balls[_ballIndex].name}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                for (var i = 0; i < _balls.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == _balls.length - 1 ? 0 : AppSpacing.sm,
                      ),
                      child: _BallOption(
                        ball: _balls[i],
                        selected: i == _ballIndex,
                        onTap: () => setState(() => _ballIndex = i),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _throw,
                icon: const Icon(Icons.catching_pokemon_rounded),
                label: const Text('Throw'),
              ),
            ),
          ],
        );

      case _Stage.thrown:
        return Column(
          key: const ValueKey('thrown'),
          children: [
            Text('The ball is wobbling…', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Wobble, wobble…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        );

      case _Stage.caught:
        return Column(
          key: const ValueKey('caught'),
          children: [
            Text('Gotcha!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              spawn.shiny
                  ? 'A shiny ${spawn.name} was added to your collection.'
                  : '${spawn.name} was caught.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _claim,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  ref.watch(partyProvider).hasSpace
                      ? 'Add to party'
                      : 'Send to PC',
                ),
              ),
            ),
          ],
        );

      case _Stage.fled:
        return Column(
          key: const ValueKey('fled'),
          children: [
            Text('It broke free!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${spawn.name} fled into the grass.',
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Leave'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _retry,
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

class _Arena extends StatelessWidget {
  const _Arena({
    required this.spawn,
    required this.stage,
    required this.ring,
    this.onTap,
  });

  final Pokemon spawn;
  final _Stage stage;
  final Animation<double> ring;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 208,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (stage == _Stage.aiming)
            AnimatedBuilder(
              animation: ring,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size.square(196),
                  painter: _CatchRingPainter(
                    progress: ring.value,
                    color: scheme.primary,
                  ),
                );
              },
            ),
          AnimatedScale(
            scale: stage == _Stage.thrown ? 0.86 : 1,
            duration: AppMotion.base,
            curve: AppMotion.spring,
            child: GestureDetector(
              onTap: onTap,
              child: PokemonOrb(
                pokemon: spawn,
                size: 118,
                active: stage == _Stage.aiming,
              ),
            ),
          ),
        ],
      ),
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
    final radius = base * (0.98 - 0.38 * progress);
    final alpha = 0.16 + 0.5 * progress;

    canvas.drawCircle(
      center,
      base * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.1),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = color.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(covariant _CatchRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _BallOption extends StatelessWidget {
  const _BallOption({
    required this.ball,
    required this.selected,
    required this.onTap,
  });

  final _Ball ball;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
          children: [
            Icon(
              Icons.catching_pokemon_rounded,
              size: 22,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              ball.shortName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(ball.rate * 100).round()}% base',
              style: TextStyle(
                fontSize: 9,
                color: selected
                    ? scheme.onPrimaryContainer.withValues(alpha: 0.7)
                    : scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
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
