// Модели тестов. Тест целиком описывается данными, поэтому новые тесты
// можно добавлять без изменения кода (позже — из Firestore).

/// Вариант ответа: даёт очки одному или нескольким результатам.
class TestAnswer {
  const TestAnswer(this.text, this.scores);

  final String text;

  /// id результата → очки (обычно 1–3).
  final Map<String, int> scores;
}

class TestQuestion {
  const TestQuestion(this.text, this.answers);

  final String text;

  /// 3–4 варианта ответа.
  final List<TestAnswer> answers;
}

class TestResult {
  const TestResult({
    required this.id,
    required this.title,
    required this.symbol,
    required this.description,
    required this.advice,
  });

  final String id;

  /// Название результата, 1–4 слова: «Огонь».
  final String title;

  /// Один символ для карточки: ✦ ☽ ☀ ♈ … (из набора: ✦ ✧ ★ ☽ ☀ ◆ или глиф знака).
  final String symbol;

  /// Описание результата, 300–500 символов.
  final String description;

  /// Совет, одна фраза до 120 символов.
  final String advice;
}

class AstraTest {
  const AstraTest({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.questions,
    required this.results,
  });

  final String id;
  final String title;

  /// Подзаголовок в каталоге, до 60 символов.
  final String subtitle;

  /// Сколько минут занимает.
  final int minutes;

  /// 7–9 вопросов.
  final List<TestQuestion> questions;

  /// 4 результата.
  final List<TestResult> results;

  /// Результат по набранным очкам; при равенстве — первый в списке.
  TestResult resultFor(Map<String, int> totals) {
    var best = results.first;
    var bestScore = totals[best.id] ?? 0;
    for (final r in results.skip(1)) {
      final s = totals[r.id] ?? 0;
      if (s > bestScore) {
        best = r;
        bestScore = s;
      }
    }
    return best;
  }
}
