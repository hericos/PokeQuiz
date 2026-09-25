import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../models/quiz.dart';
import '../services/quiz_engine.dart';
import '../widgets/pokemon_image.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.level});

  final QuizLevel level;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizQuestion> _questions;
  final _stopwatch = Stopwatch();
  final _typed = TextEditingController();
  int _index = 0;
  int _correct = 0;

  /// Resposta dada na pergunta atual (null = ainda respondendo).
  bool? _lastWasCorrect;
  Pokemon? _picked;

  QuizLevel get level => widget.level;
  QuizQuestion get _q => _questions[_index];

  @override
  void initState() {
    super.initState();
    _questions = QuizEngine().buildRound(level);
    _stopwatch.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pré-carrega as imagens da rodada para não travar entre perguntas.
    for (final q in _questions) {
      precacheImage(CachedNetworkImageProvider(q.answer.imageUrl), context)
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _answer({Pokemon? option, String? typed}) {
    if (_lastWasCorrect != null) return;
    final ok = option != null
        ? option == _q.answer
        : QuizEngine.isCorrectTypedAnswer(_q.answer, typed ?? '');
    _stopwatch.stop();
    setState(() {
      _picked = option;
      _lastWasCorrect = ok;
      if (ok) _correct++;
    });
  }

  void _next() {
    if (_index == _questions.length - 1) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: QuizResult(
            level: level,
            correct: _correct,
            total: _questions.length,
            elapsed: _stopwatch.elapsed,
          ),
        ),
      ));
      return;
    }
    setState(() {
      _index++;
      _lastWasCorrect = null;
      _picked = null;
      _typed.clear();
    });
    _stopwatch.start();
  }

  Future<bool> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do jogo?'),
        content: const Text('Seu progresso nesta rodada será perdido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final answered = _lastWasCorrect != null;
    final mode = answered
        ? PokemonImageMode.full
        : switch (level) {
            QuizLevel.full => PokemonImageMode.full,
            QuizLevel.partial => PokemonImageMode.partial,
            _ => PokemonImageMode.shadow,
          };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmExit()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${level.label} • ${level.title}'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: (_index + (answered ? 1 : 0)) / _questions.length,
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
                  Text('Pokémon ${_index + 1} de ${_questions.length}',
                      style: Theme.of(context).textTheme.titleMedium),
                  Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.green),
                    label: Text('$_correct acertos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Quem é esse Pokémon?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: PokemonImage(
                    key: ValueKey('${_q.answer.id}-$mode'),
                    pokemon: _q.answer,
                    mode: mode,
                    cropX: _q.cropX,
                    cropY: _q.cropY,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (answered) _feedback() else if (level.isTyped) _typedInput() else ..._options(),
              if (answered) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _next,
                  child: Text(_index == _questions.length - 1 ? 'Ver resultado' : 'Próximo'),
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
            padding: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _answer(typed: _typed.text),
            child: const Text('Responder'),
          ),
        ],
      );

  Widget _feedback() {
    final ok = _lastWasCorrect!;
    final color = ok ? Colors.green : Theme.of(context).colorScheme.error;
    final yourAnswer = _picked?.name ?? _typed.text.trim();
    return Card(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(ok ? Icons.check_circle : Icons.cancel, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              ok ? 'É o ${_q.answer.name}!' : 'Era o ${_q.answer.name}!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
            ),
            Text(_q.answer.dexNumber),
            if (!ok && yourAnswer.isNotEmpty) Text('Sua resposta: $yourAnswer'),
          ],
        ),
      ),
    );
  }
}
