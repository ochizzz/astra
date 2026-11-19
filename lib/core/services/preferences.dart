import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Локальное хранилище. Инициализируется в `main()` и подставляется через
/// `ProviderScope(overrides: [...])`, чтобы провайдеры читали его синхронно.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider in main()'),
);

/// Ключи локального хранилища — в одном месте, чтобы не было опечаток
/// и чтобы было понятно, что переносить в облако при входе в аккаунт.
abstract final class PrefKeys {
  static const birthDate = 'user.birthDate';
  static const userName = 'user.name';
  static const onboardingDone = 'user.onboardingDone';

  static const hapticsEnabled = 'settings.haptics';
  static const soundEnabled = 'settings.sound';
  static const notificationsEnabled = 'settings.notifications';

  /// Префикс ответов на вопрос дня — по нему ищем, что переносить в облако.
  static const questionAnswerPrefix = 'today.answer.';

  /// Карта дня уже открыта: `today.cardFlipped.2026-11-19`.
  static String cardFlipped(String dayKey) => 'today.cardFlipped.$dayKey';

  /// Ответ на вопрос дня: `today.answer.2026-11-19`.
  static String questionAnswer(String dayKey) => '$questionAnswerPrefix$dayKey';
}

/// Ключ дня в локальном времени: `yyyy-MM-dd`.
String dayKeyOf(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
