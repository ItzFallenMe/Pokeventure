/// The 18 Pokémon types. Kept in the data layer so the UI can map colours
/// separately (see `lib/ui/tokens/type_palette.dart`).
enum PokemonType {
  normal('Normal'),
  fire('Fire'),
  water('Water'),
  electric('Electric'),
  grass('Grass'),
  ice('Ice'),
  fighting('Fighting'),
  poison('Poison'),
  ground('Ground'),
  flying('Flying'),
  psychic('Psychic'),
  bug('Bug'),
  rock('Rock'),
  ghost('Ghost'),
  dragon('Dragon'),
  dark('Dark'),
  steel('Steel'),
  fairy('Fairy');

  const PokemonType(this.label);

  final String label;
}
