import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/user_avatar.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<int, int>> _best;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final user = context.read<AuthService>().currentUser!;
    _best = context.read<DatabaseService>().bestScoresFor(user.id);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PokeQuiz'),
        actions: [
          IconButton(
            tooltip: 'Ranking',
            icon: const Icon(Icons.leaderboard),
            onPressed: () => _open(const RankingScreen()),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'profile') _open(const ProfileScreen());
              if (v == 'logout') auth.logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Editar perfil')),
              PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<int, int>>(
        future: _best,
        builder: (context, snap) {
          final best = snap.data ?? const {};
          final total = best.values.fold(0, (a, b) => a + b);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: UserAvatar(name: user.name, photo: user.photo, radius: 28),
                  title: Text(user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${trainerTitle(total)} • $total pts'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _open(const ProfileScreen()),
                ),
              ),
              const SizedBox(height: 16),
              Text('Quem é esse Pokémon? — Kanto',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final level in QuizLevel.values)
                _LevelCard(
                  level: level,
                  best: best[level.number],
                  onPlay: () => _open(QuizScreen(level: level)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.best, required this.onPlay});

  final QuizLevel level;
  final int? best;
  final VoidCallback onPlay;

  static const _icons = {
    QuizLevel.full: Icons.image,
    QuizLevel.partial: Icons.crop,
    QuizLevel.shadowChoice: Icons.contrast,
    QuizLevel.shadowTyped: Icons.keyboard,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Icon(_icons[level]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${level.label} • ${level.title}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(level.description),
                    const SizedBox(height: 4),
                    Text(
                      best == null ? 'Ainda não jogado' : 'Recorde: $best pts',
                      style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow),
            ],
          ),
        ),
      ),
    );
  }
}
