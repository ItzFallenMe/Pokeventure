import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeventure/data/item_catalog.dart';
import 'package:pokeventure/data/local/key_value_store.dart';
import 'package:pokeventure/data/mock_pokemon.dart';
import 'package:pokeventure/state/party_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test();
  });

  test('party starts at six with a larger box', () {
    final state = container.read(partyProvider);
    expect(state.party, hasLength(kPartyLimit));
    expect(state.box, isNotEmpty);
    expect(state.hasSpace, isFalse);
  });

  test('swapWithBox keeps the party at six and moves the outgoing mon', () {
    final before = container.read(partyProvider);
    final outgoing = before.party.first;
    final incoming = before.box.first;

    container.read(partyProvider.notifier).swapWithBox(0, incoming.id);
    final after = container.read(partyProvider);

    expect(after.party, hasLength(6));
    expect(after.party.first.id, incoming.id);
    expect(after.party.any((p) => p.id == outgoing.id), isFalse);
    expect(after.box.any((p) => p.id == outgoing.id), isTrue);
    expect(after.box, hasLength(before.box.length));
  });

  test('swapWithBox ignores unknown ids and bad indices', () {
    final before = container.read(partyProvider);
    final notifier = container.read(partyProvider.notifier);

    notifier.swapWithBox(0, 'does_not_exist');
    notifier.swapWithBox(99, before.box.first.id);

    final after = container.read(partyProvider);
    expect(
      after.party.map((p) => p.id).toList(),
      before.party.map((p) => p.id).toList(),
    );
  });

  test('reorder applies already-adjusted indices', () {
    final before = container.read(partyProvider);
    final second = before.party[1].id;

    container.read(partyProvider.notifier).reorder(1, 0);
    final after = container.read(partyProvider);

    expect(after.party.first.id, second);
    expect(after.party, hasLength(6));
  });

  test('healAll restores every party member', () {
    final notifier = container.read(partyProvider.notifier);
    final hurt = container.read(partyProvider).party.where(
          (p) => p.currentHp < p.maxHp,
        );
    expect(hurt, isNotEmpty, reason: 'mock data should have damage to heal');

    notifier.healAll();
    final after = container.read(partyProvider);

    expect(after.party.every((p) => p.currentHp == p.maxHp), isTrue);
  });

  test('addCaught sends the overflow to the PC and counts the catch', () {
    final before = container.read(partyProvider);
    final caught = mockBox.first;

    final joinedParty =
        container.read(partyProvider.notifier).addCaught(caught);
    final after = container.read(partyProvider);

    expect(joinedParty, isFalse, reason: 'party is full');
    expect(after.party, hasLength(6));
    expect(after.box.last.id, caught.id);
    expect(after.caught, before.caught + 1);
  });

  test('buyItem spends coins and stocks the bag', () {
    final item = itemBySlug('poke_ball')!;
    final before = container.read(partyProvider);

    final bought = container.read(partyProvider.notifier).buyItem(item);
    final after = container.read(partyProvider);

    expect(bought, isTrue);
    expect(after.coins, before.coins - item.price);
    expect(
      after.quantityOf(item.slug),
      before.quantityOf(item.slug) + 1,
    );
  });

  test('buyItem refuses when coins are short', () {
    final notifier = container.read(partyProvider.notifier);
    final item = itemBySlug('rare_candy')!;

    notifier.spendCoins(container.read(partyProvider).coins);
    final coins = container.read(partyProvider).coins;

    expect(notifier.buyItem(item), isFalse);
    expect(container.read(partyProvider).coins, coins);
  });

  test('state survives a reload through the store', () async {
    final store = MemoryStore();
    final first = ProviderContainer.test(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    first.read(partyProvider.notifier).addCaught(mockBox.first);
    final expected = first.read(partyProvider).caught;
    await Future<void>.delayed(Duration.zero);

    final second = ProviderContainer.test(
      overrides: [storeProvider.overrideWithValue(store)],
    );

    expect(second.read(partyProvider).caught, expected);
    expect(second.read(partyProvider).party, hasLength(6));
  });
}
