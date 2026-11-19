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

    _ref.read(syncVersionProvider.notifier).bump();
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

  Future<void> saveAnswer(String day, String text) async {
    final user = _user;
    if (user == null) return;
    await _guard(
      () =>
          _userDoc(user.uid)
              .collection('answers')
              .doc(day)
              .set({'text': text, 'updatedAt': FieldValue.serverTimestamp()}),
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
