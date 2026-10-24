import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/credits.dart';
import '../../state/theme_provider.dart';
import '../../state/trainer_provider.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/tokens/avatars.dart';
import '../../ui/tokens/layout.dart';
import '../../ui/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mode = ref.watch(themeModeProvider);
    final settings = ref.watch(settingsProvider);
    final trainer = ref.watch(trainerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          const SectionHeader(title: 'Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: theme.textTheme.titleSmall),
                  Text(
                    'Material 3, tuned with the Pokéventure palette.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded, size: 18),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded, size: 18),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded, size: 18),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {mode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        ref
                            .read(settingsProvider.notifier)
                            .select(selection.first);
                        ref.read(soundServiceProvider).tap();
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStateProperty.all(
                          const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: SwitchListTile(
              value: settings.dynamicColor,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDynamicColor(value);
                ref.read(soundServiceProvider).tap();
              },
              secondary: const Icon(Icons.palette_rounded),
              title: const Text(
                'Dynamic colour',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: const Text(
                'Follow the wallpaper palette on Android 12+. Type colours '
                'never change.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Customisation'),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Accent colour', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Recolours the whole game. Type colours stay fixed.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final entry in AppTheme.accents.entries)
                            Tooltip(
                              message: entry.value.label,
                              child: InkWell(
                                onTap: () {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .setAccent(entry.key);
                                  ref.read(soundServiceProvider).tap();
                                },
                                borderRadius: BorderRadius.circular(99),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: entry.value.color,
                                    border: Border.all(
                                      color: settings.accent == entry.key
                                          ? scheme.onSurface
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: settings.accent == entry.key
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trainer avatar', style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final entry in trainerAvatars.entries)
                            Tooltip(
                              message: entry.value.label,
                              child: InkWell(
                                onTap: () {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .setAvatar(entry.key);
                                  ref.read(soundServiceProvider).tap();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: settings.avatar == entry.key
                                        ? scheme.primaryContainer
                                        : scheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: settings.avatar == entry.key
                                          ? scheme.primary
                                          : scheme.outlineVariant,
                                    ),
                                  ),
                                  child: Icon(
                                    entry.value.icon,
                                    size: 22,
                                    color: settings.avatar == entry.key
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trainer title', style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final title in trainerTitles)
                            ChoiceChip(
                              label: Text(title),
                              selected: settings.title == title,
                              showCheckmark: false,
                              onSelected: (_) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .setTitle(title);
                                ref.read(soundServiceProvider).tap();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.animations,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setAnimations(value);
                    ref.read(soundServiceProvider).tap();
                  },
                  secondary: const Icon(Icons.animation_rounded),
                  title: const Text(
                    'Animations',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Turn off for a calmer, battery-friendly UI. Also follows '
                    'the system reduce-motion setting.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Sound & feel'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.soundEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setSound(value);
                    if (value) ref.read(soundServiceProvider).tap();
                  },
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: const Text(
                    'Sound effects',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Throws, catches, level-ups and Pokémon cries.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.musicEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setMusic(value);
                    if (value) ref.read(soundServiceProvider).tap();
                  },
                  secondary: const Icon(Icons.music_note_rounded),
                  title: const Text(
                    'Music',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Looping adventure theme, pauses in the background.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.hapticsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setHaptics(value);
                    if (value) ref.read(soundServiceProvider).impact();
                  },
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text(
                    'Haptics',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Light feedback on catches, throws and purchases.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Trainer'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      trainer.name.isEmpty
                          ? '?'
                          : trainer.name.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    trainer.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Level ${trainer.level} · ${trainer.caughtCount} caught · '
                    '${trainer.shinyCount} shiny',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: () => _rename(context, ref, trainer.name),
                    child: const Text('Rename'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: const Text(
                    'New game',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Clears this device save and returns to starter selection.',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () => _confirmReset(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Created by'),
          Card(
            child: InkWell(
              onTap: () async {
                ref.read(soundServiceProvider).tap();
                final opened = await Credits.openCreator();
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open the link.')),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: AppTheme.heroGradient(theme.brightness),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'IF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ItzFallenMe',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Creator & maintainer · github.com/ItzFallenMe',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Version'),
                  trailing: Text('1.1.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('Data & assets'),
                  subtitle: const Text(
                    'Stats and learnsets from Pokémon Showdown. Catch rates and '
                    'flavour text from the ItzFallenMe pokemon-data.json set, '
                    'PokeAPI and the community datasets. Sprites from PokeAPI, '
                    'cries from Showdown.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => Credits.openPokemonData(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Licenses'),
                  subtitle: const Text(
                    'Flutter, Riverpod, Showdown data, Outfit font and the '
                    'PokéAPI sprite set.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Pokéventure',
                    applicationVersion: '1.1.0',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Pokéventure is a fan project. Pokémon and Pokémon character '
            'names are trademarks of Nintendo, Creators, Game Freak and The '
            'Pokémon Company.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Trainer name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 16,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your name'),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null) return;
    ref.read(trainerProvider.notifier).rename(name);
    ref.read(soundServiceProvider).tap();
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Start a new game?'),
          content: const Text(
            'This clears the local save — party, PC, coins, Pokédex and quests. '
            'It cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Start over'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    ref.read(trainerProvider.notifier).resetProgress();
    ref.read(soundServiceProvider).tap();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
