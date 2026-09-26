import 'pokemon.dart';

/// Levels do "Quem é esse Pokémon?", jogados em sequência numa mesma partida.
enum QuizLevel {
  full(1, 'Pokémon inteiro', 3, 10),
  partial(2, 'Só um pedaço', 3, 20),
  shadowChoice(3, 'Só a sombra', 4, 30),
  shadowTyped(4, 'Sombra + digitar o nome', 0, 50);

  const QuizLevel(this.number, this.title, this.optionCount, this.pointsPerHit);

  final int number;
  final String title;

  /// Quantidade de alternativas (0 = resposta digitada).
  final int optionCount;
  final int pointsPerHit;

  String get label => 'Level $number';
  bool get isTyped => optionCount == 0;

  /// Pontos por acerto + bônus de velocidade (até +50% abaixo de 5s).
  int pointsFor(Duration answerTime) {
    final secs = answerTime.inMilliseconds / 1000;
    final bonus = ((10 - secs) / 10).clamp(0.0, 0.5);
    return (pointsPerHit * (1 + bonus)).round();
  }
}

class QuizQuestion {
  final QuizLevel level;
  final Pokemon answer;
  final List<Pokemon> options;

  /// Para o Level 2: centro da janela de recorte, de -1 a 1 em cada eixo.
  final double cropX;
  final double cropY;

  const QuizQuestion({
    required this.level,
    required this.answer,
    required this.options,
    this.cropX = 0,
    this.cropY = 0,
  });
}

class RankingEntry {
  final String userId;
  final String name;
  final String? photo;
  final int score;
  final String? detail;

  const RankingEntry({
    required this.userId,
    required this.name,
    required this.photo,
    required this.score,
    this.detail,
  });
}

/// Título de treinador de acordo com a pontuação total (soma dos recordes).
String trainerTitle(int totalScore) {
  if (totalScore >= 2500) return 'Mestre Pokémon';
  if (totalScore >= 1500) return 'Campeão da Liga';
  if (totalScore >= 800) return 'Líder de Ginásio';
  if (totalScore >= 400) return 'Treinador Experiente';
  if (totalScore >= 100) return 'Treinador';
  return 'Treinador Iniciante';
}
