import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/pokeventure_app.dart';
import 'data/dex_repository.dart';
import 'data/local/key_value_store.dart';
import 'data/social/social_bootstrap.dart';
import 'data/social/social_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final social = await createSocialRepository();
  final catalog = await _loadCatalog();

  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(SharedPrefsStore(prefs)),
        socialRepositoryProvider.overrideWithValue(social),
        dexCatalogProvider.overrideWithValue(catalog),
      ],
      child: const PokeventureApp(),
    ),
  );
}

Future<DexCatalog> _loadCatalog() async {
  try {
    return await loadDexCatalog();
  } on Object catch (error) {
    debugPrint('Could not load dex assets: $error');
    return DexCatalog.empty();
  }
}
