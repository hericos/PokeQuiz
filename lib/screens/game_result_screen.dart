import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../models/quiz.dart';
import '../services/auth_service.dart';
import '../services/score_service.dart';
import '../widgets/poke_background.dart';

/// Tela de fim de partida comum a todos os jogos: salva a pontuação e mostra
/// a posição no ranking do jogo.
class GameResultScreen extends StatefulWidget {
  const GameResultScreen({
    super.key,
    required this.game,
    required this.score,
    required this.headline,
    this.details = const [],
    this.header,
    required this.playAgain,
  });

  final GameId game;
  final int score;

  /// Resumo curto, também salvo no ranking (ex.: "32/40 acertos").
  final String headline;
  final List<String> details;
  final Widget? header;
  final WidgetBuilder playAgain;

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  late final Future<
    ({int position, int players, bool record, int best, int total})
  >
  _ranking;

  @override
  void initState() {
    super.initState();
    _ranking = _saveAndRank();
  }

  Future<({int position, int players, bool record, int best, int total})>
  _saveAndRank() async {
    final scores = context.read<ScoreService>();
    final user = context.read<AuthService>().currentUser!;
    final saved = await scores.submit(
      uid: user.id,
      name: user.name,
      thumb: user.photoThumb,
      game: widget.game,
      score: widget.score,
      detail: widget.headline,
    );
    final pos = await scores.positionOf(widget.game, saved.best);
    return (
      position: pos.position,
      players: pos.players,
      record: saved.isRecord,
      best: saved.best,
      total: saved.total,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PokeScaffold(
      appBar: AppBar(
        title: Text(widget.game.title),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ?widget.header,
                    Text(widget.headline, style: textTheme.titleLarge),
                    Text(
                      '${widget.score} pontos',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    for (final d in widget.details)
                      Text(d, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder(
              future: _ranking,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                final r = snap.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 40,
                          color: Colors.amber,
                        ),
                        if (r.record)
                          Text(
                            'Novo recorde!',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text('Seu recorde: ${r.best} pts'),
                        Text(
                          '${r.position}º lugar entre ${r.players} treinador(es)',
                          style: textTheme.titleMedium,
                        ),
                        const Divider(height: 24),
                        Text('Pontuação geral: ${r.total} pts'),
                        Text(
                          trainerTitle(r.total),
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.replay),
              label: const Text('Jogar de novo'),
              onPressed: () => Navigator.of(
                context,
              ).pushReplacement(MaterialPageRoute(builder: widget.playAgain)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.sports_esports),
              label: const Text('Voltar aos jogos'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
