import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

enum FirebaseStatus {
  /// Firebase подключён и инициализирован.
  ready,

  /// `firebase_options.dart` — заглушка: работаем офлайн на моках.
  notConfigured,

  /// Конфигурация есть, но инициализация упала (например, нет Play Services).
  failed,
}

abstract final class FirebaseBootstrap {
  /// Пытается поднять Firebase. Никогда не бросает исключение —
  /// приложение должно запускаться в любом случае.
  static Future<FirebaseStatus> initialize() async {
    final FirebaseOptions options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError {
      debugPrint('[Firebase] не настроен — работаем на моковых данных');
      return FirebaseStatus.notConfigured;
    }

    try {
      await Firebase.initializeApp(options: options);
      await _setupCrashlytics();
      return FirebaseStatus.ready;
    } catch (e, st) {
      debugPrint('[Firebase] ошибка инициализации: $e\n$st');
      return FirebaseStatus.failed;
    }
  }

  static Future<void> _setupCrashlytics() async {
    final crashlytics = FirebaseCrashlytics.instance;
    // В debug не засоряем отчёты.
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }
}

/// Подставляется в `main()` результатом [FirebaseBootstrap.initialize].
/// Фичи смотрят на него, чтобы выбрать Firestore- или мок-репозиторий.
final firebaseStatusProvider = Provider<FirebaseStatus>((ref) => FirebaseStatus.notConfigured);

final isFirebaseReadyProvider = Provider<bool>(
  (ref) => ref.watch(firebaseStatusProvider) == FirebaseStatus.ready,
);
