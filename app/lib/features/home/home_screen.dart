import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dex_repository.dart';
import '../../data/game/quests.dart';
import '../../data/game/wild.dart';
import '../../data/models/pokemon.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/motion/motion.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/avatars.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/tokens/type_palette.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/hp_bar.dart';
import '../../ui/widgets/pokemon_orb.dart';
import '../../ui/widgets/pokemon_sprite.dart';
import '../../ui/widgets/type_chip.dart';
import '../dex/pokedex_screen.dart';
import '../explore/catch_sheet.dart';
import '../explore/explore_screen.dart';
import '../party/pokemon_detail_sheet.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onOpenParty});

  final VoidCallback onOpenParty;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _dailyCaught = false;

  Future<void> _catch(WildSpawn spawn) async {
    final report = await showCatchSheet(context, spawn);
    if (!mounted) return;
    if (report != null) setState(() => _dailyCaught = true);
  }

  void _openExplore() {
    ref.read(soundServiceProvider).tap();
    Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const ExploreScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trainer = ref.watch(trainerProvider);
    final catalog = ref.watch(dexCatalogProvider);
    final daily = dailyFeatured(
      species: catalog.species,
      byNumber: catalog.byNumber,
    );
    final buddy = trainer.party.isEmpty ? null : trainer.party.first;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(trainerProvider.notifier).refreshDaily();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            _Header(trainer: trainer, onAvatar: () => widget.onOpenParty()),
            const SizedBox(height: AppSpacing.md),
            _Wallet(trainer: trainer),
            if (!trainer.dailyGiftClaimed) ...[
              const SizedBox(height: AppSpacing.md),
              _DailyGift(
                streak: trainer.streak,
                onClaim: () {
                  final claimed = ref
                      .read(trainerProvider.notifier)
                      .claimDailyGift();
                  if (claimed) {
                    ref.read(soundServiceProvider).purchase();
                    _toast(
                      'Daily gift claimed · +${100 + trainer.streak * 10} coins',
                    );
                  }
                  setState(() {});
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (daily != null)
              _FeaturedCard(
                spawn: daily,
                caughtToday: _dailyCaught,
                onCatch: () => _catch(daily),
                onInspect: () {
                  final entry = catalog.speciesAt(daily.pokemon.dexNumber);
                  if (entry != null) {
                    Navigator.of(
                      context,
                    ).push(AppPageRoute(builder: (_) => const PokedexScreen()));
                  }
                },
              ),
            const SizedBox(height: AppSpacing.lg),
            _ExploreCallout(onTap: _openExplore),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Your party',
              trailingLabel: '${trainer.party.length} / $kPartyLimit',
              onTrailing: widget.onOpenParty,
            ),
            if (buddy != null)
              SizedBox(
                height: 196,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: trainer.party.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final pokemon = trainer.party[index];
                    return _PartyCard(
                      pokemon: pokemon,
                      lead: index == 0,
                      onTap: () => showPokemonDetailSheet(context, pokemon),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Today’s quests',
              trailingLabel: trainer.claimableQuests > 0
                  ? '${trainer.claimableQuests} ready'
                  : null,
            ),
            if (trainer.quests.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_available_rounded),
                  title: const Text('Quests roll in at midnight'),
                  subtitle: const Text('Come back tomorrow for new research.'),
                ),
              )
            else
              for (final quest in trainer.quests.take(3))
                _QuestTile(
                  quest: quest,
                  onClaim: () {
                    final claimed = ref
                        .read(trainerProvider.notifier)
                        .claimQuest(quest.id);
                    if (claimed) {
                      ref.read(soundServiceProvider).purchase();
                      _toast('Quest complete · +${quest.rewardCoins} coins');
                      setState(() {});
                    }
                  },
                ),
            const SizedBox(height: AppSpacing.xl),
            _DexProgress(
              caught: trainer.caughtCount,
              shiny: trainer.shinyCount,
              wins: trainer.totalWins,
              battles: trainer.totalBattles,
              onOpen: () => Navigator.of(
                context,
              ).push(AppPageRoute(builder: (_) => const PokedexScreen())),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _Shortcut(
                    icon: Icons.storefront_rounded,
                    label: 'Shop',
                    tint: AppTheme.gold,
                    onTap: () => Navigator.of(
                      context,
                    ).push(AppPageRoute(builder: (_) => const ShopScreen())),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _Shortcut(
                    icon: Icons.menu_book_rounded,
                    label: 'Pokédex',
                    tint: scheme.primary,
                    onTap: () => Navigator.of(
                      context,
                    ).push(AppPageRoute(builder: (_) => const PokedexScreen())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.trainer, required this.onAvatar});

  final TrainerState trainer;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onAvatar,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.heroGradient(theme.brightness),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              trainerAvatarIcon(settings.avatar),
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      trainer.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PillBadge(label: 'Lv. ${trainer.level}'),
                ],
              ),
              Text(
                settings.title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        PillBadge(
          label: '${trainer.streak} day${trainer.streak == 1 ? '' : 's'}',
          icon: Icons.local_fire_department_rounded,
          color: AppTheme.gold,
        ),
      ],
    );
  }
}

class _Wallet extends StatelessWidget {
  const _Wallet({required this.trainer});

  final TrainerState trainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          _WalletStat(
            icon: Icons.monetization_on_rounded,
            tint: AppTheme.gold,
            value: trainer.coins,
          ),
          _WalletDivider(),
          _WalletStat(
            icon: Icons.diamond_rounded,
            tint: AppTheme.teal,
            value: trainer.gems,
          ),
          _WalletDivider(),
          _WalletStat(
            icon: Icons.catching_pokemon_rounded,
            tint: theme.colorScheme.primary,
            value: trainer.caughtCount,
            label: 'caught',
          ),
          const Spacer(),
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LV ${trainer.level}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: trainer.levelProgress),
                    duration: AppMotion.slow,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
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

class _WalletStat extends StatelessWidget {
  const _WalletStat({
    required this.icon,
    required this.tint,
    required this.value,
    this.label,
  });

  final IconData icon;
  final Color tint;
  final int value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: tint),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCounter(
              value: value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1.1,
              ),
            ),
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WalletDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

class _DailyGift extends StatelessWidget {
  const _DailyGift({required this.streak, required this.onClaim});

  final int streak;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withValues(alpha: 0.16),
            AppTheme.rose.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.redeem_rounded, color: AppTheme.gold, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day $streak reward', style: theme.textTheme.titleSmall),
                Text(
                  '+${100 + streak * 10} coins and 5 Poké Balls',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onClaim,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.spawn,
    required this.caughtToday,
    required this.onCatch,
    required this.onInspect,
  });

  final WildSpawn spawn;
  final bool caughtToday;
  final VoidCallback onCatch;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pokemon = spawn.pokemon;
    final tint = TypePalette.of(pokemon.types.first);

    return PressScale(
      child: GestureDetector(
        onTap: onInspect,
        child: Container(
          constraints: const BoxConstraints(minHeight: 214),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint.withValues(alpha: 0.92),
                Color.alphaBlend(Colors.black.withValues(alpha: 0.3), tint),
                const Color(0xFF19132E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: tint.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -30,
                child: Icon(
                  Icons.catching_pokemon_rounded,
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'DAILY POKÉMON',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            pokemon.name,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Lv. ${pokemon.level} · ${spawn.rarity}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 4,
                            children: [
                              for (final type in pokemon.types)
                                TypeChip(type: type),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: caughtToday ? null : onCatch,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: tint,
                              minimumSize: const Size(0, 42),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                            ),
                            icon: Icon(
                              caughtToday
                                  ? Icons.check_rounded
                                  : Icons.catching_pokemon_rounded,
                              size: 18,
                            ),
                            label: Text(caughtToday ? 'Caught' : 'Catch now'),
                          ),
                        ],
                      ),
                    ),
                    GlowPulse(
                      color: Colors.white,
                      min: 0.25,
                      max: 0.45,
                      child: PokemonSprite(
                        dexNumber: pokemon.dexNumber,
                        fallbackTypes: pokemon.types,
                        size: 140,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCallout extends StatelessWidget {
  const _ExploreCallout({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: scheme.surfaceContainerLow,
            border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.teal.withValues(alpha: 0.9),
                      const Color(0xFF0891B2),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore the zones',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      'Six habitats, live spawns, rare encounters',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.pokemon,
    required this.lead,
    required this.onTap,
  });

  final Pokemon pokemon;
  final bool lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = TypePalette.of(pokemon.types.first);

    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 152,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tint.withValues(alpha: 0.2), scheme.surfaceContainerLow],
            ),
            border: Border.all(
              color: tint.withValues(alpha: lead ? 0.55 : 0.22),
              width: lead ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (lead)
                    const PillBadge(label: 'LEAD', color: AppTheme.gold),
                  const Spacer(),
                  if (pokemon.shiny)
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppTheme.shiny,
                    ),
                ],
              ),
              Center(child: PokemonOrb(pokemon: pokemon, size: 62)),
              const Spacer(),
              Text(
                pokemon.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                'Lv. ${pokemon.level} · ${pokemon.nature}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              HpBar(value: pokemon.hpFraction, height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.quest, required this.onClaim});

  final DailyQuest quest;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = quest.isClaimable;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppTheme.teal.withValues(alpha: 0.16)
                      : scheme.surfaceContainerHigh,
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.radio_button_unchecked,
                  size: 19,
                  color: done ? AppTheme.teal : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.title, style: theme.textTheme.titleSmall),
                    Text(
                      quest.description,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: quest.fraction),
                              duration: AppMotion.slow,
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    minHeight: 4,
                                    backgroundColor:
                                        scheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(
                                      done ? AppTheme.teal : scheme.primary,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${quest.progress}/${quest.target}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${quest.rewardCoins}',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  if (quest.rewardItemSlug != null)
                    Text(
                      quest.rewardItemSlug!
                          .replaceAll('_', ' ')
                          .replaceAll('tm ', 'TM ')
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (done)
                    TextButton(
                      onPressed: onClaim,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text('Claim'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DexProgress extends StatelessWidget {
  const _DexProgress({
    required this.caught,
    required this.shiny,
    required this.wins,
    required this.battles,
    required this.onOpen,
  });

  final int caught;
  final int shiny;
  final int wins;
  final int battles;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = caught / 1025;

    return PressScale(
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: scheme.surfaceContainerLow,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text('Pokédex progress', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.teal),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '$caught / 1,025 species',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _MiniStat(icon: Icons.auto_awesome_rounded, value: '$shiny'),
                  const SizedBox(width: AppSpacing.md),
                  _MiniStat(
                    icon: Icons.emoji_events_rounded,
                    value: '$wins/${battles.clamp(0, 999)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.gold),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: tint.withValues(alpha: 0.1),
            border: Border.all(color: tint.withValues(alpha: 0.26)),
          ),
          child: Column(
            children: [
              Icon(icon, color: tint, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
