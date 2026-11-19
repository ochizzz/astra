import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'parallax.dart';

/// Карта, которая переворачивается в 3D с золотой вспышкой и искрами.
///
/// Пока карта закрыта, она слегка наклоняется вслед за телефоном
/// (параллакс) и мерцает бликом по рубашке.
class FlipCard extends ConsumerStatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.flipped = false,
    this.onFlip,
    this.width = 220,
    this.aspectRatio = 0.62,
  });

  /// Лицевая сторона (видна после переворота).
  final Widget front;

  /// Рубашка.
  final Widget back;

  /// Начальное состояние / внешнее управление.
  final bool flipped;

  /// Вызывается в момент переворота по тапу.
  final VoidCallback? onFlip;
  final double width;
  final double aspectRatio;

  @override
  ConsumerState<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends ConsumerState<FlipCard> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: widget.flipped ? 1 : 0,
  );
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  late final Animation<double> _angle = CurvedAnimation(
    parent: _flip,
    curve: Curves.easeInOutCubicEmphasized,
  );

  bool _flashFired = false;

  @override
  void initState() {
    super.initState();
    if (!widget.flipped) _shine.repeat();
    _flip.addListener(() {
      if (!_flashFired && _flip.value > 0.42 && _flip.status == AnimationStatus.forward) {
        _flashFired = true;
        _flash.forward(from: 0);
      }
    });
  }

  @override
  void didUpdateWidget(FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.flipped && !old.flipped && _flip.value == 0) _startFlip();
    if (!widget.flipped && old.flipped) {
      _flip.value = 0;
      _flashFired = false;
      _shine.repeat();
    }
  }

  void _startFlip() {
    _shine.stop();
    if (MediaQuery.of(context).disableAnimations) {
      _flip.value = 1;
      return;
    }
    _flip.forward();
  }

  void _onTap() {
    if (_flip.value > 0) return;
    widget.onFlip?.call();
    _startFlip();
  }

  @override
  void dispose() {
    _flip.dispose();
    _flash.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parallax = ref.watch(parallaxProvider);
    final height = widget.width / widget.aspectRatio;

    return Semantics(
      button: _flip.value == 0,
      label: _flip.value == 0 ? 'Открыть карту' : null,
      child: GestureDetector(
        onTap: _onTap,
        child: SizedBox(
          width: widget.width * 1.6,
          height: height * 1.25,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Вспышка позади карты
              _FlashBurst(animation: _flash, size: widget.width * 1.6),
              AnimatedBuilder(
                animation: Listenable.merge([_angle, parallax, _shine]),
                builder: (context, _) {
                  final a = _angle.value * math.pi;
                  final tilt = _flip.value == 0 ? parallax.value : Offset.zero;
                  // Лёгкий «подскок» карты во время переворота
                  final lift = math.sin(_flip.value * math.pi);
                  final showFront = a > math.pi / 2;
                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.0011)
                    ..rotateX(-tilt.dy * 0.12)
                    ..rotateY(a + tilt.dx * 0.16)
                    ..scaleByDouble(1 + lift * 0.08, 1 + lift * 0.08, 1, 1);

                  return Transform(
                    alignment: Alignment.center,
                    transform: matrix,
                    child: Container(
                      width: widget.width,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                          ...AppColors.goldGlow(0.35 + lift * 0.9),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: showFront
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: widget.front,
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  widget.back,
                                  if (_flip.value == 0) _Shine(progress: _shine.value),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
              // Искры поверх карты
              IgnorePointer(
                child: _Sparks(animation: _flash, size: widget.width * 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Диагональный блик, пробегающий по рубашке.
class _Shine extends StatelessWidget {
  const _Shine({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    // Блик проходит за первые 35% цикла, дальше пауза.
    final p = (progress / 0.35).clamp(0.0, 1.0);
    if (p >= 1) return const SizedBox.shrink();
    final x = -1.5 + p * 3;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(x - 0.4, -1),
            end: Alignment(x + 0.4, 1),
            colors: [
              Colors.white.withValues(alpha: 0),
              AppColors.goldBright.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlashBurst extends StatelessWidget {
  const _FlashBurst({required this.animation, required this.size});

  final Animation<double> animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          final intensity = math.sin(math.pi * math.pow(t, 0.6));
          return Container(
            width: size * (0.6 + t * 0.9),
            height: size * (0.6 + t * 0.9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.goldBright.withValues(alpha: 0.75 * intensity),
                  AppColors.gold.withValues(alpha: 0.35 * intensity),
                  AppColors.gold.withValues(alpha: 0),
                ],
                stops: const [0, 0.35, 1],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Золотые искры, разлетающиеся от центра карты.
class _Sparks extends StatelessWidget {
  const _Sparks({required this.animation, required this.size});

  final Animation<double> animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) =>
          CustomPaint(size: Size.square(size), painter: _SparksPainter(animation.value)),
    );
  }
}

class _SparksPainter extends CustomPainter {
  _SparksPainter(this.t);

  final double t;
  static final _rnd = math.Random(42);
  static final _sparks = List.generate(
    28,
    (_) => (
      angle: _rnd.nextDouble() * 2 * math.pi,
      speed: 0.35 + _rnd.nextDouble() * 0.65,
      size: 0.8 + _rnd.nextDouble() * 1.8,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final c = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(t);
    final fade = 1 - Curves.easeIn.transform(t);
    final paint = Paint();
    for (final s in _sparks) {
      final dist = size.width * 0.5 * s.speed * eased;
      final pos = c + Offset(math.cos(s.angle), math.sin(s.angle)) * dist;
      paint
        ..color = AppColors.goldBright.withValues(alpha: fade)
        ..maskFilter = null;
      canvas.drawCircle(pos, s.size * (1 - t * 0.5), paint);
      paint
        ..color = AppColors.gold.withValues(alpha: 0.4 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(pos, s.size * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_SparksPainter old) => old.t != t;
}
