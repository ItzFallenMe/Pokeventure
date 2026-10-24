import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeventure/app/pokeventure_app.dart';
import 'package:pokeventure/ui/widgets/pokemon_sprite.dart';

void main() {
  setUp(() {
    SpriteConfig.enabled = false;
  });

  // The home screen has looping glow animations by design, so these tests pump
  // fixed durations instead of waiting for a settle.
  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PokeventureApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }

  testWidgets('shows the home hub with the featured spawn', (tester) async {
    await boot(tester);

    expect(find.text('Trainer'), findsOneWidget);
    expect(find.text('Eevee'), findsOneWidget);
    expect(find.text('Catch'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Party'), findsOneWidget);
  });

  testWidgets('party tab lists six members and the PC', (tester) async {
    await boot(tester);

    await tester.tap(find.text('Party'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Your party'), findsOneWidget);
    expect(find.text('6 / 6'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.textContaining('Battles use this party'), findsOneWidget);
  });

  testWidgets('catch sheet opens from the featured spawn', (tester) async {
    await boot(tester);

    await tester.tap(find.text('Catch'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Eevee appeared!'), findsOneWidget);
    expect(find.text('Throw'), findsOneWidget);

    // The ring animation loops, so close the sheet and let it tear down.
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('swapping from the PC keeps six and sends one out', (
    tester,
  ) async {
    await boot(tester);

    await tester.tap(find.text('Party'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Swap with PC').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Swap with the PC'), findsOneWidget);

    await tester.tap(find.text('Ralts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Ralts joined the party'), findsOneWidget);
    expect(find.text('6 / 6'), findsOneWidget);
  });

  testWidgets('every tab fits a phone viewport and scrolls cleanly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await boot(tester);

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

  testWidgets('dex loads and filters by name', (tester) async {
    await boot(tester);

    await tester.ensureVisible(find.text('Dex'));
    await tester.tap(find.text('Dex'));
    await tester.pump();
    // Asset loading is real async I/O, so give the event loop a turn.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Pokédex'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'charizard');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Charizard'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('shop purchase updates the bag', (tester) async {
    await boot(tester);

    await tester.tap(find.text('More'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ListTile, 'Shop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Poké Ball'), findsOneWidget);

    await tester.tap(find.text('Buy').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('added to your bag'), findsOneWidget);
  });

  testWidgets('more tab renders the milestone tiles', (tester) async {
    await boot(tester);

    await tester.tap(find.text('More'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Pokédex'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
  });
}
