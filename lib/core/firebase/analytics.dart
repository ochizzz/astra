import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_bootstrap.dart';

/// Тонкая обёртка над аналитикой: без Firebase все вызовы — no-op.
/// Названия событий собраны здесь, чтобы их было легко перечислить
/// в форме Data Safety и в политике конфиденциальности.
class AppAnalytics {
  const AppAnalytics(this._analytics);

  final FirebaseAnalytics? _analytics;

  void onboardingCompleted({required String sign}) => _log('onboarding_completed', {'sign': sign});

  void dailyCardFlipped({required String cardId}) =>
      _log('daily_card_flipped', {'card_id': cardId});

  void questionAnswered() => _log('question_answered');

  void shared({required String contentType}) => _log('share', {'content_type': contentType});

  void signInPromptShown({required String source}) =>
      _log('sign_in_prompt_shown', {'source': source});

  void _log(String name, [Map<String, Object>? params]) => unawaited(_send(name, params));

  Future<void> _send(String name, Map<String, Object>? params) async {
    try {
      await _analytics?.logEvent(name: name, parameters: params);
    } catch (_) {
      // Аналитика никогда не должна ломать пользовательский сценарий.
    }
  }
}

final analyticsProvider = Provider<AppAnalytics>((ref) {
  final ready = ref.watch(isFirebaseReadyProvider);
  return AppAnalytics(ready ? FirebaseAnalytics.instance : null);
});
