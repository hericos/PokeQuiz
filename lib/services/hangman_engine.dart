import '../models/pokemon.dart';
import 'quiz_engine.dart';

/// Estado de uma rodada da Forca.
class HangmanRound {
  HangmanRound(this.pokemon);

  static const maxErrors = 5;

  final Pokemon pokemon;
  final Set<String> guessed = {};

  /// Letras (A-Z) que precisam ser descobertas.
  late final Set<String> lettersToFind = {
    for (final ch in pokemon.name.split('')) ?letterOf(ch),
  };

  /// Letra A-Z correspondente a um caractere do nome, ou null se não é letra
  /// (espaço, hífen, ponto, dígito, ♀...), que já aparece revelado.
  static String? letterOf(String ch) {
    final c = QuizEngine.stripAccent(ch.toLowerCase()).toUpperCase();
    return RegExp(r'^[A-Z]$').hasMatch(c) ? c : null;
  }

  /// Vezes que o tempo para escolher uma letra acabou (cada uma é um erro).
  int timeouts = 0;

  int get errors => guessed.difference(lettersToFind).length + timeouts;

  /// O tempo acabou sem escolher letra: conta como erro.
  void timeout() {
    if (!isOver) timeouts++;
  }

  int get livesLeft => maxErrors - errors;
  bool get isWon => lettersToFind.every(guessed.contains);
  bool get isLost => errors >= maxErrors;
  bool get isOver => isWon || isLost;

  /// Registra a letra. Retorna true se ela faz parte do nome.
  bool guess(String letter) {
    letter = letter.toUpperCase();
    if (!isOver) guessed.add(letter);
    return lettersToFind.contains(letter);
  }

  /// Nome com as letras ainda ocultas trocadas por "_".
  String get masked => pokemon.name.split('').map((ch) {
    final l = letterOf(ch);
    return (l == null || guessed.contains(l) || isLost) ? ch : '_';
  }).join();

  /// Pontos pela rodada vencida: 10 + 5 por vida sobrando.
  int get points => isWon ? 10 + 5 * livesLeft : 0;
}
