// Генератор скриншотов для ревью дизайна (не проверяет, а только снимает).
//   flutter test test/screenshots --dart-define=SCREENSHOT_DIR=/abs/path
// Без SCREENSHOT_DIR тест пропускается.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

const _dir = String.fromEnvironment('SCREENSHOT_DIR');

void main() {
  setUpAll(loadAppFonts);
  final key = GlobalKey();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('онбординг и «Сегодня»', skip: _dir.isEmpty, (tester) async {
    // В тестах тени по умолчанию рисуются без размытия — включаем как на устройстве.
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    usePhoneSize(tester);
    final app = await buildTestApp();
    await tester.pumpWidget(RepaintBoundary(key: key, child: app));
    await pumpFor(tester, const Duration(seconds: 3));
    await shot(tester, '01_welcome');

    await tester.tap(find.text('Начать знакомство'));
    await pumpFor(tester, const Duration(seconds: 1));
    await shot(tester, '02_birthdate');

    await tester.tap(find.text('Дальше'));
    await pumpFor(tester, const Duration(seconds: 4));
    await shot(tester, '03_sign');

    await tester.tap(find.text('Открыть мою карту'));
    await pumpFor(tester, const Duration(seconds: 1));
    await shot(tester, '04_card_closed');
    await tester.tap(find.text('КОСНИСЬ'));
    await pumpFor(tester, const Duration(milliseconds: 550));
    await shot(tester, '05_card_flash');
    await pumpFor(tester, const Duration(seconds: 3));
    await shot(tester, '06_card_open');

    await tester.tap(find.text('К звёздам'));
    await pumpFor(tester, const Duration(seconds: 3));
    await shot(tester, '07_today_top');

    await tester.tap(find.text('КОСНИСЬ, ЧТОБЫ ОТКРЫТЬ'));
    await pumpFor(tester, const Duration(seconds: 4));
    await shot(tester, '08_today_card_open');

    final list = find.byType(Scrollable).first;
    for (final (i, dy) in [(9, -620.0), (10, -620.0), (11, -700.0)]) {
      await tester.drag(list, Offset(0, dy));
      await pumpFor(tester, const Duration(seconds: 4));
      await shot(tester, '${i.toString().padLeft(2, '0')}_today_scroll');
    }

    await tester.tap(find.text('Знаки'));
    await pumpFor(tester, const Duration(seconds: 2));
    await shot(tester, '12_signs_tab');
    await tester.tap(find.text('Профиль'));
    await pumpFor(tester, const Duration(seconds: 2));
    await shot(tester, '13_profile_tab');
  });
}
