import '../data/kanto_pokemon.dart';

class Pokemon {
  final int id;
  final String name;

  const Pokemon(this.id, this.name);

  /// Arte oficial hospedada pelo projeto PokeAPI/sprites.
  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get dexNumber => '#${id.toString().padLeft(3, '0')}';

  static final List<Pokemon> kanto = List.unmodifiable([
    for (var i = 0; i < kantoPokemonNames.length; i++)
      Pokemon(i + 1, kantoPokemonNames[i]),
  ]);

  static Pokemon? byName(String? name) {
    if (name == null) return null;
    for (final p in kanto) {
      if (p.name == name) return p;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is Pokemon && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
