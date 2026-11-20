import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Кольцевой индикатор 0..100 с плавным заполнением и подписью.
class RingMeter extends StatelessWidget {
  const RingMeter({
    super.key,
    required this.value,
    required this.label,
    this.size = 68,
    this.color = AppColors.gold,
    this.delay = Duration.zero,
  });

  final int value;
  final String label;
  final double size;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value процентов',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(value),
            tween: Tween(begin: 0, end: value / 100),
            duration: const Duration(milliseconds: 1400) + delay,
            curve: Interval(
              delay.inMilliseconds / (1400 + delay.inMilliseconds),
              1,
              curve: Curves.easeOutCubic,
            ),
            builder: (context, t, _) => SizedBox.square(
              dimension: size,
              child: CustomPaint(
                painter: _RingPainter(t, color),
                child: Center(
                  child: Text(
                    '${(t * 100).round()}',
                    style: AppTypography.textTheme.titleLarge!.copyWith(
                      fontSize: size * 0.32,
                      color: AppColors.goldBright,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(4);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.strokeSoft;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (t <= 0) return;
    final sweep = math.pi * 2 * t;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: [color.withValues(alpha: 0.5), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.color != color;
}
