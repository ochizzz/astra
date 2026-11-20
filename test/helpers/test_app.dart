import 'dart:io';

import 'package:astra/app/app.dart';
import 'package:astra/core/services/preferences.dart';
import 'package:astra/core/widgets/parallax.dart';
import 'package:astra/features/today/data/today_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Загружает шрифты проекта, чтобы скриншоты в тестах выглядели как на устройстве.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File(f.startsWith('/') ? f : 'assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('CormorantGaramond', [
    'CormorantGaramond-Regular.ttf',
    'CormorantGaramond-Italic.ttf',
    'CormorantGaramond-Medium.ttf',
    'CormorantGaramond-MediumItalic.ttf',
    'CormorantGaramond-SemiBold.ttf',
    'CormorantGaramond-Bold.ttf',
  ]);
  await load('AstraSymbols', ['AstraSymbols-Zodiac.ttf']);
  await load('AstraSymbolsStars', ['AstraSymbols-Stars.ttf']);
  final icons = File(
    '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) await load('MaterialIcons', [icons.path]);
  await load('Manrope', [
    'Manrope-Light.ttf',
    'Manrope-Regular.ttf',
    'Manrope-Medium.ttf',
    'Manrope-SemiBold.ttf',
    'Manrope-Bold.ttf',
  ]);
}

/// Приложение с подменёнными зависимостями: локальное хранилище в памяти,
/// параллакс без датчиков, фиксированная дата.
Future<Widget> buildTestApp({Map<String, Object> prefs = const {}, DateTime? today}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await initializeDateFormatting('ru');
  final sp = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      parallaxProvider.overrideWithValue(ParallaxController.still()),
      motionSensorsEnabledProvider.overrideWithValue(false),
      todayDateProvider.overrideWithValue(today ?? DateTime(2026, 11, 19)),
    ],
    child: const AstraApp(),
  );
}

void usePhoneSize(WidgetTester tester, {double dpr = 1}) {
  tester.view.physicalSize = Size(390 * dpr, 844 * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

/// Прокручивает время кадрами — чтобы успевали async-цепочки и переходы.
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < duration; t += step) {
    await tester.pump(step);
  }
}
