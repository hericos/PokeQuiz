import 'dart:math';

import '../models/pokemon.dart';
import '../models/quiz.dart';

/// Gera as perguntas do "Quem é esse Pokémon?".
class QuizEngine {
  QuizEngine({Random? random, List<Pokemon>? pool})
    : _random = random ?? Random(),
      _pool = pool ?? Pokemon.all;

  static const questionsPerLevel = 10;

  final Random _random;
  final List<Pokemon> _pool;

  /// Partida completa: 10 Pokémon por level, sem repetir na partida.
  List<QuizQuestion> buildGame() {
    final answers = ([..._pool]..shuffle(_random))
        .take(questionsPerLevel * QuizLevel.values.length)
        .toList();
    return [
      for (var i = 0; i < answers.length; i++)
        _question(QuizLevel.values[i ~/ questionsPerLevel], answers[i]),
    ];
  }

  final _used = <Pokemon>{};

  /// Próxima pergunta do modo infinito: sem repetir Pokémon até esgotar a
  /// Pokédex (aí recomeça).
  QuizQuestion nextQuestion(QuizLevel level) {
    if (_used.length >= _pool.length) _used.clear();
    Pokemon answer;
    do {
      answer = _pool[_random.nextInt(_pool.length)];
    } while (_used.contains(answer));
    _used.add(answer);
    return _question(level, answer);
  }

  QuizQuestion _question(QuizLevel level, Pokemon answer) => QuizQuestion(
    level: level,
    answer: answer,
    options: level.isTyped ? const [] : _optionsFor(answer, level.optionCount),
    cropX: _random.nextDouble() - 0.5,
    cropY: _random.nextDouble() - 0.5,
  );

  List<Pokemon> _optionsFor(Pokemon answer, int count) {
    final options = <Pokemon>{answer};
    while (options.length < count) {
      options.add(_pool[_random.nextInt(_pool.length)]);
    }
    return options.toList()..shuffle(_random);
  }

  static const _accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  /// Remove acento de um caractere minúsculo ("é" -> "e").
  static String stripAccent(String lowerChar) =>
      _accents[lowerChar] ?? lowerChar;

  /// Normaliza para comparar respostas digitadas: ignora maiúsculas,
  /// acentos, espaços e pontuação. "Mr. Mime" == "mrmime".
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      final c = switch (ch) {
        '♀' => 'f',
        '♂' => 'm',
        _ => stripAccent(ch),
      };
      if (RegExp(r'[a-z0-9]').hasMatch(c)) buffer.write(c);
    }
    return buffer.toString();
  }

  static bool isCorrectTypedAnswer(Pokemon answer, String typed) {
    final guess = normalize(typed);
    if (guess.isEmpty) return false;
    if (guess == normalize(answer.name)) return true;
    // Nidoran♀/♂: aceita também "nidoran" puro.
    return answer.name.startsWith('Nidoran') && guess == 'nidoran';
  }
}
