import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dex_repository.dart';
import '../../data/game/wild.dart';
import '../../data/game/wild_battle.dart';
import '../../data/models/pokemon.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/motion/motion.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/hp_bar.dart';
import '../../ui/widgets/pokemon_sprite.dart';
import '../../ui/widgets/type_chip.dart';
import 'catch_sheet.dart';

class WildBattleResult {
  const WildBattleResult({
    this.catchReport,
    this.won = false,
    this.ran = false,
    this.lost = false,
  });

  final CatchReport? catchReport;
  final bool won;
  final bool ran;
  final bool lost;

  bool get caught => catchReport != null;
}

Future<WildBattleResult?> showWildBattle(
  BuildContext context,
  WildSpawn spawn,
) {
  return Navigator.of(context).push<WildBattleResult>(
    AppPageRoute<WildBattleResult>(
      builder: (_) => WildBattleScreen(spawn: spawn),
    ),
  );
}

class WildBattleScreen extends ConsumerStatefulWidget {
  const WildBattleScreen({super.key, required this.spawn});

  final WildSpawn spawn;

  @override
  ConsumerState<WildBattleScreen> createState() => _WildBattleScreenState();
}

class _WildBattleScreenState extends ConsumerState<WildBattleScreen> {
  WildBattle? _battle;
  bool _showMoves = false;
  bool _busy = false;
  bool _resolved = false;
  final List<String> _turnLog = [];

  @override
  void initState() {
    super.initState();
    final trainer = ref.read(trainerProvider);
    Pokemon? lead;
    for (final pokemon in trainer.party) {
      if (!pokemon.isFainted) {
        lead = pokemon;
        break;
      }
    }
    if (lead == null) return;
    final catalog = ref.read(dexCatalogProvider);
    _battle = WildBattle(
      player: lead,
      wild: widget.spawn.pokemon,
      moves: catalog.moves,
    );
    _turnLog.add(_battle!.lastMessage);
  }

  void _setBusy(bool value) {
    if (!mounted) return;
    setState(() => _busy = value);
  }

  void _append(List<String> lines) {
    if (!mounted) return;
    setState(() {
      _turnLog.addAll(lines);
      if (_turnLog.length > 8) {
        _turnLog.removeRange(0, _turnLog.length - 8);
      }
    });
  }

  void _persistActiveHp() {
    final battle = _battle;
    if (battle == null) return;
    ref
        .read(trainerProvider.notifier)
        .setCurrentHp(battle.player.id, battle.playerHp);
  }

  Future<void> _sightline() async {
    await Future<void>.delayed(const Duration(milliseconds: 480));
  }

  Future<void> _afterTurn() async {
    final battle = _battle;
    if (battle == null) return;
    _persistActiveHp();
    await _sightline();
    if (!mounted) return;

    if (battle.wildFainted) {
      await _win();
      return;
    }
    if (battle.playerFainted) {
      await _handleFaint();
    }
  }

  Future<void> _chooseMove(BattleMoveSlot slot) async {
    final battle = _battle;
    if (battle == null || _busy || battle.over) return;
    if (!slot.usable) return;

    _setBusy(true);
    ref.read(soundServiceProvider).tap();
    final lines = battle.useMove(slot.move.name);
    _append(lines);
    setState(() => _showMoves = false);
    await _afterTurn();
    _setBusy(false);
  }

  Future<void> _openCatch() async {
    final battle = _battle;
    if (battle == null || _busy || battle.over) return;
    _setBusy(true);
    final weakened = WildSpawn(
      pokemon: battle.catchTarget,
      rarity: widget.spawn.rarity,
      zoneSlug: widget.spawn.zoneSlug,
      spawnedAt: widget.spawn.spawnedAt,
      expiresAt: widget.spawn.expiresAt,
    );
    final report = await showCatchSheet(context, weakened);
    if (!mounted) return;
    if (report != null) {
      _resolved = true;
      Navigator.of(context).pop(WildBattleResult(catchReport: report));
      return;
    }
    _setBusy(false);
  }

  Future<void> _switchPokemon() async {
    final battle = _battle;
    if (battle == null || _busy || battle.over) return;
    final party = ref
        .read(trainerProvider)
        .party
        .where(
          (pokemon) => !pokemon.isFainted && pokemon.id != battle.player.id,
        )
        .toList(growable: false);
    if (party.isEmpty) {
      _toast('No other Pokémon can battle.');
      return;
    }

    final chosen = await showModalBottomSheet<Pokemon>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Send out…',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final pokemon in party)
                ListTile(
                  leading: PokemonSprite(
                    dexNumber: pokemon.dexNumber,
                    fallbackTypes: pokemon.types,
                    size: 42,
                    shiny: pokemon.shiny,
                  ),
                  title: Text(pokemon.displayName),
                  subtitle: Text(
                    'Lv. ${pokemon.level} · ${pokemon.currentHp}/${pokemon.maxHp} HP',
                  ),
                  trailing: HpBar(value: pokemon.hpFraction, height: 5),
                  onTap: () => Navigator.of(sheetContext).pop(pokemon),
                ),
            ],
          ),
        );
      },
    );
    if (chosen == null || !mounted) return;

    _setBusy(true);
    _persistActiveHp();
    final lines = battle.switchTo(chosen);
    _append(lines);
    _persistActiveHp();
    await _sightline();
    if (battle.playerFainted) await _handleFaint();
    _setBusy(false);
  }

  Future<void> _run() async {
    final battle = _battle;
    if (battle == null || _busy || battle.over) return;
    _setBusy(true);
    final lines = battle.attemptRun();
    _append(lines);
    _persistActiveHp();
    if (battle.ran) {
      _resolved = true;
      if (mounted) {
        Navigator.of(context).pop(const WildBattleResult(ran: true));
      }
      return;
    }
    await _afterTurn();
    _setBusy(false);
  }

  Future<void> _handleFaint() async {
    final battle = _battle;
    if (battle == null || _resolved) return;
    Pokemon? next;
    for (final pokemon in ref.read(trainerProvider).party) {
      if (!pokemon.isFainted && pokemon.id != battle.player.id) {
        next = pokemon;
        break;
      }
    }
    if (next == null) {
      battle.markLost();
      await _lose();
      return;
    }
    final lines = battle.switchTo(next, wildAttacks: false);
    _append(lines);
    _persistActiveHp();
    _toast('${next.displayName}, I choose you!');
  }

  Future<void> _win() async {
    final battle = _battle;
    if (battle == null || _resolved) return;
    _resolved = true;
    final trainer = ref.read(trainerProvider.notifier);
    trainer.gainBattleRewards(won: true);
    final catalog = ref.read(dexCatalogProvider);
    final baseExp = catalog.speciesAt(battle.wild.dexNumber)?.baseExp ?? 50;
    final xp = xpFromWildWin(baseExp: baseExp, level: battle.wild.level);
    final levelReport = trainer.grantXp(battle.player.id, xp);
    ref.read(soundServiceProvider).success();
    ref.read(soundServiceProvider).cry(battle.wild.name.toLowerCase());

    if (!mounted) return;
    await showCelebration(
      context,
      title: 'Wild ${battle.wild.name} defeated!',
      message: [
        '${battle.player.displayName} earned $xp XP.',
        if (levelReport != null && levelReport.levelsGained > 0)
          'Reached level ${levelReport.pokemon.level}!',
        if (levelReport?.learnedMoves.isNotEmpty ?? false)
          'Learned ${levelReport!.learnedMoves.join(', ')}.',
        if (levelReport?.evolvedInto != null)
          'Evolved into ${levelReport!.evolvedInto!.name}!',
        '+180 coins · +140 trainer XP',
      ].join('\n'),
      icon: Icons.emoji_events_rounded,
      tint: TypePalette.of(battle.wild.types.first),
      actionLabel: 'Nice',
    );
    if (mounted) {
      Navigator.of(context).pop(const WildBattleResult(won: true));
    }
  }

  Future<void> _lose() async {
    final battle = _battle;
    if (battle == null || _resolved) return;
    _resolved = true;
    ref.read(trainerProvider.notifier).gainBattleRewards(won: false);
    ref.read(soundServiceProvider).failure();
    if (!mounted) return;
    await showCelebration(
      context,
      title: 'You blacked out!',
      message:
          'Your party needs a rest. Heal up in the Party tab and try again.',
      icon: Icons.hotel_rounded,
      tint: Theme.of(context).colorScheme.error,
      actionLabel: 'Okay',
    );
    if (mounted) {
      Navigator.of(context).pop(const WildBattleResult(lost: true));
    }
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
    final battle = _battle;

    if (battle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wild battle')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Every Pokémon in your party has fainted.\n'
              'Heal up in the Party tab before looking for wild Pokémon.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final wild = battle.wild;
    final active = battle.player;
    final wildTint = TypePalette.of(wild.types.first);
    final activeTint = TypePalette.of(active.types.first);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WILD BATTLE'),
        leading: IconButton(
          tooltip: 'Leave battle',
          onPressed: () {
            ref.read(soundServiceProvider).tap();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              wildTint.withValues(alpha: 0.22),
              scheme.surface,
              activeTint.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Row(
                children: [
                  PillBadge(
                    label: widget.spawn.rarity.toUpperCase(),
                    color: wildTint,
                  ),
                  const Spacer(),
                  if (wild.shiny)
                    const PillBadge(
                      label: 'SHINY',
                      color: AppTheme.shiny,
                      icon: Icons.auto_awesome_rounded,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _BattlerCard(
                pokemon: wild,
                hp: battle.wildHp,
                tint: wildTint,
                alignRight: true,
                label: 'WILD',
                spriteSize: 126,
              ),
              const SizedBox(height: AppSpacing.md),
              _BattlerCard(
                pokemon: active,
                hp: battle.playerHp,
                tint: activeTint,
                alignRight: false,
                label: 'YOUR POKÉMON',
                spriteSize: 110,
              ),
              const SizedBox(height: AppSpacing.md),
              _BattleLog(lines: _turnLog),
              const SizedBox(height: AppSpacing.md),
              if (_showMoves)
                _MoveGrid(
                  moves: battle.playerMoves,
                  busy: _busy,
                  onMove: _chooseMove,
                  onBack: () => setState(() => _showMoves = false),
                )
              else
                _ActionGrid(
                  busy: _busy,
                  canFight: battle.playerMoves.any((slot) => slot.usable),
                  onFight: () {
                    ref.read(soundServiceProvider).tap();
                    setState(() => _showMoves = true);
                  },
                  onCatch: _openCatch,
                  onSwitch: _switchPokemon,
                  onRun: _run,
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Wild Pokémon stay for 90 seconds. Weaken them to improve '
                'your catch chance.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattlerCard extends StatelessWidget {
  const _BattlerCard({
    required this.pokemon,
    required this.hp,
    required this.tint,
    required this.alignRight,
    required this.label,
    required this.spriteSize,
  });

  final Pokemon pokemon;
  final int hp;
  final Color tint;
  final bool alignRight;
  final String label;
  final double spriteSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fraction = pokemon.maxHp <= 0
        ? 0.0
        : (hp / pokemon.maxHp).clamp(0.0, 1.0);

    final info = Expanded(
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.3,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            pokemon.displayName,
            textAlign: alignRight ? TextAlign.left : TextAlign.right,
            style: theme.textTheme.titleLarge,
          ),
          Text(
            'Lv. ${pokemon.level} · $hp/${pokemon.maxHp} HP',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          HpBar(value: fraction, height: 7),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            alignment: alignRight ? WrapAlignment.start : WrapAlignment.end,
            children: [
              for (final type in pokemon.types)
                TypeChip(type: type, dense: true),
            ],
          ),
        ],
      ),
    );

    final sprite = GlowPulse(
      color: tint,
      min: 0.25,
      max: 0.5,
      child: PokemonSprite(
        dexNumber: pokemon.dexNumber,
        fallbackTypes: pokemon.types,
        size: spriteSize,
        shiny: pokemon.shiny,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: scheme.surfaceContainerLow.withValues(alpha: 0.78),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: alignRight
            ? [info, const SizedBox(width: AppSpacing.sm), sprite]
            : [sprite, const SizedBox(width: AppSpacing.sm), info],
      ),
    );
  }
}

class _BattleLog extends StatelessWidget {
  const _BattleLog({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 116,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView(
        reverse: true,
        children: [
          for (final line in lines.reversed.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                line,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.busy,
    required this.canFight,
    required this.onFight,
    required this.onCatch,
    required this.onSwitch,
    required this.onRun,
  });

  final bool busy;
  final bool canFight;
  final VoidCallback onFight;
  final VoidCallback onCatch;
  final VoidCallback onSwitch;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Fight',
                icon: Icons.sports_martial_arts_rounded,
                tint: scheme.primary,
                enabled: !busy && canFight,
                onTap: onFight,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionButton(
                label: 'Catch',
                icon: Icons.catching_pokemon_rounded,
                tint: AppTheme.rose,
                enabled: !busy,
                onTap: onCatch,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Switch',
                icon: Icons.swap_horiz_rounded,
                tint: AppTheme.teal,
                enabled: !busy,
                onTap: onSwitch,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionButton(
                label: 'Run',
                icon: Icons.directions_run_rounded,
                tint: scheme.onSurfaceVariant,
                enabled: !busy,
                onTap: onRun,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.tint,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: FilledButton.tonalIcon(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: tint.withValues(alpha: 0.14),
          foregroundColor: tint,
          minimumSize: const Size(0, 48),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _MoveGrid extends StatelessWidget {
  const _MoveGrid({
    required this.moves,
    required this.busy,
    required this.onMove,
    required this.onBack,
  });

  final List<BattleMoveSlot> moves;
  final bool busy;
  final ValueChanged<BattleMoveSlot> onMove;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.5,
          children: [
            for (final slot in moves)
              _MoveButton(slot: slot, busy: busy, onTap: () => onMove(slot)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: busy ? null : onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 17),
          label: Text(
            'Back',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.slot,
    required this.busy,
    required this.onTap,
  });

  final BattleMoveSlot slot;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = TypePalette.of(slot.move.type);
    final enabled = !busy && slot.usable;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: tint.withValues(alpha: 0.14),
            border: Border.all(color: tint.withValues(alpha: 0.38)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.move.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${slot.move.type.label} · ${slot.pp}/${slot.maxPp} PP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
