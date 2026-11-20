import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/cloud_sync.dart';
import '../../../core/services/preferences.dart';
import '../domain/test_models.dart';
import 'tests_content.dart';

/// Каталог тестов. Пока встроенный; позже — из Firestore `content/tests`.
final testsProvider = Provider<List<AstraTest>>((ref) => astraTests);

AstraTest? testById(String? id) => astraTests.where((t) => t.id == id).firstOrNull;

/// Пройденные тесты: id теста → id результата.
class TestResultsNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    ref.watch(syncVersionProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    return {for (final t in astraTests) t.id: ?prefs.getString(PrefKeys.testResult(t.id))};
  }

  Future<void> save(String testId, String resultId) async {
    state = {...state, testId: resultId};
    await ref.read(sharedPreferencesProvider).setString(PrefKeys.testResult(testId), resultId);
    await ref.read(cloudSyncProvider).saveTestResult(testId, resultId);
  }
}

final testResultsProvider = NotifierProvider<TestResultsNotifier, Map<String, String>>(
  TestResultsNotifier.new,
);
