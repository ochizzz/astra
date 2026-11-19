import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Диск Луны с освещённой частью и мягким сиянием.
/// [illumination] — доля освещённости 0..1, [waxing] — растущая (свет справа).
class MoonDisc extends StatelessWidget {
  const MoonDisc({super.key, required this.illumination, required this.waxing, this.size = 64});

  final double illumination;
  final bool waxing;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MoonPainter(illumination: illumination, waxing: waxing),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({required this.illumination, required this.waxing});

  final double illumination;
  final bool waxing;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.82;

    // Сияние
    canvas.drawCircle(
      c,
      r * 1.25,
      Paint()
        ..color = AppColors.moonPink.withValues(alpha: 0.10 + 0.18 * illumination)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
    );

    // Тёмная часть диска («пепельный свет»)
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2B2445));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = AppColors.moonPink.withValues(alpha: 0.25),
    );

    // Освещённая часть: полукруг + полуэллипс терминатора.
    final k = illumination.clamp(0.0, 1.0);
    final rx = r * (1 - 2 * k).abs();
    final top = c.translate(0, -r);
    final bottom = c.translate(0, r);
    final lit = Path()
      ..moveTo(top.dx, top.dy)
      ..arcToPoint(bottom, radius: Radius.circular(r))
      ..arcToPoint(top, radius: Radius.elliptical(math.max(rx, 0.01), r), clockwise: k > 0.5)
      ..close();

    canvas.save();
    if (!waxing) {
      // Убывающая Луна — свет слева (для северного полушария).
      canvas.translate(c.dx * 2, 0);
      canvas.scale(-1, 1);
    }
    final shader = const RadialGradient(
      center: Alignment(-0.3, -0.35),
      radius: 1.1,
      colors: [Color(0xFFFFF8F0), AppColors.moonPink, Color(0xFFCDB6D8)],
      stops: [0, 0.6, 1],
    ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawPath(lit, Paint()..shader = shader);
    canvas.restore();

    // Пара «кратеров» для фактуры
    final crater = Paint()..color = const Color(0x14000000);
    canvas.drawCircle(c.translate(r * 0.25, -r * 0.2), r * 0.16, crater);
    canvas.drawCircle(c.translate(-r * 0.3, r * 0.3), r * 0.11, crater);
    canvas.drawCircle(c.translate(r * 0.1, r * 0.45), r * 0.07, crater);
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.illumination != illumination || old.waxing != waxing;
}
