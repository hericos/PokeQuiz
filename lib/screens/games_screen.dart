import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../models/quiz.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/user_avatar.dart';
import 'hangman_screen.dart';
import 'whos_that_screen.dart';

/// Tela de cada jogo do catálogo.
Widget buildGameScreen(GameId game) => switch (game) {
  GameId.whosThat => const WhosThatScreen(),
  GameId.hangman => const HangmanScreen(),
};

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  late Future<Map<GameId, int>> _best;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final user = context.read<AuthService>().currentUser!;
    _best = context.read<DatabaseService>().bestScoresFor(user.id);
  }

  Future<void> _play(GameId game) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => buildGameScreen(game)));
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;
    return FutureBuilder<Map<GameId, int>>(
      future: _best,
      builder: (context, snap) {
        final best = snap.data ?? const {};
        final total = best.values.fold(0, (a, b) => a + b);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                UserAvatar(name: user.name, photo: user.photo, radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${user.name.split(' ').first}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${trainerTitle(total)} • $total pts',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (final game in GameId.values)
              _GameCard(game: game, best: best[game], onTap: () => _play(game)),
            const _ComingSoonCard(),
          ],
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.best,
    required this.onTap,
  });

  final GameId game;
  final int? best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                child: Icon(game.icon, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      best == null ? 'Ainda não jogado' : 'Recorde: $best pts',
                      style: TextStyle(
                        color: scheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill, color: scheme.primary, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.6),
      child: const ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.hourglass_top, size: 32),
        title: Text('Novos jogos em breve'),
        subtitle: Text('Fique de olho nas próximas atualizações!'),
      ),
    );
  }
}
