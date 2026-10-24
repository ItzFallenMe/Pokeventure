import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeventure/app/pokeventure_app.dart';
import 'package:pokeventure/data/dex_repository.dart';
import 'package:pokeventure/data/local/key_value_store.dart';
import 'package:pokeventure/state/trainer_provider.dart';

const testSettings = <String, String>{
  'theme_mode': 'dark',
  'sound_enabled': 'false',
  'music_enabled': 'false',
  'haptics_enabled': 'false',
  'dynamic_color': 'false',
};

/// The real bundled dataset, loaded once per test file.
Future<DexCatalog> loadTestCatalog() => loadDexCatalog();

/// A store containing a real trainer that already picked [starter].
MemoryStore startedStore(
  DexCatalog catalog, {
  String name = 'Ash',
  int starter = 1,
  int extraCoins = 0,
}) {
  final store = MemoryStore({...testSettings});
  final container = ProviderContainer(
    overrides: [
      storeProvider.overrideWithValue(store),
      dexCatalogProvider.overrideWithValue(catalog),
    ],
  );
  final notifier = container.read(trainerProvider.notifier);
  notifier.startJourney(name: name, starter: catalog.speciesAt(starter)!);
  if (extraCoins > 0) {
    final state = container.read(trainerProvider);
    final json =
        jsonDecode(store.read('trainer_state_v3')!) as Map<String, dynamic>;
    json['coins'] = state.coins + extraCoins;
    store.write('trainer_state_v3', jsonEncode(json));
  }
  container.dispose();
  return store;
}

/// Pumps the app with the real catalog and a fixed store, then lets the
/// entrance animations play for a moment.
Future<void> bootApp(
  WidgetTester tester,
  DexCatalog catalog,
  MemoryStore store,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dexCatalogProvider.overrideWithValue(catalog),
        storeProvider.overrideWithValue(store),
      ],
      child: const PokeventureApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
}
