import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/models/pokemon.dart';
import 'package:pokequiz/models/quiz.dart';
import 'package:pokequiz/services/quiz_engine.dart';

void main() {
  test('Kanto tem 151 Pokémon com ids de 1 a 151', () {
    expect(Pokemon.kanto, hasLength(151));
    expect(Pokemon.kanto.first.name, 'Bulbasaur');
    expect(Pokemon.kanto.last.id, 151);
    expect(Pokemon.kanto[24].name, 'Pikachu');
  });

  group('buildRound', () {
    final engine = QuizEngine(random: Random(42));

    for (final level in QuizLevel.values) {
      test('${level.label}: 10 Pokémon distintos e alternativas válidas', () {
        final round = engine.buildRound(level);
        expect(round, hasLength(10));
        expect(round.map((q) => q.answer).toSet(), hasLength(10));
        for (final q in round) {
          if (level.isTyped) {
            expect(q.options, isEmpty);
          } else {
            expect(q.options, hasLength(level.optionCount));
            expect(q.options.toSet(), hasLength(level.optionCount));
            expect(q.options, contains(q.answer));
          }
          expect(q.cropX, inInclusiveRange(-0.6, 0.6));
          expect(q.cropY, inInclusiveRange(-0.6, 0.6));
        }
      });
    }
  });

  group('resposta digitada', () {
    Pokemon byName(String n) => Pokemon.byName(n)!;

    test('ignora caixa, espaços e pontuação', () {
      expect(QuizEngine.isCorrectTypedAnswer(byName('Pikachu'), ' pikachu '), isTrue);
      expect(QuizEngine.isCorrectTypedAnswer(byName('Mr. Mime'), 'mr mime'), isTrue);
      expect(QuizEngine.isCorrectTypedAnswer(byName("Farfetch'd"), 'Farfetchd'), isTrue);
    });

    test('Nidoran aceita com ou sem gênero', () {
      expect(QuizEngine.isCorrectTypedAnswer(byName('Nidoran♀'), 'Nidoran'), isTrue);
      expect(QuizEngine.isCorrectTypedAnswer(byName('Nidoran♂'), 'nidoran m'), isTrue);
    });

    test('rejeita respostas erradas ou vazias', () {
      expect(QuizEngine.isCorrectTypedAnswer(byName('Pikachu'), 'Raichu'), isFalse);
      expect(QuizEngine.isCorrectTypedAnswer(byName('Pikachu'), ''), isFalse);
    });
  });

  group('pontuação', () {
    test('zero acertos = zero pontos', () {
      const r = QuizResult(
          level: QuizLevel.full, correct: 0, total: 10, elapsed: Duration(seconds: 5));
      expect(r.score, 0);
    });

    test('bônus de velocidade limitado a 50%', () {
      const fast = QuizResult(
          level: QuizLevel.shadowTyped, correct: 10, total: 10, elapsed: Duration(seconds: 1));
      const slow = QuizResult(
          level: QuizLevel.shadowTyped, correct: 10, total: 10, elapsed: Duration(minutes: 5));
      expect(fast.score, 750);
      expect(slow.score, 500);
    });
  });

  test('título de treinador', () {
    expect(trainerTitle(0), 'Treinador Iniciante');
    expect(trainerTitle(1650), 'Mestre Pokémon');
  });
}
