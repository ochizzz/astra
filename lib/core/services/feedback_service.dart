import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences.dart';

/// Настройки тактильной и звуковой отдачи.
class FeedbackSettings {
  const FeedbackSettings({required this.haptics, required this.sound});

  final bool haptics;
  final bool sound;
}

class FeedbackSettingsNotifier extends Notifier<FeedbackSettings> {
  @override
  FeedbackSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return FeedbackSettings(
      haptics: prefs.getBool(PrefKeys.hapticsEnabled) ?? true,
      // Звук по умолчанию выключен — включается в профиле.
      sound: prefs.getBool(PrefKeys.soundEnabled) ?? false,
    );
  }

  Future<void> setHaptics(bool value) async {
    state = FeedbackSettings(haptics: value, sound: state.sound);
    await ref.read(sharedPreferencesProvider).setBool(PrefKeys.hapticsEnabled, value);
  }

  Future<void> setSound(bool value) async {
    state = FeedbackSettings(haptics: state.haptics, sound: value);
    await ref.read(sharedPreferencesProvider).setBool(PrefKeys.soundEnabled, value);
  }
}

final feedbackSettingsProvider = NotifierProvider<FeedbackSettingsNotifier, FeedbackSettings>(
  FeedbackSettingsNotifier.new,
);

/// Единая точка для вибрации и звуков. Звуки пока системные;
/// в 1.1 заменим на собственные (assets/sounds) через audioplayers.
class AppFeedback {
  const AppFeedback(this._settings);

  final FeedbackSettings _settings;

  /// Лёгкое касание: переключение вкладки, выбор значения.
  void tap() {
    if (_settings.haptics) HapticFeedback.selectionClick();
  }

  /// Заметное событие: переворот карты, раскрытие знака.
  void reveal() {
    if (_settings.haptics) HapticFeedback.mediumImpact();
    if (_settings.sound) SystemSound.play(SystemSoundType.click);
  }

  /// Успех: сохранили ответ, завершили онбординг.
  void success() {
    if (_settings.haptics) HapticFeedback.lightImpact();
  }
}

final appFeedbackProvider = Provider<AppFeedback>(
  (ref) => AppFeedback(ref.watch(feedbackSettingsProvider)),
);
