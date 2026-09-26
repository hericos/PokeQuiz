import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Fundo rosado com pokébolas mais claras em padrão quadriculado.
class PokeBackground extends StatelessWidget {
  const PokeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _PokeballPatternPainter(),
      isComplex: true,
      child: child,
    );
  }
}

/// Scaffold padrão do app, já com o fundo de pokébolas.
class PokeScaffold extends StatelessWidget {
  const PokeScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: PokeBackground(child: body),
    );
  }
}

class _PokeballPatternPainter extends CustomPainter {
  const _PokeballPatternPainter();

  static const cell = 56.0;
  static const radius = 17.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = pokeBackground);

    final ball = Paint()..color = pokeBackgroundLight;
    final line = Paint()
      ..color = pokeBackground
      ..strokeWidth = 3;

    final cols = (size.width / cell).ceil() + 1;
    final rows = (size.height / cell).ceil() + 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        // Quadriculado: pokébola só nas casas "pretas" do tabuleiro.
        if ((r + c).isOdd) continue;
        final center = Offset(c * cell + cell / 2, r * cell + cell / 2);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-pi / 12);
        canvas.drawCircle(Offset.zero, radius, ball);
        canvas.drawLine(
          const Offset(-radius, 0),
          const Offset(radius, 0),
          line,
        );
        canvas.drawCircle(Offset.zero, radius * 0.36, line);
        canvas.drawCircle(Offset.zero, radius * 0.2, ball);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
