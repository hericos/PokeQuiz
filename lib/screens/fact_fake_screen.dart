import 'dart:math';

import 'package:flutter/material.dart';

import '../data/ash_facts.dart';
import '../models/game.dart';
import '../models/pokemon.dart';
import '../widgets/answer_countdown.dart';
import '../widgets/confirm_exit.dart';
import '../widgets/poke_background.dart';
import '../widgets/pokemon_image.dart';
import 'game_result_screen.dart';

/// "Fato ou Fake: Ash": afirmações sobre a história do Ash; 3 vidas,
/// 10 segundos por resposta, pontuação = total de acertos.
class FactFakeScreen extends StatefulWidget {
  const FactFakeScreen({super.key});

  @override
  State<FactFakeScreen> createState() => _FactFakeScreenState();
}

class _FactFakeScreenState extends State<FactFakeScreen> with AnswerCountdown {
  static const maxLives = 3;

  late final List<(String, bool, String)> _facts = [...ashFacts]
    ..shuffle(Random());
  int _index = 0;
  int _hits = 0;
  int _lives = maxLives;

  /// Resposta dada (null = ainda respondendo; timeout = sem resposta).
  bool? _answer;
  bool _answered = false;
  bool _timedOut = false;

  (String, bool, String) get _fact => _facts[_index];
  bool get _correct => _answered && !_timedOut && _answer == _fact.$2;
  bool get _gameOver => _lives == 0 || (_answered && _isLast);
  bool get _isLast => _index == _facts.length - 1;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void _respond(bool? answer) {
    if (_answered) return;
    stopCountdown();
    setState(() {
      _answered = true;
      _answer = answer;
      _timedOut = answer == null;
      if (_correct) {
        _hits++;
      } else {
        _lives--;
      }
    });
  }

  @override
  void onCountdownTimeout() => _respond(null);

  void _next() {
    setState(() {
      _index++;
      _answered = false;
      _answer = null;
      _timedOut = false;
    });
    startCountdown();
  }

  void _finish() {
    stopCountdown();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          game: GameId.factOrFake,
          score: _hits,
          headline: '$_hits acerto(s)',
          details: [
            if (_lives > 0)
              'Você respondeu todas as ${_facts.length} afirmações!',
            '${_index + 1} afirmação(ões) respondida(s)',
          ],
          playAgain: (_) => const FactFakeScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fact = _fact;
    return ConfirmExit(
      enabled: !_gameOver,
      child: PokeScaffold(
        appBar: AppBar(title: const Text('Fato ou Fake: Ash')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < maxLives; i++)
                          Icon(
                            i < _lives ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                            size: 20,
                          ),
                      ],
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                  ),
                  Chip(
                    avatar: const Icon(Icons.check_circle, size: 18),
                    label: Text(
                      '$_hits acertos',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              countdownBar(),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      PokemonImage(pokemon: Pokemon.all[24], size: 110),
                      const SizedBox(height: 8),
                      Text(
                        'Afirmação ${_index + 1} de ${_facts.length}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fact.$1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_answered)
                Row(
                  children: [
                    Expanded(child: _button(true)),
                    const SizedBox(width: 12),
                    Expanded(child: _button(false)),
                  ],
                )
              else ...[
                _feedback(fact),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _gameOver ? _finish : _next,
                  child: Text(
                    _gameOver ? 'Fim de jogo — ver resultado' : 'Próxima',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(bool isFact) => FilledButton.icon(
    style: FilledButton.styleFrom(
      backgroundColor: isFact ? Colors.green.shade600 : Colors.red.shade600,
      minimumSize: const Size.fromHeight(64),
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    onPressed: () => _respond(isFact),
    icon: Icon(isFact ? Icons.check : Icons.close),
    label: Text(isFact ? 'FATO' : 'FAKE'),
  );

  Widget _feedback((String, bool, String) fact) {
    final color = _correct
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _correct
                  ? Icons.check_circle
                  : (_timedOut ? Icons.timer_off : Icons.cancel),
              color: color,
              size: 40,
            ),
            Text(
              _correct
                  ? 'Acertou!'
                  : (_timedOut ? 'Tempo esgotado!' : 'Errou!'),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: color),
            ),
            Text(
              'É ${fact.$2 ? 'FATO' : 'FAKE'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(fact.$3, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
