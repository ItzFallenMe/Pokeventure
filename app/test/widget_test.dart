import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeventure/data/dex_repository.dart';
import 'package:pokeventure/data/local/key_value_store.dart';
import 'package:pokeventure/ui/widgets/pokemon_sprite.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DexCatalog catalog;

  setUpAll(() async {
    catalog = await loadTestCatalog();
  });

  setUp(() {
    SpriteConfig.enabled = false;
  });

  testWidgets('onboarding picks a real starter and enters the hub', (
    tester,
  ) async {
    await bootApp(tester, catalog, MemoryStore({...testSettings}));

    expect(find.textContaining('Your first partner'), findsOneWidget);
    expect(find.text('Start with Bulbasaur'), findsOneWidget);
    expect(find.text('Charmander'), findsOneWidget);
    expect(find.text('Squirtle'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Misty');
    final startButton = find.widgetWithText(
      FilledButton,
      'Start with Bulbasaur',
    );
    await tester.ensureVisible(startButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(startButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Misty'), findsOneWidget);
    expect(find.text('DAILY POKÉMON'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Your party'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Your party'), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
  });

  testWidgets('home exposes the daily spawn and the catch sheet', (
    tester,
  ) async {
    await bootApp(tester, catalog, startedStore(catalog));

    expect(find.text('DAILY POKÉMON'), findsOneWidget);

    await tester.tap(find.text('Catch now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('WILD ENCOUNTER'), findsOneWidget);
    expect(find.text('Catch chance'), findsOneWidget);
    expect(find.text('Throw · tap the ring'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('explore spawns a wild Pokémon from the real zone table', (
    tester,
  ) async {
    await bootApp(tester, catalog, startedStore(catalog));

    await tester.tap(find.text('Explore the zones'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Where to next?'), findsOneWidget);
    expect(find.text('Verdant Route'), findsWidgets);
    expect(find.text('Catch'), findsOneWidget);
    expect(find.textContaining('Lv.'), findsWidgets);
  });

  testWidgets('party tab starts with the starter and an empty PC', (
    tester,
  ) async {
    await bootApp(tester, catalog, startedStore(catalog));

    await tester.tap(find.text('Party'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Your party'), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('PC Boxes'), findsOneWidget);

    await tester.tap(find.text('PC Boxes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('The PC is empty'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('shop buys with real coins', (tester) async {
    await bootApp(tester, catalog, startedStore(catalog, extraCoins: 1000));

    await tester.tap(find.text('More'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.widgetWithText(ListTile, 'Shop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Poké Ball'), findsOneWidget);
    await tester.tap(find.text('Buy').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('added to your bag'), findsOneWidget);
  });

  testWidgets('dex loads the real dataset and filters by name', (tester) async {
    await bootApp(tester, catalog, startedStore(catalog));

    await tester.tap(find.text('More'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.widgetWithText(ListTile, 'Pokédex'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Pokédex'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.textContaining('complete'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'charizard');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Charizard'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('customisation changes accent, avatar and title', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await bootApp(tester, catalog, startedStore(catalog));

    await tester.tap(find.text('More'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Customisation'), findsOneWidget);
    expect(find.text('Accent colour'), findsOneWidget);

    await tester.tap(find.byTooltip('Teal'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Blaze'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Champion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Champion'));
    await tester.pump(const Duration(milliseconds: 300));

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Champion'),
    );
    expect(chip.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every tab fits a phone viewport and scrolls cleanly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await bootApp(tester, catalog, startedStore(catalog));

    for (final tab in ['Party', 'Battle', 'Social', 'More', 'Home']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull, reason: '$tab layout overflowed');

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: '$tab scroll overflowed');
    }
  });
}
