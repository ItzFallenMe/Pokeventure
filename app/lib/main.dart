import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/pokeventure_app.dart';
import 'data/local/key_value_store.dart';
import 'data/social/social_bootstrap.dart';
import 'data/social/social_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final social = await createSocialRepository();

  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(SharedPrefsStore(prefs)),
        socialRepositoryProvider.overrideWithValue(social),
      ],
      child: const PokeventureApp(),
    ),
  );
}
