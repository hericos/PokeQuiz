import 'package:flutter/material.dart';

/// Forca desenhada com o Banette: a cada erro aparece uma parte.
/// 1 cabeça, 2 corpo, 3 braços, 4 pernas, 5 rosto (olhos e zíper).
class BanetteGallows extends StatelessWidget {
  const BanetteGallows({super.key, required this.errors, this.height = 220});

  final int errors;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AspectRatio(
        aspectRatio: 200 / 220,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: errors.toDouble()),
          duration: const Duration(milliseconds: 350),
          builder: (_, value, _) =>
              CustomPaint(painter: _GallowsPainter(value)),
        ),
      ),
    );
  }
}

class _GallowsPainter extends CustomPainter {
  _GallowsPainter(this.progress);

  /// Número de erros (animado; a parte N aparece de N-1 a N).
  final double progress;

  static const body = Color(0xFF4E4B63);
  static const bodyDark = Color(0xFF34324A);
  static const zipper = Color(0xFFE8C547);
  static const eye = Color(0xFFE53935);

  double _alpha(int part) => (progress - (part - 1)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    // Desenha num espaço lógico de 200x220.
    canvas.scale(size.width / 200, size.height / 220);

    final wood = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(20, 212), const Offset(120, 212), wood);
    canvas.drawLine(const Offset(45, 212), const Offset(45, 12), wood);
    canvas.drawLine(const Offset(45, 12), const Offset(140, 12), wood);
    canvas.drawLine(
      const Offset(45, 45),
      const Offset(75, 12),
      wood..strokeWidth = 5,
    );
    final rope = Paint()
      ..color = const Color(0xFFD7B98E)
      ..strokeWidth = 3;
    canvas.drawLine(const Offset(140, 12), const Offset(140, 40), rope);

    Paint fill(Color c, int part) =>
        Paint()..color = c.withValues(alpha: c.a * _alpha(part));

    // 3 — braços (atrás do corpo)
    if (_alpha(3) > 0) {
      final arm = fill(body, 3)
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(128, 108), const Offset(104, 136), arm);
      canvas.drawLine(const Offset(152, 108), const Offset(176, 136), arm);
    }
    // 4 — pernas
    if (_alpha(4) > 0) {
      final leg = fill(body, 4)
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(131, 150), const Offset(126, 180), leg);
      canvas.drawLine(const Offset(149, 150), const Offset(154, 180), leg);
    }
    // 2 — corpo
    if (_alpha(2) > 0) {
      final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(120, 94, 40, 60),
        const Radius.circular(16),
      );
      canvas.drawRRect(rect, fill(body, 2));
      canvas.drawRRect(
        rect,
        fill(bodyDark, 2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // 1 — cabeça com a "antena" característica
    if (_alpha(1) > 0) {
      final head = fill(body, 1);
      final antenna = Path()
        ..moveTo(128, 50)
        ..quadraticBezierTo(122, 22, 150, 14)
        ..quadraticBezierTo(134, 30, 148, 50)
        ..close();
      canvas.drawPath(antenna, head);
      canvas.drawOval(const Rect.fromLTWH(114, 40, 52, 58), head);
      canvas.drawOval(
        const Rect.fromLTWH(114, 40, 52, 58),
        fill(bodyDark, 1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // 5 — rosto: olhos vermelhos e boca de zíper
    if (_alpha(5) > 0) {
      canvas.drawOval(const Rect.fromLTWH(124, 56, 11, 14), fill(eye, 5));
      canvas.drawOval(const Rect.fromLTWH(145, 56, 11, 14), fill(eye, 5));
      final z = fill(zipper, 5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(124, 82), const Offset(156, 82), z);
      for (var x = 127.0; x <= 154; x += 5) {
        canvas.drawLine(Offset(x, 78), Offset(x, 86), z..strokeWidth = 2);
      }
      canvas.drawCircle(const Offset(158, 82), 3.5, z);
    }
  }

  @override
  bool shouldRepaint(_GallowsPainter old) => old.progress != progress;
}
