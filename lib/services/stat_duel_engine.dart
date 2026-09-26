import 'dart:math';

import '../models/dex.dart';
import '../models/pokemon.dart';

/// Status comparados no "Quem tem mais?".
enum PokeStat {
  hp('HP'),
  attack('Ataque'),
  defense('Defesa'),
  spAttack('Ataque Especial'),
  spDefense('Defesa Especial'),
  speed('Velocidade'),
  total('Total de status');

  const PokeStat(this.label);

  final String label;

  /// Valor do status numa lista [HP, Atq, Def, AtqEsp, DefEsp, Vel].
  int of(List<int> stats) =>
      this == total ? stats.fold(0, (a, b) => a + b) : stats[index];
}

class StatDuelRound {
  const StatDuelRound({
    required this.stat,
    required this.left,
    required this.right,
    required this.leftValue,
    required this.rightValue,
  });

  final PokeStat stat;
  final Pokemon left;
  final Pokemon right;
  final int leftValue;
  final int rightValue;

  /// 0 = esquerda tem mais, 1 = direita tem mais (nunca empata).
  int get winner => leftValue > rightValue ? 0 : 1;
  List<Pokemon> get pair => [left, right];
  List<int> get values => [leftValue, rightValue];
}

/// Candidato a aparecer no duelo, com peso no sorteio.
typedef DuelEntry = ({Pokemon pokemon, List<int> stats, int weight});

/// Sorteia pares de Pokémon e um status, sem empate. Evoluções (2º e 3º
/// estágio) e formas extras (Mega, regionais...) aparecem com mais frequência.
class StatDuelEngine {
  StatDuelEngine(this.dex, {Random? random})
    : _random = random ?? Random(),
      pool = buildPool(dex) {
    _totalWeight = pool.fold(0, (a, e) => a + e.weight);
  }

  /// Peso por estágio: básico 1, 1ª evolução 3, 2ª evolução 4; formas extras 3.
  static const stageWeights = {1: 1, 2: 3, 3: 4};
  static const formWeight = 3;

  final Dex dex;
  final Random _random;
  final List<DuelEntry> pool;
  late final int _totalWeight;

  static List<DuelEntry> buildPool(Dex dex) => [
    for (final p in Pokemon.all)
      (
        pokemon: p,
        stats: dex.of(p.id).stats,
        weight: stageWeights[dex.of(p.id).stage]!,
      ),
    for (final f in dex.forms)
      (pokemon: f.pokemon, stats: f.stats, weight: formWeight),
  ];

  DuelEntry _pick() {
    var r = _random.nextInt(_totalWeight);
    for (final e in pool) {
      r -= e.weight;
      if (r < 0) return e;
    }
    return pool.last;
  }

  StatDuelRound next() {
    while (true) {
      final stat = PokeStat.values[_random.nextInt(PokeStat.values.length)];
      final a = _pick();
      final b = _pick();
      if (a.pokemon == b.pokemon) continue;
      final va = stat.of(a.stats);
      final vb = stat.of(b.stats);
      if (va == vb) continue;
      return StatDuelRound(
        stat: stat,
        left: a.pokemon,
        right: b.pokemon,
        leftValue: va,
        rightValue: vb,
      );
    }
  }
}
