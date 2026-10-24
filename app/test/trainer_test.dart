import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeventure/data/dex_repository.dart';
import 'package:pokeventure/data/game/stats.dart';
import 'package:pokeventure/data/game/wild.dart';
import 'package:pokeventure/data/game/quests.dart';
import 'package:pokeventure/data/item_catalog.dart';
import 'package:pokeventure/data/local/key_value_store.dart';
import 'package:pokeventure/state/trainer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DexCatalog catalog;
  late MemoryStore store;
  late ProviderContainer container;

  setUpAll(() async {
    catalog = await loadDexCatalog();
  });

  setUp(() {
    store = MemoryStore();
    container = ProviderContainer(
      overrides: [
        storeProvider.overrideWithValue(store),
        dexCatalogProvider.overrideWithValue(catalog),
      ],
    );
  });

  tearDown(() => container.dispose());

  TrainerNotifier notifier() => container.read(trainerProvider.notifier);
  TrainerState state() => container.read(trainerProvider);

  void start({int starter = 1}) {
    notifier().startJourney(name: 'Ash', starter: catalog.speciesAt(starter)!);
  }

  test('a new game is not started until a starter is chosen', () {
    expect(state().started, isFalse);
    expect(state().party, isEmpty);
  });

  test('starting the journey creates a real level-5 starter', () {
    start();

    final trainer = state();
    expect(trainer.started, isTrue);
    expect(trainer.name, 'Ash');
    expect(trainer.party, hasLength(1));
    expect(trainer.coins, 600);
    expect(trainer.streak, 1);
    expect(trainer.quests, hasLength(3));
    expect(trainer.caught, contains(1));
    expect(trainer.quantityOf('poke_ball'), 20);

    final starter = trainer.party.single;
    expect(starter.level, 5);
    expect(starter.name, 'Bulbasaur');
    expect(starter.moves, isNotEmpty);
    expect(starter.maxHp, starter.stats.hp);
    expect(starter.currentHp, starter.maxHp);
    expect(starter.ivs.total, greaterThan(0));
    expect(starter.ability, 'Overgrow');
    expect(starter.nature, isNotEmpty);
    expect(starter.toJson()['name'], 'Bulbasaur');
  });

  test('catching registers the species and rewards coins and XP', () {
    start();
    final before = state();
    final species = catalog.speciesAt(19)!;
    final wild = createPokemon(
      species: species,
      level: 4,
      random: Random(2),
      zone: 'Verdant Route',
    );

    final report = notifier().recordCatch(
      pokemon: wild,
      ball: 'Poké Ball',
      zone: 'Verdant Route',
      rarity: 'common',
    );

    expect(report.newSpecies, isTrue);
    expect(report.joinedParty, isTrue);
    expect(report.coins, greaterThan(0));
    expect(state().party, hasLength(2));
    expect(state().caught, contains(19));
    expect(state().seen, contains(19));
    expect(state().coins, before.coins + report.coins);
    expect(state().counters.catches, 1);

    final catchQuest = state().quests
        .where((quest) => quest.kind == QuestKind.catchAny)
        .first;
    expect(catchQuest.progress, 1);
  });

  test('a full party sends the catch to the PC', () {
    start();
    for (var i = 0; i < 5; i++) {
      final wild = createPokemon(
        species: catalog.speciesAt(10 + i)!,
        level: 3,
        random: Random(i),
      );
      notifier().recordCatch(
        pokemon: wild,
        ball: 'Poké Ball',
        zone: 'Verdant Route',
        rarity: 'common',
      );
    }
    expect(state().party, hasLength(kPartyLimit));

    final overflow = createPokemon(
      species: catalog.speciesAt(25)!,
      level: 3,
      random: Random(9),
    );
    final report = notifier().recordCatch(
      pokemon: overflow,
      ball: 'Poké Ball',
      zone: 'Verdant Route',
      rarity: 'common',
    );

    expect(report.joinedParty, isFalse);
    expect(state().party, hasLength(kPartyLimit));
    expect(state().box, hasLength(1));
    expect(state().box.single.name, 'Pikachu');
  });

  test('XP levels up the Pokémon and evolves it at the right level', () {
    start(starter: 4); // Charmander
    final charmander = state().party.single;
    expect(charmander.name, 'Charmander');

    final report = notifier().grantXp(
      charmander.id,
      totalXpForLevel(16) - totalXpForLevel(5) + 5,
    );

    expect(report, isNotNull);
    expect(report!.levelsGained, greaterThan(0));
    expect(report.evolvedInto?.name, 'Charmeleon');
    final evolved = state().party.single;
    expect(evolved.name, 'Charmeleon');
    expect(evolved.dexNumber, 5);
    expect(evolved.stats.total, greaterThan(charmander.stats.total));
    expect(state().caught, contains(5));
    expect(evolved.moves.length, lessThanOrEqualTo(4));
  });

  test('items are bought, consumed and used', () {
    start();
    final item = itemBySlug('poke_ball')!;
    final before = state();

    expect(notifier().buyItem(item), isTrue);
    expect(state().quantityOf('poke_ball'), before.quantityOf('poke_ball') + 1);
    expect(state().coins, before.coins - item.price);

    expect(notifier().consumeBall('poke_ball'), isTrue);
    expect(state().quantityOf('poke_ball'), before.quantityOf('poke_ball'));
    expect(notifier().consumeBall('master_ball'), isFalse);

    notifier().addItem('rare_candy', 1);
    final levelBefore = state().party.single.level;
    final message = notifier().useItem('rare_candy', state().party.single.id);
    expect(message, isNotNull);
    expect(state().party.single.level, levelBefore + 1);
    expect(state().quantityOf('rare_candy'), 0);
  });

  test('daily quests can be claimed once', () {
    start();
    for (var i = 0; i < 3; i++) {
      notifier().recordCatch(
        pokemon: createPokemon(
          species: catalog.speciesAt(16 + i)!,
          level: 3,
          random: Random(i + 4),
        ),
        ball: 'Poké Ball',
        zone: 'Verdant Route',
        rarity: 'common',
      );
    }
    final quest = state().quests.firstWhere(
      (quest) => quest.kind == QuestKind.catchAny,
    );
    expect(quest.isClaimable, isTrue);

    final coins = state().coins;
    expect(notifier().claimQuest(quest.id), isTrue);
    expect(state().coins, coins + quest.rewardCoins);
    expect(notifier().claimQuest(quest.id), isFalse);
  });

  test('releasing a Pokémon pays coins and removes it', () {
    start();
    notifier().recordCatch(
      pokemon: createPokemon(
        species: catalog.speciesAt(19)!,
        level: 4,
        random: Random(1),
      ),
      ball: 'Poké Ball',
      zone: 'Verdant Route',
      rarity: 'common',
    );
    final caught = state().party.last;
    final coins = state().coins;

    final reward = notifier().release(caught.id);

    expect(reward, greaterThan(0));
    expect(state().coins, coins + reward);
    expect(state().party.any((p) => p.id == caught.id), isFalse);
  });

  test('party reorder, swap and heal work on real members', () {
    start();
    for (var i = 0; i < 6; i++) {
      notifier().recordCatch(
        pokemon: createPokemon(
          species: catalog.speciesAt(20 + i)!,
          level: 3,
          random: Random(i),
        ),
        ball: 'Poké Ball',
        zone: 'Verdant Route',
        rarity: 'common',
      );
    }
    final party = state().party;
    expect(party, hasLength(6));

    final second = party[1].id;
    notifier().reorder(1, 0);
    expect(state().party.first.id, second);

    final boxPokemon = state().box.first;
    notifier().swapWithBox(0, boxPokemon.id);
    expect(state().party, hasLength(6));
    expect(state().party.any((p) => p.id == boxPokemon.id), isTrue);

    expect(notifier().healParty(), isFalse); // already full
  });

  test('the trainer survives a reload through the store', () {
    start();
    notifier().recordCatch(
      pokemon: createPokemon(
        species: catalog.speciesAt(133)!,
        level: 6,
        random: Random(8),
      ),
      ball: 'Great Ball',
      zone: 'Verdant Route',
      rarity: 'uncommon',
    );
    final caught = state().caughtCount;
    final party = state().party.length;

    final reloaded = ProviderContainer(
      overrides: [
        storeProvider.overrideWithValue(store),
        dexCatalogProvider.overrideWithValue(catalog),
      ],
    );
    addTearDown(reloaded.dispose);

    expect(reloaded.read(trainerProvider).caughtCount, caught);
    expect(reloaded.read(trainerProvider).party, hasLength(party));
    expect(reloaded.read(trainerProvider).name, 'Ash');
  });
}
