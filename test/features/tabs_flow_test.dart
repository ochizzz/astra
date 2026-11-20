import 'package:astra/core/astro/zodiac.dart';
import 'package:astra/features/signs/data/compat_pairs.dart';
import 'package:astra/features/signs/data/sign_profiles.dart';
import 'package:astra/features/signs/domain/sign_models.dart';
import 'package:astra/features/tests/data/tests_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

const _onboarded = {'user.birthDate': '2004-06-15', 'user.onboardingDone': true};

void main() {
  setUpAll(loadAppFonts);

  group('контент', () {
    test('профили всех 12 знаков', () {
      expect(signProfiles.keys.toSet(), ZodiacSign.values.toSet());
    });

    test('совместимость есть для каждой пары, в любом порядке', () {
      expect(compatPairs.length, 78);
      for (final a in ZodiacSign.values) {
        for (final b in ZodiacSign.values) {
          expect(compatPairs[pairKey(a, b)], isNotNull, reason: '${a.name}+${b.name}');
        }
      }
    });

    test('у каждого результата теста есть путь к нему', () {
      for (final t in astraTests) {
        final reachable = {
          for (final q in t.questions)
            for (final a in q.answers) ...a.scores.keys,
        };
        expect(reachable, t.results.map((r) => r.id).toSet(), reason: t.id);
      }
    });
  });

  testWidgets('Знаки → профиль → совместимость', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(await buildTestApp(prefs: _onboarded));
    await pumpFor(tester, const Duration(seconds: 2));

    await tester.tap(find.text('Знаки'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('ты'), findsOneWidget); // свой знак отмечен

    await tester.tap(find.text('Близнецы').first);
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('ХАРАКТЕР'), findsOneWidget);

    await tester
        .scrollUntilVisible(
          find.textContaining('Совместимость с моим знаком').hitTestable(),
          300,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 30,
        )
        .catchError((_) {});
    await tester.tap(find.text('Знаки')); // назад во вкладку
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Совместимость'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('СОВМЕСТИМОСТЬ'), findsOneWidget);
    expect(find.text('Любовь'), findsOneWidget);
  });

  testWidgets('Дневник: новая запись появляется в ленте', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(await buildTestApp(prefs: _onboarded));
    await pumpFor(tester, const Duration(seconds: 2));

    await tester.tap(find.text('Дневник'));
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Первая запись'));
    await pumpFor(tester, const Duration(seconds: 1));

    await tester.tap(find.text('Сияю'));
    await tester.enterText(find.byType(TextField), 'Сегодня было волшебно');
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.text('Сохранить'));
    await pumpFor(tester, const Duration(seconds: 2));

    expect(find.text('Сегодня было волшебно'), findsOneWidget);
    expect(find.text('СЕГОДНЯ'), findsOneWidget);

    await tester.tap(find.text('Лунный календарь'));
    await pumpFor(tester, const Duration(seconds: 1));
    expect(find.textContaining('лунный день'), findsOneWidget);
  });

  testWidgets('Тест: восемь ответов → результат сохранён', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(await buildTestApp(prefs: _onboarded));
    await pumpFor(tester, const Duration(seconds: 2));

    await tester.tap(find.text('Тесты'));
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text(astraTests.first.title));
    await pumpFor(tester, const Duration(seconds: 1));

    for (final q in astraTests.first.questions) {
      await tester.tap(find.text(q.answers.first.text));
      await pumpFor(tester, const Duration(milliseconds: 800));
    }
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('ТВОЙ РЕЗУЛЬТАТ'), findsOneWidget);

    await tester.ensureVisible(find.text('Другие тесты'));
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.text('Другие тесты'));
    await pumpFor(tester, const Duration(seconds: 1));
    expect(find.textContaining('Твой результат:'), findsOneWidget);
  });
}
