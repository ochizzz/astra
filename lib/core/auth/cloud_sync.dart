import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_bootstrap.dart';
import '../services/preferences.dart';
import '../user/user_profile.dart';

/// Синхронизация личных данных с Firestore.
///
/// Гость пользуется приложением локально. При входе [onSignedIn] переносит
/// данные с устройства в `users/{uid}`, а если в аккаунте уже есть данные
/// (вход на новом телефоне) — подтягивает их на устройство.
/// Все методы безопасны без Firebase и без входа: тогда это no-op.
class CloudSync {
  CloudSync(this._ref);

  final Ref _ref;

  bool get _ready => _ref.read(isFirebaseReadyProvider);
  User? get _user => _ready ? FirebaseAuth.instance.currentUser : null;
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      FirebaseFirestore.instance.doc('users/$uid');

  Future<void> onSignedIn(User user) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final doc = _userDoc(user.uid);
    final remote = (await doc.get()).data() ?? const {};

    // 1. Дата рождения: аккаунт главнее устройства.
    final remoteBirth = DateTime.tryParse(remote['birthDate'] as String? ?? '');
    final local = _ref.read(userProfileProvider);
    if (remoteBirth != null) {
      await _ref.read(userProfileProvider.notifier).setBirthDate(remoteBirth, sync: false);
    } else if (local.birthDate != null) {
      await saveProfile(local);
    }

    // 2. Ответы на вопрос дня: локальные → в облако.
    final answers = doc.collection('answers');
    final keys = prefs.getKeys().where((k) => k.startsWith(PrefKeys.questionAnswerPrefix)).toList();
    for (var i = 0; i < keys.length; i += 400) {
      final batch = FirebaseFirestore.instance.batch();
      for (final key in keys.skip(i).take(400)) {
        final day = key.substring(PrefKeys.questionAnswerPrefix.length);
        batch.set(answers.doc(day), {
          'text': prefs.getString(key),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }

    // 3. Облачные ответы, которых нет на устройстве, — на устройство.
    final remoteAnswers = await answers
        .orderBy(FieldPath.documentId, descending: true)
        .limit(366)
        .get();
    for (final d in remoteAnswers.docs) {
      final key = PrefKeys.questionAnswer(d.id);
      final text = d.data()['text'];
      if (!prefs.containsKey(key) && text is String) await prefs.setString(key, text);
    }

    // 4. Дневник: объединяем по id, побеждает более поздняя правка.
    await _mergeDiary(doc.collection('diary'));

    // 5. Результаты тестов: локальные → в облако, облачные → на устройство.
    final results = doc.collection('testResults');
    for (final key in prefs.getKeys().where((k) => k.startsWith('tests.result.'))) {
      final testId = key.substring('tests.result.'.length);
      await results.doc(testId).set({'result': prefs.getString(key)}, SetOptions(merge: true));
    }
    for (final d in (await results.get()).docs) {
      final r = d.data()['result'];
      if (r is String) await prefs.setString(PrefKeys.testResult(d.id), r);
    }

    _ref.read(syncVersionProvider.notifier).bump();
  }

  Future<void> _mergeDiary(CollectionReference<Map<String, dynamic>> remote) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final local = <String, Map<String, Object?>>{
      for (final e in _decodeList(prefs.getString(PrefKeys.diaryEntries)))
        if (e['id'] is String) e['id']! as String: e,
    };
    final remoteDocs = await remote.get();
    final merged = Map.of(local);
    for (final d in remoteDocs.docs) {
      final r = Map<String, Object?>.from(d.data());
      final l = local[d.id];
      if (l == null || _newer(r, l)) merged[d.id] = r;
    }
    // Локальные записи, которые остались «победителями», — в облако.
    for (final e in local.values) {
      if (identical(merged[e['id']], e)) await remote.doc(e['id']! as String).set(e);
    }
    await prefs.setString(PrefKeys.diaryEntries, jsonEncode(merged.values.toList()));
  }

  static bool _newer(Map<String, Object?> a, Map<String, Object?> b) =>
      (a['updatedAt'] as String? ?? '').compareTo(b['updatedAt'] as String? ?? '') > 0;

  static List<Map<String, Object?>> _decodeList(String? raw) {
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<Object?, Object?>>()
          .map(Map<String, Object?>.from)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final user = _user;
    if (user == null || profile.birthDate == null) return;
    await _guard(
      () => _userDoc(user.uid).set({
        'birthDate': dayKeyOf(profile.birthDate!),
        'sign': profile.sign?.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  Future<void> saveAnswer(String day, String text, {String? question}) async {
    final user = _user;
    if (user == null) return;
    await _guard(
      () => _userDoc(user.uid)
          .collection('answers')
          .doc(day)
          .set({'text': text, 'question': ?question, 'updatedAt': FieldValue.serverTimestamp()}),
    );
  }

  /// Запись дневника (JSON из `DiaryEntry.toJson`).
  Future<void> saveDiaryEntry(Map<String, Object?> entry) async {
    final user = _user;
    if (user == null) return;
    await _guard(
      () => _userDoc(user.uid).collection('diary').doc(entry['id']! as String).set(entry),
    );
  }

  Future<void> deleteDiaryEntry(String id) async {
    final user = _user;
    if (user == null) return;
    await _guard(() => _userDoc(user.uid).collection('diary').doc(id).delete());
  }

  Future<void> saveTestResult(String testId, String resultId) async {
    final user = _user;
    if (user == null) return;
    await _guard(
      () =>
          _userDoc(user.uid)
              .collection('testResults')
              .doc(testId)
              .set({'result': resultId, 'updatedAt': FieldValue.serverTimestamp()}),
    );
  }

  /// Сохраняет ID установки (FCM) для персональных пушей.
  Future<void> savePushId(String id) async {
    final user = _user;
    if (user == null) return;
    await _guard(
      () => _userDoc(user.uid).set({
        'pushIds': FieldValue.arrayUnion([id]),
      }, SetOptions(merge: true)),
    );
  }

  /// Удаляет все личные данные пользователя из Firestore (вызывается перед
  /// удалением аккаунта; работает и на бесплатном тарифе без Cloud Functions).
  Future<void> deleteAllUserData(String uid) async {
    final doc = _userDoc(uid);
    for (final sub in const ['answers', 'diary', 'testResults']) {
      while (true) {
        final page = await doc.collection(sub).limit(400).get();
        if (page.docs.isEmpty) break;
        final batch = FirebaseFirestore.instance.batch();
        for (final d in page.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
    await doc.delete();
  }

  /// Ошибки синхронизации не должны мешать пользователю: Firestore
  /// сам повторит запись, когда появится сеть.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[CloudSync] $e');
    }
  }
}

final cloudSyncProvider = Provider<CloudSync>(CloudSync.new);

/// Увеличивается после синхронизации — экраны, читающие локальные данные,
/// подписываются на него, чтобы перечитать их.
class SyncVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final syncVersionProvider = NotifierProvider<SyncVersion, int>(SyncVersion.new);
