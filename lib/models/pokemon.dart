import '../data/pokemon_forms.dart';
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

  bool get isForm => speciesId != null;

  /// Formas regionais contam como da região delas (Alolan Raichu → Alola).
  Region get region {
    if (isForm) {
      for (final (word, region) in const [
        ('Alolan', Region.alola),
        ('Galarian', Region.galar),
        ('Hisuian', Region.hisui),
        ('Paldean', Region.paldea),
      ]) {
        if (name.contains(word)) return region;
      }
    }
    return Region.of(dex);
  }

  /// Todos os Pokémon de todas as regiões.
  static final List<Pokemon> all = List.unmodifiable([
    for (var i = 0; i < pokemonNames.length; i++)
      Pokemon(i + 1, pokemonNames[i]),
  ]);

  /// Formas extras: Megas, Primal, regionais e alternativas.
  static final List<Pokemon> forms = List.unmodifiable([
    for (final (id, species, name) in pokemonForms)
      Pokemon(id, name, speciesId: species),
  ]);

  /// Todos os Pokémon mais as formas extras (usado pelos jogos).
  static final List<Pokemon> everything = List.unmodifiable([...all, ...forms]);

  static final Map<String, Pokemon> _byName = {
    for (final p in everything) p.name: p,
  };

  static Pokemon? byName(String? name) => name == null ? null : _byName[name];

  @override
  bool operator ==(Object other) => other is Pokemon && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
