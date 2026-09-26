import 'package:flutter/material.dart';

/// Catálogo de jogos do PokeQuiz. Para adicionar um jogo novo, inclua um
/// valor aqui e registre a tela em `screens/games_screen.dart`.
enum GameId {
  whosThat(
    'Quem é esse Pokémon?',
    'Adivinhe o Pokémon: na campanha, a cada 10 respostas você sobe de level; no modo infinito, escolhe o level e joga sem fim.',
    Icons.visibility,
  ),
  hangman(
    'Forca',
    'Descubra o nome do Pokémon letra por letra antes que o Banette fique completo na forca.',
    Icons.abc,
  ),
  oddOneOut(
    'Qual é o diferente?',
    'Quatro Pokémon, um critério: toque no que não combina com os outros. Quantos acertos seguidos você consegue?',
    Icons.grid_view_rounded,
  ),

  /// Modo infinito do "Quem é esse Pokémon?". Não aparece como card próprio:
  /// é escolhido dentro do card do whosThat, mas tem ranking separado.
  whosThatEndless(
    'Quem é esse? Infinito',
    'Um level só, Pokémon sem fim e 3 vidas.',
    Icons.all_inclusive,
    listed: false,
  );

  const GameId(this.title, this.description, this.icon, {this.listed = true});

  final String title;
  final String description;
  final IconData icon;

  /// Aparece como card na tela de jogos.
  final bool listed;
}
