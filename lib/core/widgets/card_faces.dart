import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'line_icons.dart';

/// Рамка карты: тёмный бархатный фон, двойная золотая кайма, уголки-звёзды.
class CardFrame extends StatelessWidget {
  const CardFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF231A45), Color(0xFF130E2B), Color(0xFF1C1338)],
        ),
      ),
      child: CustomPaint(
        foregroundPainter: _FramePainter(),
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(7),
      const Radius.circular(14),
    );
    final inner = outer.deflate(4);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.gold.withValues(alpha: 0.8)
      ..strokeWidth = 0.9;
    canvas.drawRRect(outer, p);
    canvas.drawRRect(
      inner,
      p
        ..color = AppColors.gold.withValues(alpha: 0.35)
        ..strokeWidth = 0.6,
    );

    final star = Paint()..color = AppColors.gold;
    for (final c in [
      inner.outerRect.topLeft + const Offset(10, 10),
      inner.outerRect.topRight + const Offset(-10, 10),
      inner.outerRect.bottomLeft + const Offset(10, -10),
      inner.outerRect.bottomRight + const Offset(-10, -10),
    ]) {
      _diamond(canvas, c, 3.2, star);
    }
  }

  void _diamond(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + r * 0.55, c.dy)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - r * 0.55, c.dy)
        ..close(),
      p,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => false;
}

/// Рубашка карты: лучистая звезда с полумесяцем и россыпь точек.
class CardBack extends StatelessWidget {
  const CardBack({super.key, this.hint});

  /// Подпись снизу, например «Коснись, чтобы открыть».
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      child: Column(
        children: [
          const Spacer(),
          AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _BackPatternPainter())),
          const Spacer(),
          if (hint != null)
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: AppTypography.overline.copyWith(fontSize: 9, letterSpacing: 2),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _BackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.gold.withValues(alpha: 0.7)
      ..strokeWidth = 0.8;

    canvas.drawCircle(c, r * 0.95, line);
    canvas.drawCircle(c, r * 0.88, line..color = AppColors.gold.withValues(alpha: 0.3));
    line.color = AppColors.gold.withValues(alpha: 0.7);

    // Двенадцать лучей — по числу знаков
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * r * 0.5, c + dir * r * (i.isEven ? 0.88 : 0.74), line);
      canvas.drawCircle(c + dir * r * 0.95, 1.6, Paint()..color = AppColors.gold);
    }

    // Восьмиконечная звезда
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final a = -math.pi / 2 + i * math.pi / 8;
      final rr = i.isEven ? r * 0.48 : r * 0.22;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(star..close(), line);

    // Полумесяц в центре
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.15));
    final inner = Path()
      ..addOval(Rect.fromCircle(center: c.translate(r * 0.07, -r * 0.04), radius: r * 0.13));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      Paint()..color = AppColors.goldBright,
    );
  }

  @override
  bool shouldRepaint(_BackPatternPainter old) => false;
}

/// Лицевая сторона «звёздной карты»: римский номер, эмблема, название.
class StarCardFront extends StatelessWidget {
  const StarCardFront({
    super.key,
    required this.number,
    required this.title,
    this.subtitle,
    this.emblem,
  });

  final int number;
  final String title;
  final String? subtitle;

  /// Своя эмблема (например, созвездие знака). По умолчанию — геометрическая.
  final Widget? emblem;

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            toRoman(number),
            style: AppTypography.textTheme.titleMedium!.copyWith(
              fontFamily: AppFonts.display,
              color: AppColors.gold,
              letterSpacing: 3,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: emblem ?? CustomPaint(painter: EmblemPainter(seed: number)),
                ),
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.headlineSmall!.copyWith(
              color: AppColors.goldBright,
              fontSize: 22,
              height: 1.05,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.overline.copyWith(fontSize: 8.5),
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

String toRoman(int n) {
  const map = [
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];
  final b = StringBuffer();
  var rest = n;
  for (final (value, symbol) in map) {
    while (rest >= value) {
      b.write(symbol);
      rest -= value;
    }
  }
  return b.toString();
}
