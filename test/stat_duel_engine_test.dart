import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/models/dex.dart';
import 'package:pokequiz/models/pokemon.dart';
import 'package:pokequiz/services/stat_duel_engine.dart';

void main() {
  final dex = Dex.parse(File('assets/data/pokedex.json').readAsStringSync());
  PokemonTraits t(String name) => dex.of(Pokemon.byName(name)!.id);

  test('status base conferem com valores oficiais', () {
    expect(t('Pikachu').stats, [35, 55, 40, 50, 50, 90]);
    expect(PokeStat.hp.of(t('Chansey')), 250);
    expect(PokeStat.speed.of(t('Deoxys')), 150);
    expect(PokeStat.total.of(t('Mewtwo')), 680);
    expect(PokeStat.total.of(t('Arceus')), 720);
  });

  test('rodadas: dois Pokémon diferentes, sem empate, vencedor correto', () {
    final engine = StatDuelEngine(dex, random: Random(9));
    final seen = <PokeStat>{};
    for (var i = 0; i < 500; i++) {
      final r = engine.next();
      seen.add(r.stat);
      expect(r.left, isNot(r.right));
      expect(r.leftValue, isNot(r.rightValue));
      expect(r.leftValue, r.stat.of(dex.of(r.left.id)));
      final winnerValue = r.values[r.winner];
      expect(winnerValue, r.values.reduce(max));
    }
    expect(seen, PokeStat.values.toSet(), reason: 'todos os status aparecem');
  });
}
