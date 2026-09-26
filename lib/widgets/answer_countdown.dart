import 'dart:async';

import 'package:flutter/material.dart';

/// Tempo para responder em todos os jogos.
const answerTimeLimit = Duration(seconds: 10);

/// Contagem regressiva de resposta para as telas de jogo. Chame
/// [startCountdown] quando a pergunta aparecer e [stopCountdown] quando o
/// jogador responder; se o tempo acabar, [onCountdownTimeout] é chamado.
mixin AnswerCountdown<T extends StatefulWidget> on State<T> {
  static const _tick = Duration(milliseconds: 100);

  Timer? _ticker;

  /// Tempo contado pelos ticks do timer (pausa junto com o app/aba).
  Duration _elapsed = Duration.zero;

  /// Chamado quando o tempo acaba (conta como erro).
  void onCountdownTimeout();

  bool get countdownRunning => _ticker != null;

  Duration get timeLeft {
    final left = answerTimeLimit - _elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  void startCountdown() {
    stopCountdown();
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      _elapsed += _tick;
      if (_elapsed >= answerTimeLimit) {
        stopCountdown();
        onCountdownTimeout();
      } else {
        setState(() {});
      }
    });
    if (mounted) setState(() {});
  }

  void stopCountdown() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Barra com os segundos restantes; some quando a contagem está parada.
  Widget countdownBar() =>
      CountdownBar(timeLeft: timeLeft, visible: countdownRunning);

  @override
  void dispose() {
    stopCountdown();
    super.dispose();
  }
}

class CountdownBar extends StatelessWidget {
  const CountdownBar({super.key, required this.timeLeft, this.visible = true});

  final Duration timeLeft;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final fraction = timeLeft.inMilliseconds / answerTimeLimit.inMilliseconds;
    final color = fraction > 0.5
        ? Colors.green
        : fraction > 0.25
        ? Colors.amber
        : Colors.red;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 10,
                color: color,
                backgroundColor: Colors.white30,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '${(timeLeft.inMilliseconds / 1000).ceil()}s',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
