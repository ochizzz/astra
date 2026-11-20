import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/moon_phase.dart';
import '../../../core/astro/zodiac.dart';
import '../../../core/auth/cloud_sync.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/services/preferences.dart';
import '../../../core/user/user_profile.dart';
import '../domain/daily_builder.dart';
import '../domain/today_models.dart';
import 'mock_content.dart';

/// Источник контента для вкладки «Сегодня».
abstract interface class TodayRepository {
  Future<TodayContent> load(DateTime date, {ZodiacSign? sign});
}

TodayContent _toContent(DateTime date, DailyDoc doc, ZodiacSign? sign) => TodayContent(
  date: date,
  card: doc.card,
  quote: doc.quote,
  question: doc.question,
  horoscope: doc.horoscopeFor(sign),
  // Полдень — чтобы фаза была «дневной», а не зависела от минуты открытия.
  moon: MoonPhase.at(DateTime(date.year, date.month, date.day, 12)),
);

/// Офлайн-источник: собирает день из встроенного контента.
class MockTodayRepository implements TodayRepository {
  const MockTodayRepository();

  @override
  Future<TodayContent> load(DateTime date, {ZodiacSign? sign}) async =>
      _toContent(date, mockDailyBuilder.build(date), sign);
}

/// Контент из Firestore: один документ `daily/{yyyy-MM-dd}` на день.
/// Firestore кэширует документ на устройстве, поэтому повторные открытия
/// работают офлайн. Если документа нет или сеть недоступна — встроенный контент.
class FirestoreTodayRepository implements TodayRepository {
  FirestoreTodayRepository(this._db, {this.fallback = const MockTodayRepository()});

  final FirebaseFirestore _db;
  final TodayRepository fallback;

  @override
  Future<TodayContent> load(DateTime date, {ZodiacSign? sign}) async {
    try {
      final snap = await _db.doc('daily/${dayKey(date)}').get().timeout(const Duration(seconds: 5));
      final data = snap.data();
      if (data == null) return await fallback.load(date, sign: sign);
      return _toContent(date, DailyDoc.fromJson(data), sign);
    } catch (e) {
      debugPrint('[Today] Firestore недоступен, берём встроенный контент: $e');
      return fallback.load(date, sign: sign);
    }
  }
}

final todayRepositoryProvider = Provider<TodayRepository>(
  (ref) => ref.watch(isFirebaseReadyProvider)
      ? FirestoreTodayRepository(FirebaseFirestore.instance)
      : const MockTodayRepository(),
);

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
    ref.watch(syncVersionProvider); // перечитать после синхронизации с облаком
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

  /// Ответ сохраняется локально и, если пользователь вошёл, — в облако.
  Future<void> saveAnswer(String answer, {String? question}) async {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return;
    state = TodayProgress(cardFlipped: state.cardFlipped, answer: trimmed);
    await ref.read(sharedPreferencesProvider).setString(PrefKeys.questionAnswer(_day), trimmed);
    if (question != null) {
      await ref.read(sharedPreferencesProvider).setString(PrefKeys.questionText(_day), question);
    }
    await ref.read(cloudSyncProvider).saveAnswer(_day, trimmed, question: question);
  }
}

final todayProgressProvider = NotifierProvider<TodayProgressNotifier, TodayProgress>(
  TodayProgressNotifier.new,
);
