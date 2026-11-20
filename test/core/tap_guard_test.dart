import 'dart:async';

import 'package:astra/core/widgets/tap_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('пока действие выполняется, повторные нажатия игнорируются', () async {
    final guard = TapGuard(cooldown: Duration.zero);
    final done = Completer<void>();
    var calls = 0;
    Future<void> action() {
      calls++;
      return done.future;
    }

    final first = guard.run(action);
    unawaited(guard.run(action));
    unawaited(guard.run(action));
    expect(calls, 1);
    expect(guard.busy, isTrue);

    done.complete();
    await first;
    expect(guard.busy, isFalse);
    await guard.run(() async => calls++);
    expect(calls, 2);
  });

  test('двойной тап по мгновенному действию срабатывает один раз', () async {
    final guard = TapGuard();
    var calls = 0;
    await guard.run(() => calls++);
    await guard.run(() => calls++);
    expect(calls, 1);
  });

  test('после ошибки кнопка снова доступна', () async {
    final guard = TapGuard(cooldown: Duration.zero);
    await expectLater(guard.run(() async => throw StateError('x')), throwsStateError);
    expect(guard.busy, isFalse);
  });
}
