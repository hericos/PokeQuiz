import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/pokemon.dart';
import '../models/quiz.dart';
import '../services/quiz_engine.dart';
import '../widgets/confirm_exit.dart';
import '../widgets/poke_background.dart';
import '../widgets/pokemon_image.dart';
import 'game_result_screen.dart';

/// "Quem é esse Pokémon?": 4 levels seguidos, 10 Pokémon cada. Respondeu 10,
/// sobe de level.
class WhosThatScreen extends StatefulWidget {
  const WhosThatScreen({super.key});

  @override
  State<WhosThatScreen> createState() => _WhosThatScreenState();
}

class _WhosThatScreenState extends State<WhosThatScreen> {
  static const perLevel = QuizEngine.questionsPerLevel;

  late final List<QuizQuestion> _questions;
  final _answerTime = Stopwatch();
  final _typed = TextEditingController();
  final Map<QuizLevel, int> _hitsPerLevel = {};
  int _index = 0;
  int _score = 0;
  int _lastPoints = 0;

  /// Resultado da pergunta atual (null = ainda respondendo).
  bool? _lastWasCorrect;
  Pokemon? _picked;

  QuizQuestion get _q => _questions[_index];
  QuizLevel get _level => _q.level;
  int get _hits => _hitsPerLevel.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _questions = QuizEngine().buildGame();
    _answerTime.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precache(0);
  }

  /// Pré-carrega as imagens do level que começa em [from].
  void _precache(int from) {
    for (final q in _questions.skip(from).take(perLevel)) {
      precacheImage(
        CachedNetworkImageProvider(q.answer.imageUrl),
        context,
      ).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _answer({Pokemon? option, String? typed}) {
    if (_lastWasCorrect != null) return;
    _answerTime.stop();
    final ok = option != null
        ? option == _q.answer
        : QuizEngine.isCorrectTypedAnswer(_q.answer, typed ?? '');
    setState(() {
      _picked = option;
      _lastWasCorrect = ok;
      _lastPoints = ok ? _level.pointsFor(_answerTime.elapsed) : 0;
      _score += _lastPoints;
      if (ok) _hitsPerLevel.update(_level, (v) => v + 1, ifAbsent: () => 1);
    });
  }

  Future<void> _next() async {
    if (_index == _questions.length - 1) {
      _finish();
      return;
    }
    final levelUp = (_index + 1) % perLevel == 0;
    setState(() {
      _index++;
      _lastWasCorrect = null;
      _picked = null;
      _typed.clear();
    });
    if (levelUp) {
      _precache(_index + perLevel);
      await _showLevelUp();
    }
    _answerTime
      ..reset()
      ..start();
  }

  Future<void> _showLevelUp() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.arrow_circle_up, size: 48, color: Colors.green),
      title: Text('${_level.label}!'),
      content: Text(
        '${_level.title}\n\nVocê acertou ${_hitsPerLevel[QuizLevel.values[_level.number - 2]] ?? 0} '
        'de $perLevel no level anterior.',
        textAlign: TextAlign.center,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Bora!'),
        ),
      ],
    ),
  );

  void _finish() {
    final total = _questions.length;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          game: GameId.whosThat,
          score: _score,
          headline: '$_hits/$total acertos',
          details: [
            for (final l in QuizLevel.values)
              '${l.label} (${l.title}): ${_hitsPerLevel[l] ?? 0}/$perLevel',
          ],
          playAgain: (_) => const WhosThatScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answered = _lastWasCorrect != null;
    final mode = answered
        ? PokemonImageMode.full
        : switch (_level) {
            QuizLevel.full => PokemonImageMode.full,
            QuizLevel.partial => PokemonImageMode.partial,
            _ => PokemonImageMode.shadow,
          };
    final inLevel = _index % perLevel;

    return ConfirmExit(
      child: PokeScaffold(
        appBar: AppBar(
          title: Text('${_level.label} • ${_level.title}'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              color: Colors.amber,
              backgroundColor: Colors.white24,
              value: (inLevel + (answered ? 1 : 0)) / perLevel,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Pill('${inLevel + 1}/$perLevel', Icons.catching_pokemon),
                  _Pill('$_score pts', Icons.star),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        'Quem é esse Pokémon?',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: PokemonImage(
                          key: ValueKey('${_q.answer.id}-$mode'),
                          pokemon: _q.answer,
                          mode: mode,
                          cropX: _q.cropX,
                          cropY: _q.cropY,
                          size: 240,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (answered)
                _feedback()
              else if (_level.isTyped)
                _typedInput()
              else
                ..._options(),
              if (answered) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _next,
                  child: Text(
                    _index == _questions.length - 1
                        ? 'Ver resultado'
                        : inLevel == perLevel - 1
                        ? 'Próximo level'
                        : 'Próximo',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _options() => [
    for (final option in _q.options)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OutlinedButton(
          onPressed: () => _answer(option: option),
          child: Text(option.name, style: const TextStyle(fontSize: 18)),
        ),
      ),
  ];

  Widget _typedInput() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _typed,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Nome do Pokémon'),
        onSubmitted: (v) => _answer(typed: v),
      ),
      const SizedBox(height: 10),
      FilledButton(
        onPressed: () => _answer(typed: _typed.text),
        child: const Text('Responder'),
      ),
    ],
  );

  Widget _feedback() {
    final ok = _lastWasCorrect!;
    final color = ok
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;
    final yourAnswer = _picked?.name ?? _typed.text.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.cancel,
              color: color,
              size: 40,
            ),
            Text(
              ok
                  ? 'É o ${_q.answer.name}! +$_lastPoints'
                  : 'Era o ${_q.answer.name}!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: color),
            ),
            Text('${_q.answer.dexNumber} • ${_q.answer.region.label}'),
            if (!ok && yourAnswer.isNotEmpty) Text('Sua resposta: $yourAnswer'),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: Colors.white,
    side: BorderSide.none,
  );
}
