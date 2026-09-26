import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/models/dex.dart';
import 'package:pokequiz/models/pokemon.dart';
import 'package:pokequiz/services/odd_one_out_engine.dart';

void main() {
  final dex = Dex.parse(File('assets/data/pokedex.json').readAsStringSync());
  PokemonTraits t(String name) => dex.of(Pokemon.byName(name)!.id);

  test('dados da Pokédex conferem com fatos conhecidos', () {
    expect(dex.traits, hasLength(1025));
    expect(t('Charizard').types, ['fire', 'flying']);
    expect(t('Charizard').stage, 3);
    expect(t('Charizard').hasMega, isTrue);
    expect(t('Raichu').evolutionMethod, 'item');
    expect(t('Alakazam').evolutionMethod, 'trade');
    expect(t('Espeon').evolutionMethod, 'friendship');
    expect(t('Bulbasaur').evolutionMethod, isNull);
    expect(t('Mewtwo').legend, 1);
    expect(t('Mew').legend, 2);
    expect(t('Pikachu').abilities, contains('Static'));
    expect(t('Pikachu').moves, contains('Thunderbolt'));
    expect(t('Umbreon').shinyColor, 'black');
  });

  test('formas extras têm tipos próprios e região da forma', () {
    final raichu = Pokemon.byName('Alolan Raichu')!;
    expect(raichu.isForm, isTrue);
    expect(dex.traitsOf(raichu).types, ['electric', 'psychic']);
    expect(dex.traitsOf(raichu).stage, 3);
    expect(raichu.region, Region.alola);
    expect(dex.traitsOf(Pokemon.byName('Mega Charizard X')!).types, [
      'fire',
      'dragon',
    ]);
    expect(Pokemon.byName('Hisuian Typhlosion')!.region, Region.hisui);
    expect(Pokemon.byName('Zen Galarian Darmanitan')!.region, Region.galar);
    expect(dex.traitsOf(Pokemon.byName('Wash Rotom')!).types, [
      'electric',
      'water',
    ]);
  });

  test('formas aparecem nas rodadas', () {
    final engine = OddOneOutEngine(dex, random: Random(5));
    var forms = 0;
    for (var n = 0; n < 300; n++) {
      forms += engine.next().pokemon.where((p) => p.isForm).length;
    }
    expect(forms, greaterThan(50));
  });

  test('toda rodada tem 4 Pokémon distintos e o diferente não compartilha o critério', () {
    final engine = OddOneOutEngine(dex, random: Random(7));
    for (final c in OddCriterion.values) {
      for (var n = 0; n < 50; n++) {
        final r = engine.build(c);
        expect(r, isNotNull, reason: '$c');
        expect(r!.pokemon.toSet(), hasLength(4));
        expect(r.labels, hasLength(4));
        final group = [
          for (var i = 0; i < 4; i++)
            if (i != r.oddIndex) r.labels[i],
        ];
        // Os 3 do grupo têm o mesmo rótulo no critério; o diferente, outro.
        if (c != OddCriterion.type && c != OddCriterion.legendary) {
          expect(group.toSet(), hasLength(1), reason: '$c $group');
          expect(r.labels[r.oddIndex], isNot(group.first), reason: '$c');
        }
      }
    }
  });

  test('tipo: os 3 compartilham o tipo e o diferente não tem', () {
    final engine = OddOneOutEngine(dex, random: Random(1));
    for (var n = 0; n < 100; n++) {
      final r = engine.build(OddCriterion.type)!;
      final others = [
        for (var i = 0; i < 4; i++)
          if (i != r.oddIndex) r.pokemon[i],
      ];
      final shared = others
          .map((p) => dex.traitsOf(p).types.toSet())
          .reduce((a, b) => a.intersection(b));
      expect(shared, isNotEmpty);
      expect(
        dex.traitsOf(r.odd).types.toSet().intersection(shared),
        isNot(equals(shared)),
      );
    }
  });
}
