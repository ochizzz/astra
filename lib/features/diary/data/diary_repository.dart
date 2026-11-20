import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/cloud_sync.dart';
import '../../../core/services/preferences.dart';
import '../../today/data/today_repository.dart';
import '../domain/diary_models.dart';

/// Записи дневника. Хранятся на устройстве (JSON в SharedPreferences —
/// для сотен записей этого достаточно; при росте перейдём на SQLite/drift),
/// у вошедшего пользователя дублируются в `users/{uid}/diary`.
class DiaryNotifier extends Notifier<List<DiaryEntry>> {
  @override
  List<DiaryEntry> build() {
    ref.watch(syncVersionProvider); // перечитать после синхронизации
    final raw = ref.watch(sharedPreferencesProvider).getString(PrefKeys.diaryEntries);
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as List)
          .whereType<Map<Object?, Object?>>()
          .map((m) => DiaryEntry.fromJson(Map<String, Object?>.from(m)))
          .whereType<DiaryEntry>()
          .toList();
      return _sorted(list);
    } catch (_) {
      return const [];
    }
  }

  static List<DiaryEntry> _sorted(List<DiaryEntry> list) => list
    ..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.updatedAt.compareTo(a.updatedAt);
    });

  Future<void> _persist(List<DiaryEntry> list) async {
    state = _sorted(List.of(list));
    await ref
        .read(sharedPreferencesProvider)
        .setString(PrefKeys.diaryEntries, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<DiaryEntry> save({
    String? id,
    required DateTime date,
    required String text,
    Mood? mood,
  }) async {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final existing = id == null ? null : state.where((e) => e.id == id).firstOrNull;
    final entry = existing == null
        ? DiaryEntry(
            id: '${now.microsecondsSinceEpoch}',
            date: day,
            text: text.trim(),
            mood: mood,
            updatedAt: now,
          )
        : DiaryEntry(id: existing.id, date: day, text: text.trim(), mood: mood, updatedAt: now);
    await _persist([...state.where((e) => e.id != entry.id), entry]);
    await ref.read(cloudSyncProvider).saveDiaryEntry(entry.toJson());
    return entry;
  }

  Future<void> delete(String id) async {
    await _persist(state.where((e) => e.id != id).toList());
    await ref.read(cloudSyncProvider).deleteDiaryEntry(id);
  }
}

final diaryProvider = NotifierProvider<DiaryNotifier, List<DiaryEntry>>(DiaryNotifier.new);

/// Ответы на вопрос дня из локального хранилища, новые сверху.
final questionAnswersProvider = Provider<List<QuestionAnswer>>((ref) {
  ref.watch(syncVersionProvider);
  ref.watch(diaryProvider); // обновлять ленту вместе с дневником
  ref.watch(todayProgressProvider); // и после ответа на вопрос дня
  final prefs = ref.watch(sharedPreferencesProvider);
  final result = <QuestionAnswer>[];
  for (final key in prefs.getKeys()) {
    if (!key.startsWith(PrefKeys.questionAnswerPrefix)) continue;
    final day = key.substring(PrefKeys.questionAnswerPrefix.length);
    final date = DateTime.tryParse(day);
    final answer = prefs.getString(key);
    if (date == null || answer == null) continue;
    result.add(
      QuestionAnswer(
        date: date,
        answer: answer,
        question: prefs.getString(PrefKeys.questionText(day)),
      ),
    );
  }
  return result..sort((a, b) => b.date.compareTo(a.date));
});
