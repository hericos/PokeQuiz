import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/models/pokemon.dart';
import 'package:pokequiz/models/quiz.dart';
import 'package:pokequiz/services/quiz_engine.dart';

void main() {
  test('Pokédex nacional completa, #1 a #1025', () {
    expect(Pokemon.all, hasLength(1025));
    expect(Pokemon.all.first.name, 'Bulbasaur');
    expect(Pokemon.all[24].name, 'Pikachu');
    expect(Pokemon.all.last.name, 'Pecharunt');
    expect(Pokemon.all.map((p) => p.name).toSet(), hasLength(1025));
  });

  test('formas extras entram nos jogos, com nomes únicos', () {
    expect(Pokemon.forms.length, greaterThan(150));
    expect(Pokemon.everything.length, 1025 + Pokemon.forms.length);
    expect(
      Pokemon.everything.map((p) => p.name).toSet(),
      hasLength(Pokemon.everything.length),
    );
    final megaX = Pokemon.byName('Mega Charizard X')!;
    expect(megaX.dexNumber, '#0006');
    expect(QuizEngine.isCorrectTypedAnswer(megaX, 'mega charizard x'), isTrue);
    final game = QuizEngine(random: Random(2)).buildGame();
    final many = [
      for (var i = 0; i < 20; i++) ...QuizEngine(random: Random(i)).buildGame(),
    ];
    expect(game, hasLength(40));
    expect(many.where((q) => q.answer.isForm), isNotEmpty);
  });

  test('regiões cobrem todos os números', () {
    expect(Pokemon.byName('Mew')!.region, Region.kanto);
    expect(Pokemon.byName('Chikorita')!.region, Region.johto);
    expect(Pokemon.byName('Sprigatito')!.region, Region.paldea);
    for (final p in Pokemon.all) {
      expect(() => p.region, returnsNormally);
    }
  });

  test('partida: 40 Pokémon distintos, 10 por level, na ordem', () {
    final game = QuizEngine(random: Random(42)).buildGame();
    expect(game, hasLength(40));
    expect(game.map((q) => q.answer).toSet(), hasLength(40));
    for (var i = 0; i < game.length; i++) {
      final q = game[i];
      expect(q.level, QuizLevel.values[i ~/ 10]);
      if (q.level.isTyped) {
        expect(q.options, isEmpty);
      } else {
        expect(q.options, hasLength(q.level.optionCount));
        expect(q.options.toSet(), hasLength(q.level.optionCount));
        expect(q.options, contains(q.answer));
      }
      expect(q.cropX, inInclusiveRange(-0.5, 0.5));
    }
  });

  test('modo infinito: não repete Pokémon e recomeça ao esgotar', () {
    final pool = Pokemon.all.take(5).toList();
    final engine = QuizEngine(random: Random(1), pool: pool);
    final first = [
      for (var i = 0; i < 5; i++) engine.nextQuestion(QuizLevel.shadowChoice),
    ];
    expect(first.map((q) => q.answer).toSet(), hasLength(5));
    expect(first.every((q) => q.level == QuizLevel.shadowChoice), isTrue);
    expect(first.every((q) => q.options.length == 4), isTrue);
    // Esgotou a Pokédex (aqui, 5): continua gerando.
    expect(engine.nextQuestion(QuizLevel.shadowChoice).answer, isIn(pool));
  });

  group('resposta digitada', () {
    Pokemon byName(String n) => Pokemon.byName(n)!;

    test('ignora caixa, espaços, acentos e pontuação', () {
      expect(
        QuizEngine.isCorrectTypedAnswer(byName('Pikachu'), ' pikachu '),
        isTrue,
      );
      expect(
        QuizEngine.isCorrectTypedAnswer(byName('Mr. Mime'), 'mr mime'),
        isTrue,
      );
      expect(
        QuizEngine.isCorrectTypedAnswer(byName('Farfetch’d'), "Farfetch'd"),
        isTrue,
      );
      expect(
        QuizEngine.isCorrectTypedAnswer(byName('Flabébé'), 'flabebe'),
        isTrue,
      );
      expect(
        QuizEngine.isCorrectTypedAnswer(byName('Type: Null'), 'type null'),
        isTrue,
      );
    });

    test('Nidoran aceita com ou sem gênero', () {
      expect(
        QuizEngine.isCorrectTypedAnswer(byName('Nidoran♀'), 'Nidoran'),
        isTrue,
      );
      expect(
        QuizEngine.isCorrectTypedAnswer(byName('Nidoran♂'), 'nidoran m'),
        isTrue,
      );
    });

    test('rejeita respostas erradas ou vazias', () {
      expect(
        QuizEngine.isCorrectTypedAnswer(byName('Pikachu'), 'Raichu'),
        isFalse,
      );
      expect(QuizEngine.isCorrectTypedAnswer(byName('Pikachu'), ''), isFalse);
    });
  });

  test('pontos: bônus de velocidade limitado a +50%', () {
    expect(QuizLevel.shadowTyped.pointsFor(const Duration(seconds: 1)), 75);
    expect(QuizLevel.shadowTyped.pointsFor(const Duration(seconds: 30)), 50);
    expect(QuizLevel.full.pointsFor(const Duration(seconds: 8)), 12);
  });

  test('título de treinador', () {
    expect(trainerTitle(0), 'Treinador Iniciante');
    expect(trainerTitle(3000), 'Mestre Pokémon');
  });
}
