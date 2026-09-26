import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/models/dex.dart';
import 'package:pokequiz/models/pokemon.dart';
import 'package:pokequiz/services/stat_duel_engine.dart';

void main() {
  final dex = Dex.parse(File('assets/data/pokedex.json').readAsStringSync());
  List<int> stats(String name) => dex.of(Pokemon.byName(name)!.id).stats;
  PokemonForm form(String name) =>
      dex.forms.firstWhere((f) => f.pokemon.name == name);

  test('status base conferem com valores oficiais', () {
    expect(stats('Pikachu'), [35, 55, 40, 50, 50, 90]);
    expect(PokeStat.hp.of(stats('Chansey')), 250);
    expect(PokeStat.speed.of(stats('Deoxys')), 150);
    expect(PokeStat.total.of(stats('Mewtwo')), 680);
    expect(PokeStat.total.of(stats('Arceus')), 720);
  });

  test(
    'formas extras: Megas, regionais e alternativas com status próprios',
    () {
      expect(dex.forms.length, greaterThan(150));
      final megaX = form('Mega Charizard X');
      expect(megaX.pokemon.dex, 6);
      expect(megaX.pokemon.dexNumber, '#0006');
      expect(megaX.pokemon.imageUrl, endsWith('/${megaX.pokemon.id}.png'));
      expect(PokeStat.total.of(megaX.stats), 634);
      expect(PokeStat.speed.of(form('Attack Deoxys').stats), 150);
      expect(form('Alolan Raichu').pokemon.region.label, 'Alola');
      expect(dex.forms.any((f) => f.pokemon.name.contains('Hisuian')), isTrue);
      // Sem formas puramente cosméticas.
      expect(dex.forms.any((f) => f.pokemon.name.contains('Totem')), isFalse);
    },
  );

  test('sorteio favorece evoluções e formas extras', () {
    final engine = StatDuelEngine(dex, random: Random(3));
    var basic = 0, evolved = 0, forms = 0;
    for (var i = 0; i < 3000; i++) {
      for (final p in engine.next().pair) {
        if (p.speciesId != null) {
          forms++;
        } else if (dex.of(p.id).stage == 1) {
          basic++;
        } else {
          evolved++;
        }
      }
    }
    // Na Pokédex há mais básicos (541) que evoluídos (484); no jogo, o
    // contrário, e as formas extras aparecem com frequência.
    expect(evolved, greaterThan(basic * 2));
    expect(forms, greaterThan(500));
  });

  test('rodadas: dois Pokémon diferentes, sem empate, vencedor correto', () {
    final engine = StatDuelEngine(dex, random: Random(9));
    final seen = <PokeStat>{};
    for (var i = 0; i < 500; i++) {
      final r = engine.next();
      seen.add(r.stat);
      expect(r.left, isNot(r.right));
      expect(r.leftValue, isNot(r.rightValue));
      expect(r.values[r.winner], r.values.reduce(max));
    }
    expect(seen, PokeStat.values.toSet(), reason: 'todos os status aparecem');
  });
}
