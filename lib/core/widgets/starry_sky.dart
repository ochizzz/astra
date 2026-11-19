import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'parallax.dart';

/// Фон приложения: ночной градиент, туманности, три слоя мерцающих звёзд
/// с параллаксом от наклона телефона и редкие падающие звёзды.
///
/// Рисуется один раз под всеми экранами (см. `AstraApp`), поэтому при
/// переходах между экранами небо не «перезагружается».
class StarrySky extends ConsumerStatefulWidget {
  const StarrySky({super.key, this.seed = 7});

  final int seed;

  @override
  ConsumerState<StarrySky> createState() => _StarrySkyState();
}

class _StarrySkyState extends ConsumerState<StarrySky> with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  late final List<_Star> _stars;

  static const _cycle = Duration(seconds: 24);

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: _cycle)..repeat();
    final rnd = math.Random(widget.seed);
    _stars = List.generate(170, (i) {
      final layer = i < 110 ? 0 : (i < 155 ? 1 : 2);
      return _Star(
        position: Offset(rnd.nextDouble(), rnd.nextDouble()),
        layer: layer,
        radius: switch (layer) {
          0 => 0.4 + rnd.nextDouble() * 0.6,
          1 => 0.8 + rnd.nextDouble() * 0.7,
          _ => 1.3 + rnd.nextDouble() * 0.9,
        },
        phase: rnd.nextDouble(),
        // Целое число вспышек за цикл — анимация зациклена без рывка.
        speed: 1 + rnd.nextInt(5).toDouble(),
        warm: rnd.nextDouble() < 0.25,
      );
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final parallax = ref.watch(parallaxProvider);
    if (reduceMotion) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _SkyPainter(
          stars: _stars,
          clock: _clock,
          parallax: parallax,
          reduceMotion: reduceMotion,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.position,
    required this.layer,
    required this.radius,
    required this.phase,
    required this.speed,
    required this.warm,
  });

  final Offset position;
  final int layer;
  final double radius;
  final double phase;
  final double speed;
  final bool warm;
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.stars,
    required this.clock,
    required this.parallax,
    required this.reduceMotion,
  }) : super(repaint: Listenable.merge([clock, parallax]));

  final List<_Star> stars;
  final Animation<double> clock;
  final ValueListenable<Offset> parallax;
  final bool reduceMotion;

  static const _layerShift = [6.0, 14.0, 26.0];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = AppColors.skyGradient.createShader(rect));

    final tilt = reduceMotion ? Offset.zero : parallax.value;
    final t = clock.value;

    _paintNebula(canvas, size, tilt);

    final paint = Paint();
    for (final s in stars) {
      final shift = _layerShift[s.layer];
      final pos = Offset(
        s.position.dx * size.width + tilt.dx * shift,
        s.position.dy * size.height + tilt.dy * shift,
      );
      final twinkle = reduceMotion
          ? 0.7
          : 0.45 + 0.55 * (0.5 + 0.5 * math.sin(2 * math.pi * (t * s.speed + s.phase)));
      final color = s.warm ? AppColors.goldBright : AppColors.textPrimary;

      if (s.layer == 2) {
        paint
          ..color = (s.warm ? AppColors.gold : AppColors.lavender).withValues(alpha: 0.18 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(pos, s.radius * 3.2, paint);
        paint.maskFilter = null;
      }
      paint.color = color.withValues(alpha: (0.35 + 0.65 * twinkle) * (0.55 + s.layer * 0.2));
      canvas.drawCircle(pos, s.radius, paint);

      if (s.layer == 2 && twinkle > 0.85) {
        _paintSparkle(canvas, pos, s.radius * 5 * (twinkle - 0.85) / 0.15, color);
      }
    }

    if (!reduceMotion) _paintShootingStar(canvas, size, t);
  }

  void _paintNebula(Canvas canvas, Size size, Offset tilt) {
    void blob(Offset center, double radius, Color color) {
      final c = center + tilt * 10;
      final shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawCircle(c, radius, Paint()..shader = shader);
    }

    blob(
      Offset(size.width * 0.85, size.height * 0.12),
      size.width * 0.7,
      AppColors.lavender.withValues(alpha: 0.10),
    );
    blob(
      Offset(size.width * 0.1, size.height * 0.55),
      size.width * 0.8,
      AppColors.moonPink.withValues(alpha: 0.05),
    );
    blob(
      Offset(size.width * 0.6, size.height * 1.0),
      size.width * 0.9,
      AppColors.dusk.withValues(alpha: 0.6),
    );
  }

  void _paintSparkle(Canvas canvas, Offset c, double len, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-len, 0), c.translate(len, 0), p);
    canvas.drawLine(c.translate(0, -len), c.translate(0, len), p);
  }

  /// Одна падающая звезда за цикл, видна ~1.2 с.
  void _paintShootingStar(Canvas canvas, Size size, double t) {
    const start = 0.62;
    const duration = 0.05;
    if (t < start || t > start + duration) return;
    final p = (t - start) / duration;
    final from = Offset(size.width * 0.78, size.height * 0.08);
    final dir = Offset(-size.width * 0.45, size.height * 0.22);
    final head = from + dir * Curves.easeOut.transform(p);
    final tail = head - dir * 0.25;
    final opacity = math.sin(math.pi * p);
    final shader = LinearGradient(
      colors: [
        AppColors.goldBright.withValues(alpha: 0),
        AppColors.goldBright.withValues(alpha: 0.9 * opacity),
      ],
    ).createShader(Rect.fromPoints(tail, head));
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..shader = shader
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(head, 1.6, Paint()..color = AppColors.goldBright.withValues(alpha: opacity));
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.stars != stars || old.reduceMotion != reduceMotion;
}
