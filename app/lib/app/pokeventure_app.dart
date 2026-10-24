import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/welcome_screen.dart';
import '../state/theme_provider.dart';
import '../state/trainer_provider.dart';
import '../ui/theme/app_theme.dart';
import 'app_shell.dart';

class PokeventureApp extends ConsumerStatefulWidget {
  const PokeventureApp({super.key});

  @override
  ConsumerState<PokeventureApp> createState() => _PokeventureAppState();
}

class _PokeventureAppState extends ConsumerState<PokeventureApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Roll daily quests, streak and counters if the date changed while the
      // app was closed, then start the looping theme.
      ref.read(trainerProvider.notifier).refreshDaily();
      ref.read(soundServiceProvider).startMusic();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sound = ref.read(soundServiceProvider);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        sound.pauseMusic();
      case AppLifecycleState.resumed:
        sound.resumeMusic();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    Widget app(ThemeData light, ThemeData dark) {
      return MaterialApp(
        title: 'Pokéventure',
        debugShowCheckedModeBanner: false,
        theme: light,
        darkTheme: dark,
        themeMode: settings.themeMode,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              disableAnimations:
                  !settings.animations || media.disableAnimations,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const _RootGate(),
      );
    }

    if (!settings.dynamicColor) {
      final accent = AppTheme.accentColor(settings.accent);
      return app(
        AppTheme.withAccent(accent, Brightness.light),
        AppTheme.withAccent(accent, Brightness.dark),
      );
    }

    return DynamicColorBuilder(
      builder: (lightScheme, darkScheme) {
        // `dynamic_color` ships its own ColorScheme type that can drift from
        // the Flutter SDK, so only the wallpaper colours cross the boundary.
        return app(
          lightScheme == null
              ? AppTheme.light
              : AppTheme.fromScheme(
                  ColorScheme.fromSeed(
                    seedColor: lightScheme.primary,
                    brightness: Brightness.light,
                    secondary: lightScheme.secondary,
                    tertiary: lightScheme.tertiary,
                  ),
                ),
          darkScheme == null
              ? AppTheme.dark
              : AppTheme.fromScheme(
                  ColorScheme.fromSeed(
                    seedColor: darkScheme.primary,
                    brightness: Brightness.dark,
                    secondary: darkScheme.secondary,
                    tertiary: darkScheme.tertiary,
                  ),
                ),
        );
      },
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final started = ref.watch(trainerProvider.select((state) => state.started));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: started
          ? const AppShell(key: ValueKey('shell'))
          : const WelcomeScreen(key: ValueKey('welcome')),
    );
  }
}
