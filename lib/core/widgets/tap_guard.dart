import 'dart:async';

import 'package:flutter/foundation.dart';

/// Обработчик нажатия: может быть синхронным или асинхронным.
typedef GuardedTap = FutureOr<void> Function();

/// Защита от повторных нажатий.
///
/// - Пока асинхронное действие выполняется, новые нажатия игнорируются
///   (иначе, например, «Сохранить» создаёт несколько одинаковых записей).
/// - После любого нажатия ещё [cooldown] новые нажатия игнорируются
///   (двойной тап не открывает экран дважды).
class TapGuard {
  TapGuard({this.cooldown = const Duration(milliseconds: 500)});

  final Duration cooldown;
  bool _busy = false;
  DateTime? _lastTap;

  /// Идёт ли сейчас асинхронное действие.
  bool get busy => _busy;

  /// Выполняет [action], если сейчас можно. [onBusyChanged] вызывается,
  /// когда меняется [busy] — чтобы кнопка перерисовалась.
  Future<void> run(GuardedTap action, {VoidCallback? onBusyChanged}) async {
    final now = DateTime.now();
    if (_busy) return;
    if (_lastTap != null && now.difference(_lastTap!) < cooldown) return;
    _lastTap = now;

    final result = action();
    if (result is! Future<void>) return;
    _busy = true;
    onBusyChanged?.call();
    try {
      await result;
    } finally {
      _busy = false;
      onBusyChanged?.call();
    }
  }
}
