import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'quiz_screen.dart';
import 'ranking_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result});

  final QuizResult result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final Future<({int position, int players, int total})> _ranking;

  @override
  void initState() {
    super.initState();
    _ranking = _saveAndRank();
  }

  Future<({int position, int players, int total})> _saveAndRank() async {
    final db = context.read<DatabaseService>();
    final user = context.read<AuthService>().currentUser!;
    await db.insertScore(user.id, widget.result);
    final ranking = await db.levelRanking(widget.result.level.number, limit: 1000);
    final best = await db.bestScoresFor(user.id);
    final position = ranking.indexWhere((e) => e.userId == user.id) + 1;
    return (
      position: position,
      players: ranking.length,
      total: best.values.fold(0, (a, b) => a + b),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final level = r.level;
    final hasNext = level.number < QuizLevel.values.length;
    final textTheme = Theme.of(context).textTheme;
    final stars = r.correct >= 9 ? 3 : r.correct >= 6 ? 2 : r.correct >= 3 ? 1 : 0;

    return Scaffold(
      appBar: AppBar(title: Text('Resultado • ${level.label}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(i < stars ? Icons.star : Icons.star_border,
                      size: 56, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            Text('${r.correct} de ${r.total} acertos',
                textAlign: TextAlign.center, style: textTheme.headlineMedium),
            Text('${r.score} pontos',
                textAlign: TextAlign.center,
                style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            Text('Tempo: ${(r.elapsed.inMilliseconds / 1000).toStringAsFixed(1)}s',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FutureBuilder(
              future: _ranking,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snap.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, size: 40, color: Colors.amber),
                        Text('${data.position}º lugar no ranking do ${level.label}',
                            style: textTheme.titleMedium),
                        Text('entre ${data.players} treinador(es)'),
                        const Divider(height: 24),
                        Text('Pontuação geral: ${data.total} pts'),
                        Text(trainerTitle(data.total),
                            style: textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            if (hasNext)
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: Text('Ir para o ${QuizLevel.fromNumber(level.number + 1).label}'),
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) =>
                        QuizScreen(level: QuizLevel.fromNumber(level.number + 1)))),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.replay),
              label: const Text('Jogar de novo'),
              onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => QuizScreen(level: level))),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.leaderboard),
              label: const Text('Ver ranking'),
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => RankingScreen(initialLevel: level.number))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }
}
