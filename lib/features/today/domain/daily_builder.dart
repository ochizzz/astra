// Чистый Dart (без Flutter): используется и приложением (моковый режим),
// и генератором контента `tool/build_daily.dart`, который готовит документы
// `daily/{yyyy-MM-dd}` для загрузки в Firestore.

import '../../../core/astro/zodiac.dart';
import 'today_models.dart';

/// Содержимое одного документа `daily/{yyyy-MM-dd}`.
/// Один документ на день — одно чтение из Firestore на пользователя в сутки.
class DailyDoc {
  const DailyDoc({
    required this.day,
    required this.card,
    required this.quote,
    required this.question,
    required this.horoscopes,
  });

  final String day;
  final DailyCard card;
  final DailyQuote quote;
  final DailyQuestion question;
  final Map<ZodiacSign, ({String text, HoroscopeScores scores})> horoscopes;

  DailyHoroscope? horoscopeFor(ZodiacSign? sign) {
    if (sign == null) return null;
    final h = horoscopes[sign];
    return h == null ? null : DailyHoroscope(sign: sign, text: h.text, scores: h.scores);
  }

  Map<String, Object?> toJson() => {
    'day': day,
    'card': {
      'id': card.id,
      'number': card.number,
      'title': card.title,
      'meaning': card.meaning,
      'advice': card.advice,
    },
    'quote': {'text': quote.text, 'author': quote.author},
    'question': {'id': question.id, 'text': question.text},
    'horoscopes': {
      for (final e in horoscopes.entries)
        e.key.name: {
          'text': e.value.text,
          'love': e.value.scores.love,
          'work': e.value.scores.work,
          'energy': e.value.scores.energy,
        },
    },
  };

  /// Разбор документа из Firestore. Бросает [FormatException], если поля не те.
  factory DailyDoc.fromJson(Map<String, Object?> json) {
    T field<T>(Map<String, Object?> m, String key) {
      final v = m[key];
      if (v is T) return v;
      throw FormatException('daily: поле "$key" отсутствует или неверного типа');
    }

    Map<String, Object?> obj(Map<String, Object?> m, String key) =>
        Map<String, Object?>.from(field<Map<Object?, Object?>>(m, key));

    final card = obj(json, 'card');
    final quote = obj(json, 'quote');
    final question = obj(json, 'question');
    final rawHoroscopes = obj(json, 'horoscopes');

    final horoscopes = <ZodiacSign, ({String text, HoroscopeScores scores})>{};
    for (final sign in ZodiacSign.values) {
      final raw = rawHoroscopes[sign.name];
      if (raw is! Map) continue;
      final h = Map<String, Object?>.from(raw);
      horoscopes[sign] = (
        text: field<String>(h, 'text'),
        scores: HoroscopeScores(
          love: field<num>(h, 'love').toInt(),
          work: field<num>(h, 'work').toInt(),
          energy: field<num>(h, 'energy').toInt(),
        ),
      );
    }

    return DailyDoc(
      day: field<String>(json, 'day'),
      card: DailyCard(
        id: field<String>(card, 'id'),
        number: field<num>(card, 'number').toInt(),
        title: field<String>(card, 'title'),
        meaning: field<String>(card, 'meaning'),
        advice: field<String>(card, 'advice'),
      ),
      quote: DailyQuote(
        text: field<String>(quote, 'text'),
        author: (quote['author'] as String?) ?? 'Астра',
      ),
      question: DailyQuestion(
        id: field<String>(question, 'id'),
        text: field<String>(question, 'text'),
      ),
      horoscopes: horoscopes,
    );
  }
}

/// Детерминированный выбор контента на день из пулов: у всех пользователей
/// в один день одна и та же карта, цитата и вопрос.
class DailyBuilder {
  const DailyBuilder({
    required this.cards,
    required this.quotes,
    required this.questions,
    required this.horoscopeTexts,
  });

  final List<DailyCard> cards;
  final List<DailyQuote> quotes;
  final List<DailyQuestion> questions;
  final Map<ZodiacSign, List<String>> horoscopeTexts;

  DailyDoc build(DateTime date) {
    final seed = _daySeed(date);
    T pick<T>(List<T> list, int salt) => list[_mix(seed, salt) % list.length];

    return DailyDoc(
      day: dayKey(date),
      card: pick(cards, 1),
      quote: pick(quotes, 2),
      question: pick(questions, 3),
      horoscopes: {
        for (final sign in ZodiacSign.values)
          if (horoscopeTexts[sign] case final texts? when texts.isNotEmpty)
            sign: () {
              final s = _mix(seed, 100 + sign.index);
              return (
                text: texts[s % texts.length],
                scores: HoroscopeScores(
                  love: 2 + s % 4,
                  work: 2 + (s ~/ 4) % 4,
                  energy: 2 + (s ~/ 16) % 4,
                ),
              );
            }(),
      },
    );
  }

  static int _daySeed(DateTime d) => d.year * 1000 + d.month * 40 + d.day;

  /// Перемешивание (вариант хеша Кнута), чтобы соседние дни не давали
  /// соседние элементы списка.
  static int _mix(int seed, int salt) {
    var x = (seed * 2654435761 + salt * 40503) & 0x7fffffff;
    x ^= x >> 13;
    x = (x * 1274126177) & 0x7fffffff;
    return x ^ (x >> 16);
  }
}

/// Ключ дня в локальном времени: `yyyy-MM-dd`.
String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
