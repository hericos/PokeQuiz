import 'pokemon.dart';

enum QuizLevel {
  full(1, 'Level 1', 'Pokémon inteiro', 'Veja o Pokémon completo e escolha entre 3 opções.', 3, 10),
  partial(2, 'Level 2', 'Só um pedaço', 'Apenas 25% da imagem aparece. Escolha entre 3 opções.', 3, 20),
  shadowChoice(3, 'Level 3', 'Sombra', 'Só a silhueta! Escolha entre 4 opções.', 4, 30),
  shadowTyped(4, 'Level 4', 'Sombra + digitação', 'Só a silhueta, e você precisa escrever o nome.', 0, 50);

  const QuizLevel(this.number, this.label, this.title, this.description,
      this.optionCount, this.pointsPerHit);

  final int number;
  final String label;
  final String title;
  final String description;

  /// Quantidade de alternativas (0 = resposta digitada).
  final int optionCount;
  final int pointsPerHit;

  bool get isTyped => optionCount == 0;
  bool get showsShadow => this == shadowChoice || this == shadowTyped;

  static QuizLevel fromNumber(int n) =>
      values.firstWhere((l) => l.number == n);
}

class QuizQuestion {
  final Pokemon answer;
  final List<Pokemon> options;

  /// Para o Level 2: centro da janela de recorte, de -1 a 1 em cada eixo.
  final double cropX;
  final double cropY;

  const QuizQuestion({
    required this.answer,
    required this.options,
    this.cropX = 0,
    this.cropY = 0,
  });
}

class QuizResult {
  final QuizLevel level;
  final int correct;
  final int total;
  final Duration elapsed;

  const QuizResult({
    required this.level,
    required this.correct,
    required this.total,
    required this.elapsed,
  });

  /// Pontos por acerto + bônus de velocidade (até 50% a mais em rodadas rápidas).
  int get score {
    final base = correct * level.pointsPerHit;
    if (correct == 0) return 0;
    final secsPerQuestion = elapsed.inMilliseconds / 1000 / total;
    final speedFactor = ((10 - secsPerQuestion) / 10).clamp(0.0, 0.5);
    return (base * (1 + speedFactor)).round();
  }
}

class RankingEntry {
  final int userId;
  final String name;
  final String? photo;
  final int score;
  final int? correct;

  const RankingEntry({
    required this.userId,
    required this.name,
    required this.photo,
    required this.score,
    this.correct,
  });
}

/// Título de treinador de acordo com a pontuação total.
String trainerTitle(int totalScore) {
  if (totalScore >= 1500) return 'Mestre Pokémon';
  if (totalScore >= 1000) return 'Campeão da Liga';
  if (totalScore >= 600) return 'Líder de Ginásio';
  if (totalScore >= 300) return 'Treinador Experiente';
  if (totalScore >= 100) return 'Treinador';
  return 'Treinador Iniciante';
}
