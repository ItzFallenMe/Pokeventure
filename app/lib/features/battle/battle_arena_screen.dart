import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/battle_api.dart';
import '../../data/battle_log.dart';
import '../../data/dex_repository.dart';
import '../../data/friend_battle_api.dart';
import '../../data/models/battle.dart';
import '../../data/models/dex_entry.dart';
import '../../data/models/move_entry.dart';
import '../../data/models/pokemon_type.dart';
import '../../data/type_chart.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/hp_bar.dart';
import '../../ui/widgets/pokemon_sprite.dart';

class BattleArenaScreen extends ConsumerStatefulWidget {
  const BattleArenaScreen({super.key, required this.initial, this.friend});

  final BattleSnapshot initial;

  /// Set for a human-vs-human battle; the screen then polls for the friend's
  /// moves instead of the server waiting for both players.
  final FriendBattleConnection? friend;

  @override
  ConsumerState<BattleArenaScreen> createState() => _BattleArenaScreenState();
}

class _BattleArenaScreenState extends ConsumerState<BattleArenaScreen> {
  late BattleSnapshot _snapshot = widget.initial;
  bool _busy = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.friend != null) {
      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 1500),
        (_) => _poll(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final friend = widget.friend;
    if (friend == null || _busy || !mounted) return;

    try {
      final next = await friend.refresh();
      if (!mounted) return;
      final changed =
          next.turn != _snapshot.turn ||
          next.canAct != _snapshot.canAct ||
          next.ended != _snapshot.ended ||
          next.waiting != _snapshot.waiting ||
          next.log.length != _snapshot.log.length ||
          next.active?.hp != _snapshot.active?.hp ||
          next.opponent?.hp != _snapshot.opponent?.hp;

      if (changed) setState(() => _snapshot = next);
      if (next.ended) _pollTimer?.cancel();
    } on BattleApiException {
      // Transient polling failures are expected on flaky mobile networks; the
      // next tick tries again.
    }
  }

  Future<void> _submit(String choice) async {
    if (_busy || _snapshot.ended) return;

    setState(() => _busy = true);
    try {
      final friend = widget.friend;
      final next = friend != null
          ? await friend.choose(choice)
          : await ref.read(battleApiProvider).choose(_snapshot.id, choice);
      if (!mounted) return;
      setState(() {
        _snapshot = next;
        _busy = false;
      });
      if (next.ended) _pollTimer?.cancel();
      if (next.forceSwitch && !next.ended) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openSwitch();
        });
      }
    } on BattleApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openSwitch() async {
    final reviving = _snapshot.active?.reviving ?? false;
    final bench = _snapshot.team
        .where(
          (member) =>
              !member.active && (reviving ? member.fainted : !member.fainted),
        )
        .toList(growable: false);
    if (bench.isEmpty || _busy) return;

    final slot = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  reviving ? 'Revive who?' : 'Send out who?',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              for (final member in bench)
                ListTile(
                  leading: PokemonSprite(
                    dexNumber: _dexNumber(member.species),
                    fallbackTypes: const [],
                    size: 40,
                  ),
                  title: Text(member.species),
                  subtitle: Text(
                    reviving
                        ? 'Lv. ${member.level} · fainted, ready to revive'
                        : 'Lv. ${member.level} · ${member.hpLabel}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(sheetContext).pop(member.slot),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );

    if (slot != null) await _submit('switch $slot');
  }

  int _dexNumber(String species) {
    if (!SpriteConfig.enabled) return 0;
    final lookup = ref.read(dexLookupProvider).value;
    return lookup?[species.toLowerCase()]?.number ?? 0;
  }

  DexEntry? _dexEntry(String species) {
    if (!SpriteConfig.enabled) return null;
    return ref.watch(dexLookupProvider).value?[species.toLowerCase()];
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave battle?'),
        content: const Text(
          'The battle continues on the server until it expires. '
          'Leaving counts as a forfeit for this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Forfeit'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _snapshot.active;
    final opponent = _snapshot.opponent;
    final moves =
        ref.watch(moveLookupProvider).value ?? const <String, MoveEntry>{};
    final defenderTypes =
        _dexEntry(opponent?.species ?? '')?.types ?? const <PokemonType>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.friend == null ? 'Battle' : 'Friend battle'} · '
          'Turn ${_snapshot.turn}',
        ),
        scrolledUnderElevation: 0,
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Leave battle',
            onPressed: _snapshot.ended
                ? () => Navigator.of(context).pop()
                : _confirmLeave,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  _CombatantCard(
                    label: 'AI Trainer',
                    species: opponent?.species ?? '—',
                    level: opponent?.level ?? 50,
                    hp: opponent?.hp ?? 1,
                    hpLabel: opponent?.hpLabel ?? '—',
                    status: opponent?.status,
                    fainted: opponent?.fainted ?? false,
                    dexEntry: _dexEntry(opponent?.species ?? ''),
                    reverse: false,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LogCard(log: _snapshot.log),
                  const SizedBox(height: AppSpacing.md),
                  _CombatantCard(
                    label: 'You',
                    species: active?.species ?? '—',
                    level: active?.level ?? 50,
                    hp: active?.hp ?? 0,
                    hpLabel: active?.hpLabel ?? '—',
                    status: active?.status,
                    fainted: active?.fainted ?? false,
                    dexEntry: _dexEntry(active?.species ?? ''),
                    reverse: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PartyDots(team: _snapshot.team),
                ],
              ),
            ),
            _ActionPanel(
              snapshot: _snapshot,
              busy: _busy,
              onMove: (index) => _submit('move $index'),
              onSwitch: _openSwitch,
              onDone: () => Navigator.of(context).pop(_snapshot.playerWon),
              playerWon: _snapshot.playerWon,
              theme: theme,
              moves: moves,
              defenderTypes: defenderTypes,
            ),
          ],
        ),
      ),
    );
  }
}

class _CombatantCard extends StatelessWidget {
  const _CombatantCard({
    required this.label,
    required this.species,
    required this.level,
    required this.hp,
    required this.hpLabel,
    required this.status,
    required this.fainted,
    required this.dexEntry,
    required this.reverse,
  });

  final String label;
  final String species;
  final int level;
  final double hp;
  final String hpLabel;
  final String? status;
  final bool fainted;
  final DexEntry? dexEntry;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = dexEntry == null
        ? scheme.primary
        : TypePalette.of(dexEntry!.types.first);

    final info = Column(
      crossAxisAlignment: reverse
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: reverse
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            PillBadge(label: 'Lv. $level'),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          species,
          textAlign: reverse ? TextAlign.left : TextAlign.right,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: fainted ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HpBar(value: fainted ? 0 : hp, height: 8),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: reverse
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            Text(
              fainted ? 'Fainted' : hpLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (status != null && status!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    final sprite = Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [tint.withValues(alpha: 0.22), tint.withValues(alpha: 0.02)],
        ),
      ),
      alignment: Alignment.center,
      child: PokemonSprite(
        dexNumber: dexEntry?.number ?? 0,
        fallbackTypes: dexEntry?.types ?? const [],
        size: 96,
        artwork: true,
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: reverse
              ? [
                  sprite,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: info),
                ]
              : [
                  Expanded(child: info),
                  const SizedBox(width: AppSpacing.md),
                  sprite,
                ],
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});

  final List<String> log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = log
        .map(prettifyBattleLogLine)
        .whereType<String>()
        .toList(growable: false);
    final visible = lines.length > 5 ? lines.sublist(lines.length - 5) : lines;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BATTLE LOG',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visible.isEmpty)
            Text(
              'The battle begins…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          for (final line in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PartyDots extends StatelessWidget {
  const _PartyDots({required this.team});

  final List<BattleMember> team;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final member in team)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Tooltip(
              message: '${member.species} · ${member.condition}',
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: member.fainted
                      ? scheme.outlineVariant
                      : member.active
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.snapshot,
    required this.busy,
    required this.onMove,
    required this.onSwitch,
    required this.onDone,
    required this.playerWon,
    required this.theme,
    required this.moves,
    required this.defenderTypes,
  });

  final BattleSnapshot snapshot;
  final bool busy;
  final void Function(int index) onMove;
  final VoidCallback onSwitch;
  final VoidCallback onDone;
  final bool playerWon;
  final ThemeData theme;
  final Map<String, MoveEntry> moves;
  final List<PokemonType> defenderTypes;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final battleMoves = snapshot.active?.moves ?? const <BattleMove>[];

    Widget content;
    if (snapshot.ended) {
      content = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerWon ? 'Victory!' : 'Defeat',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: playerWon ? scheme.tertiary : scheme.error,
                  ),
                ),
                Text(
                  playerWon
                      ? 'Your team held the line.'
                      : 'The AI Trainer takes this one.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(onPressed: onDone, child: const Text('Done')),
        ],
      );
    } else if (snapshot.forceSwitch) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            snapshot.active?.reviving ?? false
                ? 'Revival Blessing: pick a fainted Pokémon to bring back.'
                : 'Your Pokémon fainted. Choose a replacement.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onSwitch,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(
                (snapshot.active?.reviving ?? false)
                    ? 'Choose who to revive'
                    : 'Choose a Pokémon',
              ),
            ),
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < 2; row++)
            Padding(
              padding: EdgeInsets.only(bottom: row == 0 ? 8 : 10),
              child: Row(
                children: [
                  for (var column = 0; column < 2; column++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: column == 0 ? AppSpacing.sm : 0,
                        ),
                        child: _MoveButton(
                          move: battleMoves.length > row * 2 + column
                              ? battleMoves[row * 2 + column]
                              : null,
                          entry: battleMoves.length > row * 2 + column
                              ? moves[battleMoves[row * 2 + column].name
                                    .toLowerCase()]
                              : null,
                          defenderTypes: defenderTypes,
                          index: row * 2 + column + 1,
                          enabled:
                              !busy &&
                              snapshot.canAct &&
                              battleMoves.isNotEmpty,
                          onPressed: onMove,
                          theme: theme,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy || !snapshot.canAct ? null : onSwitch,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Switch Pokémon'),
            ),
          ),
          if (!snapshot.canAct && !busy)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Waiting for the opponent…',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: content,
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.move,
    required this.entry,
    required this.defenderTypes,
    required this.index,
    required this.enabled,
    required this.onPressed,
    required this.theme,
  });

  final BattleMove? move;
  final MoveEntry? entry;
  final List<PokemonType> defenderTypes;
  final int index;
  final bool enabled;
  final void Function(int index) onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final usable = enabled && (move?.usable ?? false);
    final type = entry?.type;
    final brightness = theme.brightness;
    final effectiveness = type == null || defenderTypes.isEmpty
        ? null
        : typeEffectiveness(type, defenderTypes);

    final foreground = !usable
        ? scheme.onSurfaceVariant
        : type == null
        ? scheme.onPrimaryContainer
        : TypePalette.text(type, brightness);
    final background = !usable
        ? scheme.surfaceContainerHighest
        : type == null
        ? scheme.primaryContainer.withValues(alpha: 0.75)
        : TypePalette.of(type).withValues(alpha: 0.22);

    return Tooltip(
      message: entry == null
          ? (move?.name ?? '')
          : '${entry!.category} · ${entry!.isStatus ? 'no power' : '${entry!.power} power'}'
                '${entry!.accuracy == null ? '' : ' · ${entry!.accuracy}% accuracy'}',
      waitDuration: const Duration(milliseconds: 600),
      child: FilledButton.tonal(
        onPressed: usable ? () => onPressed(index) : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 58),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          alignment: Alignment.centerLeft,
          backgroundColor: background,
          disabledBackgroundColor: background,
          side: type == null
              ? null
              : BorderSide(
                  color: TypePalette.of(
                    type,
                  ).withValues(alpha: usable ? 0.55 : 0.2),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    move?.name ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ),
                if (effectiveness != null)
                  _EffectivenessTag(multiplier: effectiveness, theme: theme),
              ],
            ),
            Text(
              move == null
                  ? ''
                  : '${type?.label ?? '—'} · PP ${move!.pp}/${move!.maxPp}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: foreground.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EffectivenessTag extends StatelessWidget {
  const _EffectivenessTag({required this.multiplier, required this.theme});

  final double multiplier;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final color = multiplier > 1
        ? scheme.tertiary
        : multiplier < 1
        ? scheme.error
        : scheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        effectivenessLabel(multiplier),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
