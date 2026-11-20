import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Наклон устройства, нормализованный в диапазон -1..1 по обеим осям.
///
/// Используется акселерометр (есть на всех телефонах, в отличие от гироскопа)
/// с двумя фильтрами: медленная «базовая линия» запоминает, как человек
/// обычно держит телефон, а быстрый фильтр сглаживает дрожание. Поэтому в
/// покое небо стоит по центру, а при наклоне мягко «плывёт».
class ParallaxController extends ValueNotifier<Offset> {
  ParallaxController() : super(Offset.zero) {
    try {
      _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
          .listen(_onEvent, onError: (_) {}, cancelOnError: true);
    } catch (_) {
      // Нет датчика или плагина (эмулятор, тесты) — параллакс просто выключен.
    }
  }

  /// Без датчиков: для тестов, скриншотов и режима «уменьшить движение».
  ParallaxController.still() : super(Offset.zero);

  StreamSubscription<AccelerometerEvent>? _sub;
  Offset? _baseline;
  Offset _smoothed = Offset.zero;

  static const _baselineFollow = 0.01;
  static const _smoothing = 0.12;
  static const _range = 3.0; // м/с², отклонение до полного сдвига

  void _onEvent(AccelerometerEvent e) {
    final raw = Offset(e.x, e.y);
    final base = _baseline = _baseline == null
        ? raw
        : Offset.lerp(_baseline, raw, _baselineFollow)!;
    final delta = raw - base;
    final target = Offset(
      (-delta.dx / _range).clamp(-1.0, 1.0),
      (delta.dy / _range).clamp(-1.0, 1.0),
    );
    _smoothed = Offset.lerp(_smoothed, target, _smoothing)!;
    if ((_smoothed - value).distanceSquared > 0.00002) value = _smoothed;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final parallaxProvider = Provider<ParallaxController>((ref) {
  final controller = ParallaxController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Можно ли слушать датчики движения (встряхивание и т.п.).
/// В тестах и скриншотах подменяется на false.
final motionSensorsEnabledProvider = Provider<bool>((ref) => true);
