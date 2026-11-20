import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../app/router.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/astra_buttons.dart';
import '../../../core/widgets/parallax.dart';
import '../../../core/widgets/sub_page.dart';
import '../data/tests_content.dart';

enum _BallState { idle, swirling, answer }

/// «Шар судьбы»: мысленно задай вопрос и встряхни телефон.
class MagicBallScreen extends ConsumerStatefulWidget {
  const MagicBallScreen({super.key});

  @override
  ConsumerState<MagicBallScreen> createState() => _MagicBallScreenState();
}

class _MagicBallScreenState extends ConsumerState<MagicBallScreen> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();
  late final AnimationController _swirl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  final _rnd = math.Random();
  StreamSubscription<UserAccelerometerEvent>? _shakeSub;
  _BallState _state = _BallState.idle;
  String _answer = '';
  int _lastIndex = -1;

  static const _shakeThreshold = 13.0; // м/с² без учёта гравитации

  @override
  void initState() {
    super.initState();
    if (ref.read(motionSensorsEnabledProvider)) {
      try {
        _shakeSub = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen((e) {
              final force = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
              if (force > _shakeThreshold) _ask();
            }, onError: (_) {});
      } catch (_) {
        // Нет датчика — остаётся кнопка.
      }
    }
  }

  Future<void> _ask() async {
    if (_state == _BallState.swirling) return;
    ref.read(appFeedbackProvider).reveal();
    setState(() => _state = _BallState.swirling);
    // Несколько лёгких толчков, пока «туман» клубится.
    for (var i = 0; i < 3; i++) {
      if (ref.read(feedbackSettingsProvider).haptics) unawaited(HapticFeedback.lightImpact());
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }
    await _swirl.forward(from: 0);
    if (!mounted) return;
    var i = _rnd.nextInt(magicBallAnswers.length);
    if (i == _lastIndex) i = (i + 1) % magicBallAnswers.length;
    _lastIndex = i;
    ref.read(appFeedbackProvider).success();
    setState(() {
      _answer = magicBallAnswers[i];
      _state = _BallState.answer;
    });
  }

  @override
  void dispose() {
    _shakeSub?.cancel();
    _idle.dispose();
    _swirl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final size = math.min(MediaQuery.sizeOf(context).width - 80, 300.0);

    return SubPage(
      parent: Routes.tests,
      children: [
        const Text('ШАР СУДЬБЫ', textAlign: TextAlign.center, style: AppTypography.overline),
        const SizedBox(height: 10),
        Text('Задай вопрос мысленно', textAlign: TextAlign.center, style: text.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Вопрос, на который можно ответить «да» или «нет». '
          'Затем встряхни телефон или коснись шара.',
          textAlign: TextAlign.center,
          style: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        Center(
          child: Semantics(
            button: true,
            label:
                'Шар судьбы. ${_state == _BallState.answer ? _answer : 'Коснись, чтобы спросить'}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _ask,
              child: AnimatedBuilder(
                animation: Listenable.merge([_idle, _swirl]),
                builder: (context, _) => CustomPaint(
                  size: Size.square(size),
                  painter: _OrbPainter(
                    t: _idle.value,
                    swirl: _state == _BallState.swirling ? _swirl.value : 0,
                    swirling: _state == _BallState.swirling,
                  ),
                  child: SizedBox.square(
                    dimension: size,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(size * 0.2),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          child: switch (_state) {
                            _BallState.answer => Text(
                              _answer,
                              key: ValueKey(_answer),
                              textAlign: TextAlign.center,
                              style: AppTypography.quote.copyWith(
                                fontSize: 22,
                                color: AppColors.goldBright,
                                shadows: [
                                  Shadow(
                                    color: AppColors.gold.withValues(alpha: 0.6),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            _BallState.idle => Text(
                              '✦',
                              key: const ValueKey('idle'),
                              style: TextStyle(
                                fontSize: 36,
                                color: AppColors.goldBright.withValues(
                                  alpha: 0.6 + 0.4 * math.sin(_idle.value * math.pi * 6).abs(),
                                ),
                              ),
                            ),
                            _BallState.swirling => const SizedBox.shrink(key: ValueKey('swirl')),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 36),
        GoldButton(
          label: _state == _BallState.answer ? 'Спросить ещё' : 'Спросить звёзды',
          onPressed: _state == _BallState.swirling ? null : _ask,
        ),
        const SizedBox(height: 16),
        Text(
          'Шар судьбы — игра для настроения, а не руководство к действию ✦',
          textAlign: TextAlign.center,
          style: text.labelSmall,
        ),
      ],
    );
  }
}

/// Стеклянная сфера с клубящейся туманностью и звёздами внутри.
class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.t, required this.swirl, required this.swirling});

  final double t;
  final double swirl;
  final bool swirling;

  static final _stars = List.generate(
    40,
    (i) => (
      a: math.Random(i).nextDouble() * math.pi * 2,
      r: math.sqrt(math.Random(i * 7 + 1).nextDouble()) * 0.85,
      s: 0.6 + math.Random(i * 13 + 2).nextDouble() * 1.2,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Внешнее свечение
    canvas.drawCircle(
      c,
      r * 1.05,
      Paint()
        ..color = AppColors.lavender.withValues(alpha: swirling ? 0.45 : 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
    );

    // Тело шара
    final body = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.25, -0.35),
          radius: 1.0,
          colors: [Color(0xFF3E2C78), Color(0xFF1C1340), AppColors.night],
          stops: [0, 0.55, 1],
        ).createShader(body),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(body));

    // Туманность: два вращающихся облака
    final speed = swirling ? 4.0 + swirl * 8 : 1.0;
    for (var i = 0; i < 2; i++) {
      final angle = (t * speed + i * 0.5) * math.pi * 2 * (i.isEven ? 1 : -1);
      final center = c + Offset(math.cos(angle), math.sin(angle)) * r * 0.35;
      final cloudR = r * (swirling ? 0.9 : 0.7);
      canvas.drawCircle(
        center,
        cloudR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (i.isEven ? AppColors.lavender : AppColors.moonPink).withValues(
                alpha: swirling ? 0.45 : 0.22,
              ),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: cloudR)),
      );
    }

    // Звёзды внутри, медленно вращаются
    final rot = t * math.pi * 2 * (swirling ? 3 : 0.3);
    for (final s in _stars) {
      final a = s.a + rot;
      final p = c + Offset(math.cos(a), math.sin(a)) * r * s.r;
      canvas.drawCircle(
        p,
        s.s,
        Paint()..color = AppColors.textPrimary.withValues(alpha: swirling ? 0.3 : 0.7),
      );
    }
    canvas.restore();

    // Блик стекла
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(-r * 0.35, -r * 0.45), width: r * 0.55, height: r * 0.28),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.06),
    );

    // Тонкое золотое кольцо
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.gold.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.t != t || old.swirl != swirl || old.swirling != swirling;
}
