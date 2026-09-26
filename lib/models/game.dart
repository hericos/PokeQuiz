import 'package:flutter/material.dart';

/// Catálogo de jogos do PokeQuiz. Para adicionar um jogo novo, inclua um
/// valor aqui e registre a tela em `screens/games_screen.dart`.
enum GameId {
  whosThat(
    'Quem é esse Pokémon?',
    'Adivinhe o Pokémon. A cada 10 respostas você sobe de level: inteiro, pedaço, sombra e sombra digitando.',
    Icons.visibility,
  ),
  hangman(
    'Forca',
    'Descubra o nome do Pokémon letra por letra antes que o Banette fique completo na forca.',
    Icons.abc,
  );

  const GameId(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}
