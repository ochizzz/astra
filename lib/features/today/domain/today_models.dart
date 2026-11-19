import '../../../core/astro/moon_phase.dart';
import '../../../core/astro/zodiac.dart';

/// Карта дня из собственной колоды «Звёздные карты».
class DailyCard {
  const DailyCard({
    required this.id,
    required this.number,
    required this.title,
    required this.meaning,
    required this.advice,
  });

  final String id;

  /// Порядковый номер в колоде — отображается римской цифрой и задаёт эмблему.
  final int number;
  final String title;
  final String meaning;
  final String advice;
}

class DailyQuote {
  const DailyQuote({required this.text, this.author = 'Астра'});

  final String text;
  final String author;
}

/// Короткий прогноз по сферам, 1..5.
class HoroscopeScores {
  const HoroscopeScores({required this.love, required this.work, required this.energy});

  final int love;
  final int work;
  final int energy;
}

class DailyHoroscope {
  const DailyHoroscope({required this.sign, required this.text, required this.scores});

  final ZodiacSign sign;
  final String text;
  final HoroscopeScores scores;
}

class DailyQuestion {
  const DailyQuestion({required this.id, required this.text});

  final String id;
  final String text;
}

/// Всё содержимое вкладки «Сегодня» на конкретный день.
class TodayContent {
  const TodayContent({
    required this.date,
    required this.card,
    required this.quote,
    required this.horoscope,
    required this.question,
    required this.moon,
  });

  final DateTime date;
  final DailyCard card;
  final DailyQuote quote;

  /// Общий гороскоп по знаку. null — если дата рождения ещё не указана.
  final DailyHoroscope? horoscope;
  final DailyQuestion question;
  final MoonPhase moon;
}
