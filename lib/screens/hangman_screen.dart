import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/pokemon.dart';
import '../services/hangman_engine.dart';
import '../widgets/banette_gallows.dart';
import '../widgets/confirm_exit.dart';
import '../widgets/poke_background.dart';
import '../widgets/pokemon_image.dart';
import 'game_result_screen.dart';

/// Forca: descubra o Pokémon letra a letra. Cada acerto vale pontos e sorteia
/// o próximo; a partida acaba quando o Banette fica completo (5 erros).
class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final _random = Random();
  final _used = <Pokemon>{};
  late HangmanRound _round;
  int _score = 0;
  int _solved = 0;

  @override
  void initState() {
    super.initState();
    _round = _newRound();
  }

  HangmanRound _newRound() {
    Pokemon p;
    do {
      p = Pokemon.all[_random.nextInt(Pokemon.all.length)];
    } while (_used.contains(p));
    _used.add(p);
    return HangmanRound(p);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheCurrent();
  }

  void _precacheCurrent() {
    precacheImage(
      pokemonImageProvider(_round.pokemon.imageUrl),
      context,
    ).catchError((_) {});
  }

  void _guess(String letter) {
    setState(() {
      _round.guess(letter);
      if (_round.isWon) {
        _score += _round.points;
        _solved++;
      }
    });
  }

  void _nextRound() {
    setState(() => _round = _newRound());
    _precacheCurrent();
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          game: GameId.hangman,
          score: _score,
          headline: '$_solved Pokémon descoberto(s)',
          details: [
            'O último era ${_round.pokemon.name} (${_round.pokemon.dexNumber}).',
          ],
          header: PokemonImage(pokemon: _round.pokemon, size: 140),
          playAgain: (_) => const HangmanScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _round;
    return ConfirmExit(
      enabled: !r.isLost,
      child: PokeScaffold(
        appBar: AppBar(title: const Text('Forca')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: Text('${r.livesLeft} chances'),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                  ),
                  Chip(
                    avatar: const Icon(Icons.star, size: 18),
                    label: Text('$_score pts • $_solved ✓'),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          BanetteGallows(errors: r.errors, height: 180),
                          if (r.isOver)
                            PokemonImage(pokemon: r.pokemon, size: 120),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Word(round: r),
                      const SizedBox(height: 8),
                      Text(
                        'Dica: Pokémon da região de ${r.pokemon.region.label}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (r.isOver) _endOfRound(r) else _keyboard(r),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keyboard(HangmanRound r) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final l in _alphabet.split(''))
        SizedBox(
          width: 42,
          height: 46,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              disabledBackgroundColor: !r.guessed.contains(l)
                  ? Colors.white
                  : r.lettersToFind.contains(l)
                  ? Colors.green.shade400
                  : Colors.grey.shade700,
              disabledForegroundColor: Colors.white,
            ),
            onPressed: r.guessed.contains(l) ? null : () => _guess(l),
            child: Text(
              l,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
    ],
  );

  Widget _endOfRound(HangmanRound r) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            r.isWon
                ? 'Isso! É o ${r.pokemon.name}! +${r.points} pts'
                : 'O Banette te pegou! Era o ${r.pokemon.name}.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: r.isWon ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 12),
          if (r.isWon)
            FilledButton(
              onPressed: _nextRound,
              child: const Text('Próximo Pokémon'),
            )
          else
            FilledButton(
              onPressed: _finish,
              child: const Text('Ver resultado'),
            ),
        ],
      ),
    ),
  );
}

/// Palavra com um quadradinho por letra; espaços viram separação.
class _Word extends StatelessWidget {
  const _Word({required this.round});

  final HangmanRound round;

  @override
  Widget build(BuildContext context) {
    final name = round.pokemon.name.split('');
    final masked = round.masked.split('');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 8,
      children: [
        for (var i = 0; i < name.length; i++)
          if (name[i] == ' ')
            const SizedBox(width: 14)
          else
            _letter(name[i], masked[i]),
      ],
    );
  }

  Widget _letter(String char, String masked) {
    final letter = HangmanRound.letterOf(char);
    return _LetterBox(
      char: masked == '_' ? '' : char.toUpperCase(),
      isLetter: letter != null,
      // Na derrota, as letras que faltaram aparecem em vermelho.
      missed: round.isLost && letter != null && !round.guessed.contains(letter),
    );
  }
}

class _LetterBox extends StatelessWidget {
  const _LetterBox({
    required this.char,
    required this.isLetter,
    required this.missed,
  });

  final String char;
  final bool isLetter;
  final bool missed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isLetter ? 26 : 14,
      height: 34,
      alignment: Alignment.center,
      decoration: isLetter
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 3, color: Colors.black87),
              ),
            )
          : null,
      child: Text(
        char,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: missed ? Colors.red : Colors.black87,
        ),
      ),
    );
  }
}
