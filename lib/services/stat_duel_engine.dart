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

  int of(PokemonTraits t) =>
      this == total ? t.stats.fold(0, (a, b) => a + b) : t.stats[index];
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

/// Sorteia pares de Pokémon e um status, sem empate.
class StatDuelEngine {
  StatDuelEngine(this.dex, {Random? random}) : _random = random ?? Random();

  final Dex dex;
  final Random _random;

  StatDuelRound next() {
    final all = Pokemon.all;
    while (true) {
      final stat = PokeStat.values[_random.nextInt(PokeStat.values.length)];
      final a = all[_random.nextInt(all.length)];
      final b = all[_random.nextInt(all.length)];
      if (a == b) continue;
      final va = stat.of(dex.of(a.id));
      final vb = stat.of(dex.of(b.id));
      if (va == vb) continue;
      return StatDuelRound(
        stat: stat,
        left: a,
        right: b,
        leftValue: va,
        rightValue: vb,
      );
    }
  }
}
