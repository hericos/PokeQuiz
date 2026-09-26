import 'package:flutter/material.dart';

import '../widgets/poke_background.dart';
import 'games_screen.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';

/// Navegação principal: Jogos, Ranking e Perfil.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  /// Muda a cada troca de aba para recarregar recordes e ranking.
  int _refresh = 0;

  static const _titles = ['PokeQuiz', 'Ranking', 'Meu perfil'];

  @override
  Widget build(BuildContext context) {
    return PokeScaffold(
      appBar: AppBar(title: Text(_titles[_tab])),
      body: switch (_tab) {
        0 => GamesScreen(key: ValueKey('games$_refresh')),
        1 => RankingScreen(key: ValueKey('ranking$_refresh')),
        _ => const ProfileScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          _refresh++;
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'Jogos',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
