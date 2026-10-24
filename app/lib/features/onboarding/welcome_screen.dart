import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dex_repository.dart';
import '../../data/models/dex_entry.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/motion/motion.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/pokemon_sprite.dart';
import '../../ui/widgets/type_chip.dart';

const _starterNumbers = [1, 4, 7];

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final TextEditingController _name = TextEditingController();
  int _selected = 0;
  bool _starting = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _begin(DexEntry starter) {
    if (_starting) return;
    setState(() => _starting = true);
    ref
        .read(trainerProvider.notifier)
        .startJourney(name: _name.text, starter: starter);
    try {
      final sound = ref.read(soundServiceProvider);
      sound.success();
      sound.cry(starter.slug);
    } on Object {
      // Audio must never block the first launch.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catalog = ref.watch(dexCatalogProvider);
    final starters = [
      for (final number in _starterNumbers)
        if (catalog.speciesAt(number) != null) catalog.speciesAt(number)!,
    ];

    if (starters.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'The Pokédex data could not be loaded.\n'
              'Run the app from the project root so the assets are bundled.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final selected = starters[_selected.clamp(0, starters.length - 1)];
    final tint = TypePalette.of(selected.types.first);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AuroraBackdrop(
              colors: [
                tint,
                TypePalette.of(selected.types.last),
                AppTheme.teal,
              ],
              opacity: 0.7,
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 620;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Reveal(
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppTheme.heroGradient(
                                      theme.brightness,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.catching_pokemon_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  'POKÉVENTURE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 2.6,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Reveal(
                            delay: 60,
                            child: Text(
                              'Your first partner\nis waiting.',
                              style: theme.textTheme.displayLarge,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _Reveal(
                            delay: 120,
                            child: Text(
                              'Catch, train and battle with real Showdown '
                              'mechanics. Pick a starter, then explore six '
                              'zones built from all 1,025 species.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Reveal(
                            delay: 180,
                            child: TextField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              maxLength: 16,
                              decoration: const InputDecoration(
                                labelText: 'Trainer name',
                                hintText: 'Ash, Dawn, your call…',
                                counterText: '',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Reveal(
                            delay: 240,
                            child: Row(
                              children: [
                                Text(
                                  'CHOOSE YOUR STARTER',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 1.6,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                const PillBadge(
                                  label: 'Gen 1',
                                  icon: Icons.auto_awesome_rounded,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          wide
                              ? Row(
                                  children: [
                                    for (var i = 0; i < starters.length; i++)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: i == starters.length - 1
                                                ? 0
                                                : AppSpacing.sm,
                                          ),
                                          child: _StarterCard(
                                            entry: starters[i],
                                            selected: i == _selected,
                                            onTap: () {
                                              setState(() => _selected = i);
                                              ref
                                                  .read(soundServiceProvider)
                                                  .tap();
                                              ref
                                                  .read(soundServiceProvider)
                                                  .cry(starters[i].slug);
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : SizedBox(
                                  height: 236,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: starters.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: AppSpacing.sm),
                                    itemBuilder: (context, index) {
                                      return SizedBox(
                                        width: 168,
                                        child: _StarterCard(
                                          entry: starters[index],
                                          selected: index == _selected,
                                          onTap: () {
                                            setState(() => _selected = index);
                                            ref
                                                .read(soundServiceProvider)
                                                .tap();
                                            ref
                                                .read(soundServiceProvider)
                                                .cry(starters[index].slug);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                          const SizedBox(height: AppSpacing.lg),
                          _Reveal(
                            delay: 300,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow.withValues(
                                  alpha: 0.78,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${selected.name} · ${selected.genus}\n'
                                      '${selected.types.map((t) => t.label).join(' / ')} · '
                                      'Base total ${selected.statTotal}',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            height: 1.5,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: tint,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _starting
                                  ? null
                                  : () => _begin(selected),
                              icon: const Icon(Icons.rocket_launch_rounded),
                              label: Text('Start with ${selected.name}'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Saves on this device · no account needed',
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final DexEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = TypePalette.of(entry.types.first);

    return PressScale(
      scale: 0.97,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.emphasizedDecelerate,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint.withValues(alpha: selected ? 0.28 : 0.12),
                scheme.surfaceContainerLow.withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? tint
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.32),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 18, color: tint),
                  const Spacer(),
                  Text(
                    entry.dexLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: GlowPulse(
                  color: tint,
                  min: selected ? 0.45 : 0.1,
                  max: selected ? 0.8 : 0.2,
                  child: PokemonSprite(
                    dexNumber: entry.number,
                    fallbackTypes: entry.types,
                    size: 86,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(entry.name, style: theme.textTheme.titleLarge),
              Text(
                entry.genus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final type in entry.types)
                    TypeChip(type: type, dense: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.emphasizedDecelerate,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
