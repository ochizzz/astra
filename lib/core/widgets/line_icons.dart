import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Набор тонких линейных иконок «Астры». Рисуются кодом — чётко на любом
/// экране и легко перекрашиваются (золото / приглушённый).
enum AstraIcon { today, signs, tests, diary, profile, moon, share, sparkle }

class LineIcon extends StatelessWidget {
  const LineIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color = AppColors.gold,
    this.strokeWidth = 1.3,
  });

  final AstraIcon icon;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LineIconPainter(icon, color, strokeWidth)),
    );
  }
}

class _LineIconPainter extends CustomPainter {
  _LineIconPainter(this.icon, this.color, this.strokeWidth);

  final AstraIcon icon;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.scale(s / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    switch (icon) {
      case AstraIcon.today:
        // Солнце: круг и восемь лучей
        canvas.drawCircle(const Offset(12, 12), 4.2, p);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final long = i.isEven;
          final from = Offset(12 + math.cos(a) * 6.6, 12 + math.sin(a) * 6.6);
          final to = Offset(
            12 + math.cos(a) * (long ? 10 : 8.6),
            12 + math.sin(a) * (long ? 10 : 8.6),
          );
          canvas.drawLine(from, to, p);
        }
      case AstraIcon.signs:
        // Мини-созвездие
        const pts = [Offset(4, 17), Offset(9, 9), Offset(15, 12), Offset(20, 5), Offset(17, 19)];
        canvas.drawPath(
          Path()
            ..moveTo(pts[0].dx, pts[0].dy)
            ..lineTo(pts[1].dx, pts[1].dy)
            ..lineTo(pts[2].dx, pts[2].dy)
            ..lineTo(pts[3].dx, pts[3].dy)
            ..moveTo(pts[2].dx, pts[2].dy)
            ..lineTo(pts[4].dx, pts[4].dy),
          p..strokeWidth = strokeWidth * 0.8,
        );
        for (final pt in pts) {
          canvas.drawCircle(pt, 1.6, fill);
        }
      case AstraIcon.tests:
        // Две карты веером со звездой
        canvas.save();
        canvas.translate(12, 13);
        canvas.rotate(-0.25);
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -8, 10, 15), const Radius.circular(2)),
          p,
        );
        canvas.restore();
        canvas.save();
        canvas.translate(12, 13);
        canvas.rotate(0.2);
        final r = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-2, -9, 10, 15),
          const Radius.circular(2),
        );
        canvas.drawRRect(r, Paint()..color = AppColors.night.withValues(alpha: 0.9));
        canvas.drawRRect(r, p);
        _star(canvas, const Offset(3, -1.5), 2.6, fill);
        canvas.restore();
      case AstraIcon.diary:
        // Книга с полумесяцем
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(5, 3, 14, 18), const Radius.circular(2)),
          p,
        );
        canvas.drawLine(const Offset(8, 3), const Offset(8, 21), p);
        _crescent(canvas, const Offset(13.8, 11), 3.4, p);
      case AstraIcon.profile:
        // Силуэт в круге-орбите
        canvas.drawCircle(const Offset(12, 9), 3.4, p);
        canvas.drawPath(
          Path()
            ..moveTo(5.5, 20)
            ..quadraticBezierTo(6.5, 14, 12, 14)
            ..quadraticBezierTo(17.5, 14, 18.5, 20),
          p,
        );
        canvas.drawCircle(const Offset(19.5, 5), 1.3, fill);
      case AstraIcon.moon:
        _crescent(canvas, const Offset(12, 12), 8, p);
      case AstraIcon.share:
        canvas.drawLine(const Offset(12, 3.5), const Offset(12, 15), p);
        canvas.drawPath(
          Path()
            ..moveTo(8, 7.5)
            ..lineTo(12, 3.5)
            ..lineTo(16, 7.5),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(7, 11)
            ..lineTo(5, 11)
            ..lineTo(5, 20.5)
            ..lineTo(19, 20.5)
            ..lineTo(19, 11)
            ..lineTo(17, 11),
          p,
        );
      case AstraIcon.sparkle:
        _star(canvas, const Offset(12, 12), 9, p);
    }
  }

  /// Четырёхлучевая звезда.
  static void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final rr = i.isEven ? r : r * 0.32;
      final pt = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  static void _crescent(Canvas canvas, Offset c, double r, Paint paint) {
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(center: c.translate(r * 0.45, -r * 0.25), radius: r * 0.85));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), paint);
  }

  @override
  bool shouldRepaint(_LineIconPainter old) =>
      old.icon != icon || old.color != color || old.strokeWidth != strokeWidth;
}

/// Эмблема для карты дня: сакральная геометрия, параметризованная номером
/// карты (число лучей, вложенный многоугольник, орбиты). Каждая карта колоды
/// получает уникальный, но стилистически единый символ без растровых ассетов.
class EmblemPainter extends CustomPainter {
  EmblemPainter({required this.seed, this.color = AppColors.gold, this.glow = 1});

  final int seed;
  final Color color;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rays = 4 + (seed % 5) * 2; // 4..12 лучей
    final polygon = 3 + (seed ~/ 5) % 4; // 3..6 углов
    final orbits = 1 + seed % 3;

    final line = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    // Свечение
    canvas.drawCircle(
      c,
      r * 0.55,
      Paint()
        ..color = color.withValues(alpha: 0.18 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
    );

    for (var i = 0; i < orbits; i++) {
      canvas.drawCircle(c, r * (0.92 - i * 0.12), thin);
    }

    // Лучи
    for (var i = 0; i < rays; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / rays;
      final long = i.isEven;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.42,
        c + Offset(math.cos(a), math.sin(a)) * r * (long ? 0.8 : 0.62),
        long ? line : thin,
      );
    }

    // Многоугольник
    final poly = Path();
    for (var i = 0; i <= polygon; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / polygon;
      final pt = c + Offset(math.cos(a), math.sin(a)) * r * 0.38;
      i == 0 ? poly.moveTo(pt.dx, pt.dy) : poly.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(poly, line);

    // Центр: звезда или полумесяц
    if (seed.isEven) {
      _LineIconPainter._star(canvas, c, r * 0.2, Paint()..color = AppColors.goldBright);
    } else {
      _LineIconPainter._crescent(canvas, c, r * 0.17, Paint()..color = AppColors.goldBright);
    }

    // Точки-звёзды на внешней орбите
    for (var i = 0; i < polygon; i++) {
      final a = -math.pi / 2 + (i + 0.5) * 2 * math.pi / polygon;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.92,
        1.8,
        Paint()..color = AppColors.goldBright,
      );
    }
  }

  @override
  bool shouldRepaint(EmblemPainter old) =>
      old.seed != seed || old.color != color || old.glow != glow;
}
