import 'package:astra/features/today/presentation/today_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('онбординг: приветствие → дата → знак → карта → «Сегодня»', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(await buildTestApp());
    await pumpFor(tester, const Duration(seconds: 3));

    expect(find.text('Астра'), findsOneWidget);
    await tester.tap(find.text('Начать знакомство'));
    await pumpFor(tester, const Duration(seconds: 1));

    expect(find.text('Твоя дата рождения'), findsOneWidget);
    await tester.tap(find.text('Дальше'));
    await pumpFor(tester, const Duration(seconds: 3));

    // Значение по умолчанию — 15 июня → Близнецы
    expect(find.text('ТВОЙ ЗНАК'), findsOneWidget);
    expect(find.textContaining('Близнецы'), findsWidgets);
    await tester.tap(find.text('Открыть мою карту'));
    await pumpFor(tester, const Duration(seconds: 1));

    expect(find.text('Твоя карта'), findsOneWidget);
    await tester.tap(find.text('КОСНИСЬ'));
    await pumpFor(tester, const Duration(seconds: 2));

    await tester.tap(find.text('К звёздам'));
    await pumpFor(tester, const Duration(seconds: 3));

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('КАРТА ДНЯ'), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget); // вкладка
  });

  testWidgets('после онбординга приложение сразу открывает «Сегодня»', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      await buildTestApp(prefs: {'user.birthDate': '1998-11-02', 'user.onboardingDone': true}),
    );
    await pumpFor(tester, const Duration(seconds: 3));

    expect(find.byType(TodayScreen), findsOneWidget);

    // Карта дня переворачивается
    await tester.tap(find.text('КОСНИСЬ, ЧТОБЫ ОТКРЫТЬ'));
    await pumpFor(tester, const Duration(seconds: 3));
    expect(find.text('Поделиться'), findsOneWidget);

    // Ниже — гороскоп по знаку из сохранённой даты рождения
    await tester.drag(find.byType(TodayScreen), const Offset(0, -900));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('ГОРОСКОП · СКОРПИОН'), findsOneWidget);
  });
}
