// Рендер картинок виджета: для ревью дизайна и для превью в списке виджетов.
//   flutter test test/screenshots/widget_render_test.dart --dart-define=WIDGET_OUT=/abs/dir
import 'dart:io';
import 'dart:ui' as ui;

import 'package:astra/core/astro/moon_phase.dart';
import 'package:astra/core/astro/zodiac.dart';
import 'package:astra/features/home_widget/widget_view.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

const _out = String.fromEnvironment('WIDGET_OUT');

void main() {
  setUpAll(loadAppFonts);

  for (final (name, flipped) in [('closed', false), ('open', true)]) {
    for (final variant in WidgetVariant.values) {
      testWidgets('виджет ${variant.name} $name', skip: _out.isEmpty, (tester) async {
        final key = GlobalKey();
        final date = DateTime(2026, 11, 20);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: AstraWidgetView(
                  variant: variant,
                  data: WidgetSnapshot(
                    date: date,
                    moon: MoonPhase.at(DateTime(2026, 11, 20, 12)),
                    quote: 'Звёзды не торопятся — и всё равно освещают весь путь.',
                    cardTitle: flipped ? 'Серебряный ключ' : null,
                    sign: ZodiacSign.gemini,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 3);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/widget_${variant.name}_$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
