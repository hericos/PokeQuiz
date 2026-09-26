import '../data/pokemon_names.dart';

enum Region {
  kanto('Kanto', 1, 151),
  johto('Johto', 152, 251),
  hoenn('Hoenn', 252, 386),
  sinnoh('Sinnoh', 387, 493),
  unova('Unova', 494, 649),
  kalos('Kalos', 650, 721),
  alola('Alola', 722, 809),
  galar('Galar', 810, 898),
  hisui('Hisui', 899, 905),
  paldea('Paldea', 906, 1025);

  const Region(this.label, this.first, this.last);

  final String label;
  final int first;
  final int last;

  static Region of(int id) =>
      values.firstWhere((r) => id >= r.first && id <= r.last);
}

class Pokemon {
  /// Número usado nas imagens da PokeAPI: o da Pokédex, ou 10001+ para
  /// formas extras (Mega, regionais...).
  final int id;
  final String name;

  /// Espécie da forma extra (ex.: Mega Charizard X → 6). null = forma base.
  final int? speciesId;

  const Pokemon(this.id, this.name, {this.speciesId});

  int get dex => speciesId ?? id;

  /// Arte oficial hospedada pelo projeto PokeAPI/sprites.
  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get shinyImageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/$id.png';

  String get dexNumber => '#${dex.toString().padLeft(4, '0')}';

  Region get region => Region.of(dex);

  /// Todos os Pokémon de todas as regiões.
  static final List<Pokemon> all = List.unmodifiable([
    for (var i = 0; i < pokemonNames.length; i++)
      Pokemon(i + 1, pokemonNames[i]),
  ]);

  static Pokemon? byName(String? name) {
    if (name == null) return null;
    for (final p in all) {
      if (p.name == name) return p;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is Pokemon && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
