import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/cloud_sync.dart';
import '../services/preferences.dart';
import 'firebase_bootstrap.dart';

/// Push-уведомления.
///
/// Разрешение спрашиваем только когда человек сам включает уведомления
/// в профиле — никаких системных окон при запуске.
/// - Тема `daily` — общий «гороскоп дня готов», работает и для гостей.
/// - Токен устройства сохраняется в аккаунт для личных пушей (1.1).
class PushNotifier extends Notifier<bool> {
  static const dailyTopic = 'daily';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(PrefKeys.notificationsEnabled) ?? false;

  bool get available => ref.read(isFirebaseReadyProvider);

  /// Идёт включение/выключение — быстрые переключения не запускают
  /// параллельные запросы разрешения и подписки.
  bool _busy = false;

  /// Возвращает false, если пользователь не дал разрешение.
  Future<bool> enable() async {
    if (!available || _busy) return false;
    _busy = true;
    try {
      return await _enable();
    } finally {
      _busy = false;
    }
  }

  Future<bool> _enable() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return false;

    try {
      await messaging.subscribeToTopic(dailyTopic);
      // ID установки (FID) для адресных пушей приходит в onRegistered.
      final registered = messaging.onRegistered.first.timeout(const Duration(seconds: 15));
      await messaging.register();
      await ref.read(cloudSyncProvider).savePushId(await registered);
    } catch (e) {
      debugPrint('[Push] $e');
    }
    await ref.read(sharedPreferencesProvider).setBool(PrefKeys.notificationsEnabled, true);
    state = true;
    return true;
  }

  Future<void> disable() async {
    if (_busy) return;
    _busy = true;
    try {
      await _disable();
    } finally {
      _busy = false;
    }
  }

  Future<void> _disable() async {
    if (available) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(dailyTopic);
        await FirebaseMessaging.instance.unregister();
      } catch (e) {
        debugPrint('[Push] $e');
      }
    }
    await ref.read(sharedPreferencesProvider).setBool(PrefKeys.notificationsEnabled, false);
    state = false;
  }
}

final pushProvider = NotifierProvider<PushNotifier, bool>(PushNotifier.new);
