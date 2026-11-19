import 'dart:convert';

import 'package:astra/core/astro/zodiac.dart';
import 'package:astra/features/today/data/mock_content.dart';
import 'package:astra/features/today/domain/daily_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('документ дня переживает JSON (как в Firestore)', () {
    final doc = mockDailyBuilder.build(DateTime(2026, 11, 19));
    final json = jsonDecode(jsonEncode(doc.toJson())) as Map<String, Object?>;
    final parsed = DailyDoc.fromJson(json);

    expect(parsed.day, '2026-11-19');
    expect(parsed.card.id, doc.card.id);
    expect(parsed.quote.text, doc.quote.text);
    expect(parsed.horoscopes.length, 12);
    expect(parsed.horoscopeFor(ZodiacSign.leo)!.text, doc.horoscopes[ZodiacSign.leo]!.text);
  });

  test('один и тот же день — один и тот же контент', () {
    final a = mockDailyBuilder.build(DateTime(2026, 1, 1));
    final b = mockDailyBuilder.build(DateTime(2026, 1, 1));
    expect(a.card.id, b.card.id);
    expect(a.question.id, b.question.id);
  });

  test('битый документ — FormatException', () {
    expect(() => DailyDoc.fromJson({'day': '2026-01-01'}), throwsFormatException);
  });
}
