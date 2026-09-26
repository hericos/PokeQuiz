import 'package:flutter/material.dart';

import '../models/dex.dart';
import '../models/game.dart';
import '../services/odd_one_out_engine.dart';
import '../widgets/confirm_exit.dart';
import '../widgets/poke_background.dart';
import '../widgets/pokemon_image.dart';
import 'game_result_screen.dart';

/// "Qual é o diferente?": 4 Pokémon em 2x2, um deles não combina com os
/// outros pelo critério mostrado. A pontuação é a sequência de acertos.
class OddOneOutScreen extends StatefulWidget {
  const OddOneOutScreen({super.key});

  @override
  State<OddOneOutScreen> createState() => _OddOneOutScreenState();
}

class _OddOneOutScreenState extends State<OddOneOutScreen> {
  OddOneOutEngine? _engine;
  OddRound? _round;
  OddRound? _upcoming;
  int _streak = 0;

  /// Índice tocado na rodada atual (null = ainda escolhendo).
  int? _picked;

  @override
  void initState() {
    super.initState();
    Dex.load().then((dex) {
      if (!mounted) return;
      _engine = OddOneOutEngine(dex);
      setState(() => _round = _engine!.next());
      _prepareNext();
    });
  }

  /// Sorteia a próxima rodada já e pré-carrega as imagens dela.
  void _prepareNext() {
    final next = _engine!.next();
    _upcoming = next;
    for (final p in next.pokemon) {
      precacheImage(
        pokemonImageProvider(next.showsShiny ? p.shinyImageUrl : p.imageUrl),
        context,
      ).catchError((_) {});
    }
  }

  void _pick(int index) {
    if (_picked != null) return;
    setState(() {
      _picked = index;
      if (index == _round!.oddIndex) _streak++;
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          game: GameId.oddOneOut,
          score: _streak,
          headline: '$_streak acerto(s) seguido(s)',
          details: [_round!.explanation],
          playAgain: (_) => const OddOneOutScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final answered = _picked != null;
    final correct = answered && _picked == round!.oddIndex;

    return ConfirmExit(
      enabled: !(answered && !correct),
      child: PokeScaffold(
        appBar: AppBar(title: const Text('Qual é o diferente?')),
        body: round == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
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
                        Chip(
                          avatar: const Icon(Icons.rule, size: 18),
                          label: Text(round.criterion.label),
                          backgroundColor: Colors.amber.shade200,
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      answered
                          ? (correct ? 'Acertou!' : 'Errou!')
                          : 'Toque no Pokémon que é diferente',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (round.showsShiny && !answered)
                      const Text(
                        '(formas shiny)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: answered ? 0.78 : 0.95,
                      children: [for (var i = 0; i < 4; i++) _tile(round, i)],
                    ),
                    if (answered) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            round.explanation,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

  Widget _tile(OddRound round, int i) {
    final answered = _picked != null;
    final isOdd = i == round.oddIndex;
    final border = !answered
        ? BorderSide.none
        : isOdd
        ? const BorderSide(color: Colors.green, width: 4)
        : i == _picked
        ? const BorderSide(color: Colors.red, width: 4)
        : BorderSide.none;
    final p = round.pokemon[i];
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: border,
      ),
      child: InkWell(
        onTap: answered ? null : () => _pick(i),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) => PokemonImage(
                    key: ValueKey('${p.id}-${round.showsShiny}'),
                    pokemon: p,
                    shiny: round.showsShiny,
                    size: c.biggest.shortestSide,
                  ),
                ),
              ),
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (answered)
                Text(
                  round.labels[i],
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOdd ? Colors.green.shade800 : Colors.black54,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
