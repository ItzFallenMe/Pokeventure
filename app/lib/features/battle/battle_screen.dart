import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/battle_api.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/common.dart';
import 'battle_arena_screen.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key, this.onOpenSocial});

  /// Switches to the Social tab, where friend invites live.
  final VoidCallback? onOpenSocial;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  static const _formats = <(String, String)>[
    ('Random Battle · Gen 9', 'gen9randombattle'),
    ('Random Battle · Gen 8', 'gen8randombattle'),
  ];
  int _format = 0;
  bool _queueing = false;

  Future<void> _queue() async {
    if (_queueing) return;
    setState(() => _queueing = true);

    try {
      final sound = ref.read(soundServiceProvider);
      sound.tap();
      final snapshot = await ref
          .read(battleApiProvider)
          .createBattle(format: _formats[_format].$2);
      if (!mounted) return;
      final won = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => BattleArenaScreen(initial: snapshot),
        ),
      );
      if (!mounted || won == null) return;
      ref.read(trainerProvider.notifier).gainBattleRewards(won: won);
      if (won) {
        sound.success();
      } else {
        sound.failure();
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              won
                  ? 'Battle won · +180 coins · +140 trainer XP'
                  : 'Battle lost · +40 coins · +30 trainer XP',
            ),
          ),
        );
    } on BattleApiException catch (error) {
      ref.read(soundServiceProvider).error();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${error.message}\n\n'
              'Start the server with: cd server && npm start',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _queueing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final party = ref.watch(trainerProvider).party;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          StaggeredEntrance(
            index: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Battle', style: theme.textTheme.displaySmall),
                Text(
                  'Real Showdown mechanics, server-side.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(index: 1, child: const _SeasonCard()),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 2,
            child: SectionHeader(
              title: 'Choose a format',
              trailingLabel: '${party.length}/6 ready',
            ),
          ),
          StaggeredEntrance(
            index: 3,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < _formats.length; i++)
                  ChoiceChip(
                    label: Text(_formats[i].$1),
                    selected: i == _format,
                    onSelected: (_) => setState(() => _format = i),
                    showCheckmark: false,
                    selectedColor: scheme.primaryContainer,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i == _format
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 4,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _queueing ? null : _queue,
                icon: _queueing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt_rounded),
                label: Text(
                  _queueing
                      ? 'Connecting…'
                      : 'Battle AI · ${_formats[_format].$1}',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 5,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        size: 20,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Battle a friend',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Share an invite code or QR; both phones play the '
                            'same engine.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.tonal(
                      onPressed: widget.onOpenSocial,
                      child: const Text('Open Social'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 6,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How a battle runs',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _Rule(
                      icon: Icons.dns_rounded,
                      text:
                          'Every turn is resolved by the Showdown engine on '
                          'our server — the app only renders what it is told.',
                    ),
                    const _Rule(
                      icon: Icons.groups_2_rounded,
                      text:
                          'Bring your party of six. Team preview, switching '
                          'and fainting follow the format rules.',
                    ),
                    const _Rule(
                      icon: Icons.timer_outlined,
                      text:
                          'Turn timer, reconnect and ranked rating arrive with '
                          'accounts; this build plays the AI.',
                    ),
                    const _Rule(
                      icon: Icons.casino_rounded,
                      text:
                          'Random battles generate both teams. Party-based '
                          'ranked formats need accounts and team validation.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 7,
            child: Card(
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.movie_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                title: const Text(
                  'Replays · M4',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Recording and sharing arrive with battle history.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final white = Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.alphaBlend(
              scheme.tertiary.withValues(alpha: 0.7),
              scheme.primary,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PillBadge(label: 'PRACTICE', color: Colors.white),
              const Spacer(),
              PillBadge(label: 'UNRANKED', color: white.withValues(alpha: 0.9)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Every match is a real battle',
            style: theme.textTheme.titleLarge?.copyWith(color: white),
          ),
          const SizedBox(height: 6),
          Text(
            'Rating, seasons and the ranked ladder need accounts. Until then, '
            'practice against the AI or challenge a friend by code.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: 6,
            children: [
              _Feature(label: 'Real Showdown engine', color: white),
              _Feature(label: 'No fake ratings', color: white),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.gold),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
