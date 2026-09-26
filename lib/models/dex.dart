import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'pokemon.dart';

/// Características de cada Pokémon usadas no "Qual é o diferente?".
/// Dados gerados a partir da PokeAPI (assets/data/pokedex.json).
class PokemonTraits {
  const PokemonTraits({
    required this.types,
    required this.stage,
    required this.evolutionMethod,
    required this.hasMega,
    required this.legend,
    required this.shinyColor,
    required this.abilities,
    required this.moves,
    required this.stats,
  });

  /// Status base: HP, Ataque, Defesa, Ataque Esp., Defesa Esp., Velocidade.
  final List<int> stats;

  /// Tipos em inglês ("fire", "flying").
  final List<String> types;

  /// 1 = básico, 2 = primeira evolução, 3 = segunda evolução.
  final int stage;

  /// Como evoluiu da forma anterior: level, item, trade, friendship, special.
  /// null para Pokémon básicos.
  final String? evolutionMethod;
  final bool hasMega;

  /// 0 = comum, 1 = lendário, 2 = mítico.
  final int legend;

  /// Cor predominante da arte shiny; null quando é muito misturada.
  final String? shinyColor;
  final Set<String> abilities;
  final Set<String> moves;

  bool get isLegendaryOrMythical => legend > 0;
}

/// Forma extra (Mega, regional, Therian...) com status próprios.
class PokemonForm {
  const PokemonForm(this.pokemon, this.stats);

  final Pokemon pokemon;
  final List<int> stats;
}

class Dex {
  Dex._(this.traits, this.moves, this.abilities, this.forms);

  /// Índice = número da Pokédex - 1.
  final List<PokemonTraits> traits;
  final List<String> moves;
  final List<String> abilities;
  final List<PokemonForm> forms;

  /// Características da espécie (formas extras usam as da espécie).
  PokemonTraits of(int id) => traits[id - 1];

  static Future<Dex>? _loading;

  static Future<Dex> load() => _loading ??= rootBundle
      .loadString('assets/data/pokedex.json')
      .then(parse);

  static Dex parse(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final moves = (data['moves'] as List).cast<String>();
    final abilities = (data['abilities'] as List).cast<String>();
    final traits = [
      for (final p in data['pokemon'] as List)
        PokemonTraits(
          types: (p[0] as List).cast<String>(),
          stage: p[1] as int,
          evolutionMethod: p[2] as String?,
          hasMega: p[3] == 1,
          legend: p[4] as int,
          shinyColor: p[5] as String?,
          abilities: {for (final i in p[6] as List) abilities[i as int]},
          moves: {for (final i in p[7] as List) moves[i as int]},
          stats: (p[8] as List).cast<int>(),
        ),
    ];
    final forms = [
      for (final f in (data['forms'] as List?) ?? const [])
        PokemonForm(
          Pokemon(f[0] as int, f[2] as String, speciesId: f[1] as int),
          (f[3] as List).cast<int>(),
        ),
    ];
    return Dex._(traits, moves, abilities, forms);
  }
}

const typeNamesPt = {
  'normal': 'Normal',
  'fighting': 'Lutador',
  'flying': 'Voador',
  'poison': 'Venenoso',
  'ground': 'Terrestre',
  'rock': 'Pedra',
  'bug': 'Inseto',
  'ghost': 'Fantasma',
  'steel': 'Aço',
  'fire': 'Fogo',
  'water': 'Água',
  'grass': 'Planta',
  'electric': 'Elétrico',
  'psychic': 'Psíquico',
  'ice': 'Gelo',
  'dragon': 'Dragão',
  'dark': 'Sombrio',
  'fairy': 'Fada',
};

const colorNamesPt = {
  'blue': 'Azul',
  'green': 'Verde',
  'white': 'Branco',
  'yellow': 'Amarelo',
  'black': 'Preto',
  'orange': 'Laranja',
  'pink': 'Rosa',
  'red': 'Vermelho',
  'gray': 'Cinza',
  'purple': 'Roxo',
  'brown': 'Marrom',
};

const evolutionMethodNamesPt = {
  'level': 'Por nível',
  'item': 'Com pedra/item',
  'trade': 'Por troca',
  'friendship': 'Por amizade',
  'special': 'Por condição especial',
};

const stageNamesPt = {1: 'Básico', 2: '1ª evolução', 3: '2ª evolução'};

const legendNamesPt = {0: 'Comum', 1: 'Lendário', 2: 'Mítico'};
