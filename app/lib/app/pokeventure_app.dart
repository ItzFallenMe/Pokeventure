import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/theme_provider.dart';
import '../ui/theme/app_theme.dart';
import 'app_shell.dart';

class PokeventureApp extends ConsumerWidget {
  const PokeventureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Pokéventure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      home: const AppShell(),
    );
  }
}
