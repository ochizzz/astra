import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/services/preferences.dart';
import '../../core/user/user_profile.dart';
import '../today/data/today_repository.dart';
import 'widget_view.dart';

/// Виджет «Астры» на главном экране Android.
///
/// Flutter заранее рисует картинки на 7 дней вперёд (в двух размерах) и
/// кладёт их в «слоты» по дню недели: `astra_small_d1` … `astra_wide_d7`.
/// Нативный `AstraWidgetProvider` берёт слот сегодняшнего дня, проверив
/// дату. Обновление в полночь планируется через AlarmManager, поэтому виджет
/// меняется каждый день, даже если приложение не открывали неделю.
class HomeWidgetSync {
  HomeWidgetSync(this._ref);

  final Ref _ref;
  Timer? _debounce;

  static const androidName = 'AstraWidgetProvider';
  static const _days = 7;
  static const _pixelRatio = 2.5;
  static const _signatureKey = 'widget.signature';

  /// Версия картинки: увеличить при изменении дизайна, чтобы перерисовать.
  static const _designVersion = 1;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Отложенное обновление: не мешает анимациям при запуске и
  /// схлопывает несколько изменений подряд в одну перерисовку.
  void scheduleRefresh() {
    if (!_supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () => unawaited(refresh()));
  }

  bool _running = false;

  Future<void> refresh({bool force = false}) async {
    if (!_supported || _running) return;
    _running = true;
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final today = _ref.read(todayDateProvider);
      final sign = _ref.read(userProfileProvider).sign;
      final flipped = _ref.read(todayProgressProvider).cardFlipped;
      final signature = '$_designVersion|${dayKeyOf(today)}|${sign?.name}|$flipped';
      if (!force && prefs.getString(_signatureKey) == signature) return;

      final repo = _ref.read(todayRepositoryProvider);
      for (var i = 0; i < _days; i++) {
        final date = DateTime(today.year, today.month, today.day + i);
        final content = await repo.load(date, sign: sign);
        final snapshot = WidgetSnapshot(
          date: date,
          moon: content.moon,
          quote: content.quote.text,
          cardTitle: i == 0 && flipped ? content.card.title : null,
          sign: sign,
        );
        final slot = date.weekday;
        for (final variant in WidgetVariant.values) {
          await HomeWidget.renderFlutterWidget(
            AstraWidgetView(data: snapshot, variant: variant),
            key: 'astra_${variant.name}_d$slot',
            logicalSize: variant.size,
            pixelRatio: _pixelRatio,
          );
        }
        await HomeWidget.saveWidgetData<String>('astra_date_d$slot', dayKeyOf(date));
      }

      await HomeWidget.updateWidget(androidName: androidName);
      // Перерисовка в каждую из ближайших полуночей (+1 минута на всякий случай).
      await HomeWidget.scheduleWidgetUpdates([
        for (var i = 1; i <= _days; i++) DateTime(today.year, today.month, today.day + i, 0, 1),
      ], androidName: androidName);
      await prefs.setString(_signatureKey, signature);
    } catch (e, st) {
      debugPrint('[HomeWidget] не удалось обновить: $e\n$st');
    } finally {
      _running = false;
    }
  }
}

final homeWidgetSyncProvider = Provider<HomeWidgetSync>(HomeWidgetSync.new);
