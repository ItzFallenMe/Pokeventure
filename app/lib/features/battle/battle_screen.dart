import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/battle_api.dart';
import '../../state/party_provider.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/common.dart';
import 'battle_arena_screen.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

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
      final snapshot = await ref
          .read(battleApiProvider)
          .createBattle(format: _formats[_format].$2);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BattleArenaScreen(initial: snapshot),
        ),
      );
    } on BattleApiException catch (error) {
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
    final party = ref.watch(partyProvider).party;

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
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 5,
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
            index: 6,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
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
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replays',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Your first battle replay will appear here.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              const PillBadge(label: 'SEASON 1', color: Colors.white),
              const Spacer(),
              const PillBadge(label: '12 DAYS LEFT', color: Colors.white),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Great Ball tier',
            style: theme.textTheme.labelLarge?.copyWith(
              color: white.withValues(alpha: 0.8),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '1,482',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: white,
                  fontSize: 42,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.58,
              minHeight: 7,
              backgroundColor: white.withValues(alpha: 0.18),
              color: white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '1,320',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: white.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              Text(
                'Ultra Ball at 1,600',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
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
