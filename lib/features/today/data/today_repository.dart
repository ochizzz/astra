import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/moon_phase.dart';
import '../../../core/astro/zodiac.dart';
import '../../../core/services/preferences.dart';
import '../../../core/user/user_profile.dart';
import '../domain/today_models.dart';
import 'mock_content.dart';

/// Источник контента для вкладки «Сегодня».
abstract interface class TodayRepository {
  Future<TodayContent> load(DateTime date, {ZodiacSign? sign});
}

/// Детерминированный выбор контента по дате: у всех пользователей
/// в один день одна и та же карта, цитата и вопрос; гороскоп — по знаку.
/// Позже появится `FirestoreTodayRepository` с этим же интерфейсом,
/// а моковый останется запасным на случай отсутствия сети.
class MockTodayRepository implements TodayRepository {
  const MockTodayRepository();

  @override
  Future<TodayContent> load(DateTime date, {ZodiacSign? sign}) async {
    final seed = _daySeed(date);
    T pick<T>(List<T> list, int salt) => list[_mix(seed, salt) % list.length];

    DailyHoroscope? horoscope;
    if (sign != null) {
      final texts = mockHoroscopes[sign]!;
      final s = _mix(seed, 100 + sign.index);
      horoscope = DailyHoroscope(
        sign: sign,
        text: texts[s % texts.length],
        scores: HoroscopeScores(love: 2 + s % 4, work: 2 + (s ~/ 4) % 4, energy: 2 + (s ~/ 16) % 4),
      );
    }

    return TodayContent(
      date: date,
      card: pick(mockCards, 1),
      quote: pick(mockQuotes, 2),
      question: pick(mockQuestions, 3),
      horoscope: horoscope,
      // Полдень — чтобы фаза была «дневной», а не зависела от минуты открытия.
      moon: MoonPhase.at(DateTime(date.year, date.month, date.day, 12)),
    );
  }

  static int _daySeed(DateTime d) => d.year * 1000 + d.month * 40 + d.day;

  /// Простое перемешивание (вариант хеша Кнута), чтобы соседние дни
  /// не давали соседние элементы списка.
  static int _mix(int seed, int salt) {
    var x = (seed * 2654435761 + salt * 40503) & 0x7fffffff;
    x ^= x >> 13;
    x = (x * 1274126177) & 0x7fffffff;
    return x ^ (x >> 16);
  }
}

final todayRepositoryProvider = Provider<TodayRepository>((ref) => const MockTodayRepository());

/// Текущая дата (без времени). Вынесено в провайдер, чтобы в тестах
/// можно было подставить любой день.
final todayDateProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final todayContentProvider = FutureProvider<TodayContent>((ref) {
  final date = ref.watch(todayDateProvider);
  final sign = ref.watch(userProfileProvider.select((p) => p.sign));
  return ref.watch(todayRepositoryProvider).load(date, sign: sign);
});

/// Состояние интерактива дня: открыта ли карта и ответ на вопрос.
class TodayProgress {
  const TodayProgress({required this.cardFlipped, this.answer});

  final bool cardFlipped;
  final String? answer;
}

class TodayProgressNotifier extends Notifier<TodayProgress> {
  String get _day => dayKeyOf(ref.read(todayDateProvider));

  @override
  TodayProgress build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final day = dayKeyOf(ref.watch(todayDateProvider));
    return TodayProgress(
      cardFlipped: prefs.getBool(PrefKeys.cardFlipped(day)) ?? false,
      answer: prefs.getString(PrefKeys.questionAnswer(day)),
    );
  }

  Future<void> flipCard() async {
    state = TodayProgress(cardFlipped: true, answer: state.answer);
    await ref.read(sharedPreferencesProvider).setBool(PrefKeys.cardFlipped(_day), true);
  }

  /// Ответ сохраняется локально; дневник (MVP) читает его по ключу дня.
  Future<void> saveAnswer(String answer) async {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return;
    state = TodayProgress(cardFlipped: state.cardFlipped, answer: trimmed);
    await ref.read(sharedPreferencesProvider).setString(PrefKeys.questionAnswer(_day), trimmed);
  }
}

final todayProgressProvider = NotifierProvider<TodayProgressNotifier, TodayProgress>(
  TodayProgressNotifier.new,
);
