import 'dart:math';

import '../models/dex.dart';
import '../models/pokemon.dart';

enum OddCriterion {
  type('Tipo'),
  evolutionMethod('Método de evolução'),
  firstLetter('Primeira letra do nome'),
  mega('Forma Mega'),
  region('Região'),
  stage('Estágio da evolução'),
  shinyColor('Cor da forma shiny'),
  ability('Habilidade'),
  move('Ataque'),
  legendary('Lendário / Mítico');

  const OddCriterion(this.label);

  final String label;
}

class OddRound {
  const OddRound({
    required this.criterion,
    required this.pokemon,
    required this.oddIndex,
    required this.labels,
    required this.explanation,
  });

  final OddCriterion criterion;

  /// Os 4 Pokémon, na ordem do quadrado 2x2.
  final List<Pokemon> pokemon;
  final int oddIndex;

  /// Valor do critério de cada Pokémon, mostrado após a resposta.
  final List<String> labels;
  final String explanation;

  Pokemon get odd => pokemon[oddIndex];
  bool get showsShiny => criterion == OddCriterion.shinyColor;
}

/// Monta rodadas de "Qual é o diferente?": 3 Pokémon compartilham algo pelo
/// critério sorteado e 1 não.
class OddOneOutEngine {
  OddOneOutEngine(this.dex, {Random? random}) : _random = random ?? Random();

  final Dex dex;
  final Random _random;

  OddRound next() {
    while (true) {
      final c =
          OddCriterion.values[_random.nextInt(OddCriterion.values.length)];
      final round = build(c);
      if (round != null) return round;
    }
  }

  /// Rodada para um critério específico (null se não achou combinação).
  OddRound? build(OddCriterion c) {
    PokemonTraits t(Pokemon p) => dex.traitsOf(p);
    final all = Pokemon.everything;

    switch (c) {
      case OddCriterion.type:
        final type = _pick(typeNamesPt.keys.toList());
        return _make(
          c,
          group: all.where((p) => t(p).types.contains(type)),
          others: all.where((p) => !t(p).types.contains(type)),
          label: (p) => t(p).types.map((x) => typeNamesPt[x] ?? x).join(' / '),
          explanation: (odd) =>
              'Os outros são do tipo ${typeNamesPt[type]}; ${odd.name} não.',
        );

      case OddCriterion.evolutionMethod:
        const methods = ['level', 'item', 'trade', 'friendship'];
        final m = _pick(methods);
        return _make(
          c,
          group: all.where((p) => t(p).evolutionMethod == m),
          others: all.where(
            (p) => t(p).evolutionMethod != null && t(p).evolutionMethod != m,
          ),
          label: (p) => evolutionMethodNamesPt[t(p).evolutionMethod] ?? '-',
          explanation: (odd) =>
              'Os outros evoluíram ${evolutionMethodNamesPt[m]!.toLowerCase()}; '
              '${odd.name} evoluiu ${evolutionMethodNamesPt[t(odd).evolutionMethod]!.toLowerCase()}.',
        );

      case OddCriterion.firstLetter:
        final letter = _pick(all).name[0];
        return _make(
          c,
          group: all.where((p) => p.name[0] == letter),
          others: all.where((p) => p.name[0] != letter),
          label: (p) => 'Letra ${p.name[0]}',
          explanation: (odd) =>
              'Os outros começam com "$letter"; ${odd.name} começa com "${odd.name[0]}".',
        );

      case OddCriterion.mega:
        final oddHasMega = _random.nextBool();
        return _make(
          c,
          group: Pokemon.all.where((p) => t(p).hasMega != oddHasMega),
          others: Pokemon.all.where((p) => t(p).hasMega == oddHasMega),
          label: (p) => t(p).hasMega ? 'Tem Mega' : 'Sem Mega',
          explanation: (odd) => oddHasMega
              ? '${odd.name} é o único com Mega Evolução.'
              : '${odd.name} é o único sem Mega Evolução.',
        );

      case OddCriterion.region:
        final region = _pick(Region.values);
        return _make(
          c,
          group: all.where((p) => p.region == region),
          others: all.where((p) => p.region != region),
          label: (p) => p.region.label,
          explanation: (odd) =>
              'Os outros são de ${region.label}; ${odd.name} é de ${odd.region.label}.',
        );

      case OddCriterion.stage:
        final stage = 1 + _random.nextInt(3);
        return _make(
          c,
          group: all.where((p) => t(p).stage == stage),
          others: all.where((p) => t(p).stage != stage),
          label: (p) => stageNamesPt[t(p).stage]!,
          explanation: (odd) =>
              'Os outros são "${stageNamesPt[stage]}"; ${odd.name} é "${stageNamesPt[t(odd).stage]}".',
        );

      case OddCriterion.shinyColor:
        final color = _pick(colorNamesPt.keys.toList());
        return _make(
          c,
          group: all.where((p) => t(p).shinyColor == color),
          others: all.where(
            (p) => t(p).shinyColor != null && t(p).shinyColor != color,
          ),
          label: (p) => colorNamesPt[t(p).shinyColor] ?? '-',
          explanation: (odd) =>
              'Na forma shiny, os outros são ${colorNamesPt[color]!.toLowerCase()}; '
              '${odd.name} é ${colorNamesPt[t(odd).shinyColor]!.toLowerCase()}.',
        );

      case OddCriterion.ability:
        final ability = _pick(dex.abilities);
        return _make(
          c,
          group: all.where((p) => t(p).abilities.contains(ability)),
          others: all.where((p) => !t(p).abilities.contains(ability)),
          label: (p) =>
              t(p).abilities.contains(ability) ? '✓ $ability' : '✗ $ability',
          explanation: (odd) =>
              'Os outros podem ter a habilidade $ability; ${odd.name} não.',
        );

      case OddCriterion.move:
        final move = _pick(dex.moves);
        return _make(
          c,
          group: all.where((p) => t(p).moves.contains(move)),
          others: all.where((p) => !t(p).moves.contains(move)),
          label: (p) => t(p).moves.contains(move) ? '✓ $move' : '✗ $move',
          explanation: (odd) =>
              'Os outros aprendem o ataque $move; ${odd.name} não.',
        );

      case OddCriterion.legendary:
        final oddIsLegend = _random.nextBool();
        return _make(
          c,
          group: all.where((p) => t(p).isLegendaryOrMythical != oddIsLegend),
          others: all.where((p) => t(p).isLegendaryOrMythical == oddIsLegend),
          label: (p) => legendNamesPt[t(p).legend]!,
          explanation: (odd) => oddIsLegend
              ? '${odd.name} é o único lendário/mítico.'
              : '${odd.name} é o único que não é lendário nem mítico.',
        );
    }
  }

  T _pick<T>(List<T> list) => list[_random.nextInt(list.length)];

  OddRound? _make(
    OddCriterion c, {
    required Iterable<Pokemon> group,
    required Iterable<Pokemon> others,
    required String Function(Pokemon) label,
    required String Function(Pokemon odd) explanation,
  }) {
    final g = group.toList();
    final o = others.toList();
    if (g.length < 3 || o.isEmpty) return null;
    g.shuffle(_random);
    final odd = _pick(o);
    final four = [...g.take(3), odd]..shuffle(_random);
    return OddRound(
      criterion: c,
      pokemon: four,
      oddIndex: four.indexOf(odd),
      labels: [for (final p in four) label(p)],
      explanation: explanation(odd),
    );
  }
}
