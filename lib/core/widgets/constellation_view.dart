import 'package:material_ui/material_ui.dart';

import '../astro/zodiac.dart';
import '../theme/app_colors.dart';

/// Созвездие знака, которое «прорисовывается»: сначала вспыхивают звёзды,
/// затем по очереди тянутся золотые линии.
class ConstellationView extends StatefulWidget {
  const ConstellationView({
    super.key,
    required this.constellation,
    this.animate = true,
    this.duration = const Duration(milliseconds: 2200),
    this.strokeWidth = 1.1,
    this.starScale = 1,
    this.color = AppColors.gold,
  });

  final Constellation constellation;
  final bool animate;
  final Duration duration;
  final double strokeWidth;
  final double starScale;
  final Color color;

  @override
  State<ConstellationView> createState() => _ConstellationViewState();
}

class _ConstellationViewState extends State<ConstellationView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (MediaQuery.of(context).disableAnimations) {
          _c.value = 1;
        } else {
          _c.forward();
        }
      });
    } else {
      _c.value = 1;
    }
  }

  @override
  void didUpdateWidget(ConstellationView old) {
    super.didUpdateWidget(old);
    if (old.constellation != widget.constellation && widget.animate) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ConstellationPainter(
        constellation: widget.constellation,
        progress: _c,
        strokeWidth: widget.strokeWidth,
        starScale: widget.starScale,
        color: widget.color,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class ConstellationPainter extends CustomPainter {
  ConstellationPainter({
    required this.constellation,
    required this.progress,
    this.strokeWidth = 1.1,
    this.starScale = 1,
    this.color = AppColors.gold,
  }) : super(repaint: progress);

  final Constellation constellation;
  final Animation<double> progress;
  final double strokeWidth;
  final double starScale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value;
    final side = size.shortestSide;
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    Offset at(int i) =>
        origin + Offset(constellation.stars[i].dx * side, constellation.stars[i].dy * side);

    // 0..0.3 — звёзды, 0.25..1 — линии одна за другой.
    final starsT = Curves.easeOut.transform((p / 0.3).clamp(0.0, 1.0));
    final linesT = ((p - 0.25) / 0.75).clamp(0.0, 1.0);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = strokeWidth * 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final lines = constellation.lines;
    for (var i = 0; i < lines.length; i++) {
      final local = (linesT * lines.length - i).clamp(0.0, 1.0);
      if (local <= 0) break;
      final a = at(lines[i].$1);
      final b = Offset.lerp(a, at(lines[i].$2), Curves.easeInOut.transform(local))!;
      canvas.drawLine(a, b, glowPaint);
      canvas.drawLine(a, b, linePaint);
    }

    for (var i = 0; i < constellation.stars.length; i++) {
      final bright = i == constellation.brightest;
      final appear = ((starsT * constellation.stars.length) - i * 0.6).clamp(0.0, 1.0);
      if (appear <= 0) continue;
      final r = (bright ? 3.4 : 2.2) * starScale * appear;
      final c = at(i);
      canvas.drawCircle(
        c,
        r * 3.2,
        Paint()
          ..color = color.withValues(alpha: 0.28 * appear)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.6),
      );
      canvas.drawCircle(c, r, Paint()..color = AppColors.goldBright.withValues(alpha: appear));
      if (bright) {
        final l = r * 3.5;
        final sp = Paint()
          ..color = AppColors.goldBright.withValues(alpha: 0.6 * appear)
          ..strokeWidth = 0.7;
        canvas.drawLine(c.translate(-l, 0), c.translate(l, 0), sp);
        canvas.drawLine(c.translate(0, -l), c.translate(0, l), sp);
      }
    }
  }

  @override
  bool shouldRepaint(ConstellationPainter old) =>
      old.constellation != constellation || old.color != color;
}
