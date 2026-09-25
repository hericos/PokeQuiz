import 'dart:math';

import '../models/pokemon.dart';
import '../models/quiz.dart';

/// Gera as rodadas do "Quem é esse Pokémon?".
class QuizEngine {
  QuizEngine({Random? random, List<Pokemon>? pool})
      : _random = random ?? Random(),
        _pool = pool ?? Pokemon.kanto;

  static const questionsPerLevel = 10;

  final Random _random;
  final List<Pokemon> _pool;

  /// 10 Pokémon aleatórios e distintos, com alternativas embaralhadas.
  List<QuizQuestion> buildRound(QuizLevel level) {
    final answers = ([..._pool]..shuffle(_random)).take(questionsPerLevel);
    return [
      for (final answer in answers)
        QuizQuestion(
          answer: answer,
          options: level.isTyped ? const [] : _optionsFor(answer, level.optionCount),
          cropX: _random.nextDouble() * 1.2 - 0.6,
          cropY: _random.nextDouble() * 1.2 - 0.6,
        ),
    ];
  }

  List<Pokemon> _optionsFor(Pokemon answer, int count) {
    final options = <Pokemon>{answer};
    while (options.length < count) {
      options.add(_pool[_random.nextInt(_pool.length)]);
    }
    return options.toList()..shuffle(_random);
  }

  /// Normaliza para comparar respostas digitadas: ignora maiúsculas,
  /// acentos, espaços e pontuação. "Mr. Mime" == "mrmime".
  static String normalize(String input) {
    const accents = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
      '♀': 'f', '♂': 'm',
    };
    final buffer = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      final c = accents[ch] ?? ch;
      if (RegExp(r'[a-z0-9]').hasMatch(c)) buffer.write(c);
    }
    return buffer.toString();
  }

  static bool isCorrectTypedAnswer(Pokemon answer, String typed) {
    final guess = normalize(typed);
    if (guess.isEmpty) return false;
    final expected = normalize(answer.name);
    if (guess == expected) return true;
    // Nidoran♀/♂: aceita também "nidoran" puro.
    if (answer.name.startsWith('Nidoran') && guess == 'nidoran') return true;
    return false;
  }
}
