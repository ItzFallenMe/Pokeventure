import 'package:flutter/material.dart';

enum ItemCategory {
  balls('Balls'),
  medicine('Medicine'),
  berries('Berries'),
  tms('TMs'),
  key('Key items'),
  materials('Materials');

  const ItemCategory(this.label);

  final String label;
}

class ItemDef {
  const ItemDef({
    required this.slug,
    required this.name,
    required this.category,
    required this.description,
    this.price = 0,
    this.icon = Icons.catching_pokemon_rounded,
  });

  final String slug;
  final String name;
  final ItemCategory category;
  final String description;
  final int price;
  final IconData icon;

  bool get purchasable => price > 0;
}

const itemCatalog = <ItemDef>[
  ItemDef(
    slug: 'poke_ball',
    name: 'Poké Ball',
    category: ItemCategory.balls,
    description: 'The standard ball. 1× catch rate.',
    price: 200,
  ),
  ItemDef(
    slug: 'great_ball',
    name: 'Great Ball',
    category: ItemCategory.balls,
    description: 'Better performance. 1.5× catch rate.',
    price: 600,
    icon: Icons.sports_baseball_rounded,
  ),
  ItemDef(
    slug: 'ultra_ball',
    name: 'Ultra Ball',
    category: ItemCategory.balls,
    description: 'High-performance ball. 2× catch rate.',
    price: 1200,
    icon: Icons.sports_baseball_rounded,
  ),
  ItemDef(
    slug: 'net_ball',
    name: 'Net Ball',
    category: ItemCategory.balls,
    description: '3.5× against Water and Bug types.',
    price: 1000,
    icon: Icons.grid_4x4_rounded,
  ),
  ItemDef(
    slug: 'dusk_ball',
    name: 'Dusk Ball',
    category: ItemCategory.balls,
    description: '3× against Dark and Ghost types.',
    price: 1000,
    icon: Icons.dark_mode_rounded,
  ),
  ItemDef(
    slug: 'potion',
    name: 'Potion',
    category: ItemCategory.medicine,
    description: 'Restores 20 HP to one Pokémon.',
    price: 300,
    icon: Icons.local_hospital_rounded,
  ),
  ItemDef(
    slug: 'super_potion',
    name: 'Super Potion',
    category: ItemCategory.medicine,
    description: 'Restores 60 HP to one Pokémon.',
    price: 700,
    icon: Icons.local_hospital_rounded,
  ),
  ItemDef(
    slug: 'hyper_potion',
    name: 'Hyper Potion',
    category: ItemCategory.medicine,
    description: 'Restores 120 HP to one Pokémon.',
    price: 1500,
    icon: Icons.medical_services_rounded,
  ),
  ItemDef(
    slug: 'full_restore',
    name: 'Full Restore',
    category: ItemCategory.medicine,
    description: 'Fully restores one Pokémon.',
    price: 3000,
    icon: Icons.healing_rounded,
  ),
  ItemDef(
    slug: 'revive',
    name: 'Revive',
    category: ItemCategory.medicine,
    description: 'Wakes a fainted Pokémon with half HP.',
    price: 1500,
    icon: Icons.favorite_rounded,
  ),
  ItemDef(
    slug: 'rare_candy',
    name: 'Rare Candy',
    category: ItemCategory.medicine,
    description: 'Raises one Pokémon by a level.',
    price: 4800,
    icon: Icons.cake_rounded,
  ),
  ItemDef(
    slug: 'exp_candy_l',
    name: 'EXP Candy L',
    category: ItemCategory.medicine,
    description: 'Gives one Pokémon 500 EXP.',
    price: 1200,
    icon: Icons.auto_graph_rounded,
  ),
  ItemDef(
    slug: 'razz_berry',
    name: 'Razz Berry',
    category: ItemCategory.berries,
    description: 'A thrown berry. 1.5× catch rate for one throw.',
    price: 250,
    icon: Icons.energy_savings_leaf_rounded,
  ),
  ItemDef(
    slug: 'golden_razz',
    name: 'Golden Razz Berry',
    category: ItemCategory.berries,
    description: 'A rare berry. 2.5× catch rate for one throw.',
    price: 900,
    icon: Icons.emoji_food_beverage_rounded,
  ),
  ItemDef(
    slug: 'sitrus_berry',
    name: 'Sitrus Berry',
    category: ItemCategory.berries,
    description: 'Held berry that restores HP in battle.',
    price: 250,
    icon: Icons.energy_savings_leaf_rounded,
  ),
  ItemDef(
    slug: 'lum_berry',
    name: 'Lum Berry',
    category: ItemCategory.berries,
    description: 'Held berry that cures status once.',
    price: 300,
    icon: Icons.energy_savings_leaf_rounded,
  ),
  ItemDef(
    slug: 'tm_earthquake',
    name: 'TM Earthquake',
    category: ItemCategory.tms,
    description: 'Teaches Earthquake. Consumed on use.',
    price: 3000,
    icon: Icons.menu_book_rounded,
  ),
  ItemDef(
    slug: 'tm_shadow_ball',
    name: 'TM Shadow Ball',
    category: ItemCategory.tms,
    description: 'Teaches Shadow Ball. Consumed on use.',
    price: 3000,
    icon: Icons.menu_book_rounded,
  ),
  ItemDef(
    slug: 'incense',
    name: 'Incense',
    category: ItemCategory.key,
    description: 'Forces a spawn in the current zone.',
    price: 800,
    icon: Icons.air_rounded,
  ),
  ItemDef(
    slug: 'lure_module',
    name: 'Lure Module',
    category: ItemCategory.key,
    description: 'Faster spawns for 30 minutes.',
    price: 1000,
    icon: Icons.bolt_rounded,
  ),
  ItemDef(
    slug: 'iv_scanner',
    name: 'IV Scanner',
    category: ItemCategory.key,
    description: 'Reveals the IVs of one Pokémon.',
    price: 2500,
    icon: Icons.search_rounded,
  ),
  ItemDef(
    slug: 'apricorn_red',
    name: 'Red Apricorn',
    category: ItemCategory.materials,
    description: 'Crafting material for Poké Balls.',
    price: 150,
    icon: Icons.spa_rounded,
  ),
  ItemDef(
    slug: 'apricorn_blue',
    name: 'Blue Apricorn',
    category: ItemCategory.materials,
    description: 'Crafting material for Lure Balls.',
    price: 150,
    icon: Icons.spa_rounded,
  ),
];

ItemDef? itemBySlug(String slug) {
  for (final item in itemCatalog) {
    if (item.slug == slug) return item;
  }
  return null;
}
