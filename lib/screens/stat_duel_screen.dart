import 'package:flutter/material.dart';

import '../models/dex.dart';
import '../models/game.dart';
import '../services/stat_duel_engine.dart';
import '../widgets/confirm_exit.dart';
import '../widgets/poke_background.dart';
import '../widgets/pokemon_image.dart';
import 'game_result_screen.dart';

/// "Quem tem mais?": dois Pokémon lado a lado; toque no que tem o maior
/// valor do status sorteado. Pontuação = acertos seguidos.
class StatDuelScreen extends StatefulWidget {
  const StatDuelScreen({super.key});

  @override
  State<StatDuelScreen> createState() => _StatDuelScreenState();
}

class _StatDuelScreenState extends State<StatDuelScreen> {
  StatDuelEngine? _engine;
  StatDuelRound? _round;
  StatDuelRound? _upcoming;
  int _streak = 0;

  /// Lado tocado na rodada atual (null = ainda escolhendo).
  int? _picked;

  @override
  void initState() {
    super.initState();
    Dex.load().then((dex) {
      if (!mounted) return;
      _engine = StatDuelEngine(dex);
      setState(() => _round = _engine!.next());
      _prepareNext();
    });
  }

  /// Sorteia a próxima rodada já e pré-carrega as imagens dela.
  void _prepareNext() {
    final next = _engine!.next();
    _upcoming = next;
    for (final p in next.pair) {
      precacheImage(
        pokemonImageProvider(p.imageUrl),
        context,
      ).catchError((_) {});
    }
  }

  void _pick(int side) {
    if (_picked != null) return;
    setState(() {
      _picked = side;
      if (side == _round!.winner) _streak++;
    });
  }

  void _next() {
    setState(() {
      _round = _upcoming;
      _picked = null;
    });
    _prepareNext();
  }

  void _finish() {
    final r = _round!;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          game: GameId.statDuel,
          score: _streak,
          headline: '$_streak acerto(s) seguido(s)',
          details: [
            '${r.stat.label}: ${r.left.name} ${r.leftValue} × '
                '${r.rightValue} ${r.right.name}',
          ],
          playAgain: (_) => const StatDuelScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final answered = _picked != null;
    final correct = answered && _picked == round!.winner;

    return ConfirmExit(
      enabled: !(answered && !correct),
      child: PokeScaffold(
        appBar: AppBar(title: const Text('Quem tem mais?')),
        body: round == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: const Icon(
                          Icons.local_fire_department,
                          color: Colors.deepOrange,
                          size: 18,
                        ),
                        label: Text(
                          'Sequência: $_streak',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      answered
                          ? (correct ? 'Acertou!' : 'Errou!')
                          : 'Quem tem mais',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${round.stat.label}?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _side(round, 0)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Expanded(child: _side(round, 1)),
                      ],
                    ),
                    if (answered) ...[
                      const SizedBox(height: 16),
                      if (correct)
                        FilledButton(
                          onPressed: _next,
                          child: const Text('Próximo'),
                        )
                      else
                        FilledButton(
                          onPressed: _finish,
                          child: const Text('Ver resultado'),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _side(StatDuelRound round, int side) {
    final answered = _picked != null;
    final isWinner = side == round.winner;
    final p = round.pair[side];
    final value = round.values[side];
    final maxValue = round.values.reduce((a, b) => a > b ? a : b);
    final border = !answered
        ? BorderSide.none
        : isWinner
        ? const BorderSide(color: Colors.green, width: 4)
        : side == _picked
        ? const BorderSide(color: Colors.red, width: 4)
        : BorderSide.none;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: border,
      ),
      child: InkWell(
        onTap: answered ? null : () => _pick(side),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (_, c) => PokemonImage(
                  key: ValueKey(p.id),
                  pokemon: p,
                  size: c.maxWidth,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(p.dexNumber, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              if (answered) ...[
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isWinner ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / maxValue,
                    minHeight: 8,
                    color: isWinner ? Colors.green : Colors.grey,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ] else
                const SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
