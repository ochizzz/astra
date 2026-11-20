// Регрессия: быстрые повторные нажатия не должны дублировать действия.
import 'dart:convert';

import 'package:astra/core/auth/cloud_sync.dart';
import 'package:astra/features/tests/data/tests_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

const _onboarded = {'user.birthDate': '2004-06-15', 'user.onboardingDone': true};

Future<void> _tapRapidly(WidgetTester tester, Finder finder, {int times = 4}) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(finder, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// Облако, которое отвечает медленно — как реальный Firestore у вошедшего
/// пользователя. Именно в это время пользователь успевает нажать ещё раз.
class _SlowCloudSync extends CloudSync {
  _SlowCloudSync(super.ref);

  @override
  Future<void> saveDiaryEntry(Map<String, Object?> entry) =>
      Future<void>.delayed(const Duration(milliseconds: 800));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Дневник: многократное «Сохранить» создаёт одну запись', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      await buildTestApp(
        prefs: _onboarded,
        overrides: [cloudSyncProvider.overrideWith(_SlowCloudSync.new)],
      ),
    );
    await pumpFor(tester, const Duration(seconds: 2));
    await tester.tap(find.text('Дневник'));
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Первая запись'));
    await pumpFor(tester, const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), 'Одна-единственная запись');
    await pumpFor(tester, const Duration(milliseconds: 300));
    await _tapRapidly(tester, find.text('Сохранить'));
    await pumpFor(tester, const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final entries = jsonDecode(prefs.getString('diary.entries')!) as List;
    expect(entries, hasLength(1));
    expect(find.text('Одна-единственная запись'), findsOneWidget);
  });

  testWidgets('Тест: двойной тап по ответу засчитывается один раз', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(await buildTestApp(prefs: _onboarded));
    await pumpFor(tester, const Duration(seconds: 2));
    await tester.tap(find.text('Тесты'));
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text(astraTests.first.title));
    await pumpFor(tester, const Duration(seconds: 1));

    await _tapRapidly(tester, find.text(astraTests.first.questions.first.answers.first.text));
    await pumpFor(tester, const Duration(seconds: 1));

    expect(find.text('Вопрос 2'), findsOneWidget);
    expect(find.text(astraTests.first.questions[1].text), findsOneWidget);
  });

  testWidgets('Онбординг: частые нажатия «Назад» не роняют приложение', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(await buildTestApp());
    await pumpFor(tester, const Duration(seconds: 3));
    await tester.tap(find.text('Начать знакомство'));
    await pumpFor(tester, const Duration(seconds: 1));

    // Два нажатия в одном кадре — до того, как экран успеет перестроиться.
    await tester.tap(find.byTooltip('Назад'));
    await tester.tap(find.byTooltip('Назад'));
    await pumpFor(tester, const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Начать знакомство'), findsOneWidget);
  });
}
