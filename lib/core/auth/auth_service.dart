import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase/analytics.dart';
import '../firebase/firebase_bootstrap.dart';
import '../user/user_profile.dart';
import 'cloud_sync.dart';

/// Текущий пользователь Firebase. `null` — гость (или Firebase не настроен).
final authUserProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(isFirebaseReadyProvider)) return Stream.value(null);
  return FirebaseAuth.instance.userChanges();
});

enum AuthResult { success, canceled, unavailable, failed }

class AuthService {
  AuthService(this._ref);

  final Ref _ref;
  static Future<void>? _googleInit;

  /// Текущая попытка входа: повторный вызов получает тот же результат,
  /// а не открывает второе окно выбора аккаунта.
  static Future<AuthResult>? _signingIn;

  bool get isAvailable => _ref.read(isFirebaseReadyProvider);

  Future<void> _ensureGoogle() => _googleInit ??= GoogleSignIn.instance.initialize();

  Future<AuthCredential?> _googleCredential() async {
    await _ensureGoogle();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) return null;
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  /// Вход через Google. Данные гостя переносятся в аккаунт.
  Future<AuthResult> signInWithGoogle({required String source}) {
    if (!isAvailable) return Future.value(AuthResult.unavailable);
    return _signingIn ??= _signIn(source).whenComplete(() => _signingIn = null);
  }

  Future<AuthResult> _signIn(String source) async {
    try {
      final credential = await _googleCredential();
      if (credential == null) return AuthResult.failed;
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      await _ref.read(cloudSyncProvider).onSignedIn(result.user!);
      _ref.read(analyticsProvider).login(method: 'google', source: source);
      return AuthResult.success;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return AuthResult.canceled;
      debugPrint('[Auth] Google: $e');
      return AuthResult.failed;
    } catch (e) {
      debugPrint('[Auth] $e');
      return AuthResult.failed;
    }
  }

  /// Выход. Локальные данные остаются на устройстве как у гостя.
  Future<void> signOut() async {
    if (!isAvailable) return;
    await FirebaseAuth.instance.signOut();
    try {
      await _ensureGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  /// Полное удаление аккаунта и всех данных в облаке и на устройстве.
  /// Требование Google Play и App Store.
  Future<AuthResult> deleteAccount() async {
    final user = isAvailable ? FirebaseAuth.instance.currentUser : null;
    if (user == null) return AuthResult.unavailable;
    try {
      await _ref.read(cloudSyncProvider).deleteAllUserData(user.uid);
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        // Firebase просит недавний вход — подтверждаем через Google.
        final credential = await _googleCredential();
        if (credential == null) return AuthResult.failed;
        await user.reauthenticateWithCredential(credential);
        await user.delete();
      }
      await signOut();
      await _ref.read(userProfileProvider.notifier).reset();
      return AuthResult.success;
    } on GoogleSignInException catch (e) {
      return e.code == GoogleSignInExceptionCode.canceled ? AuthResult.canceled : AuthResult.failed;
    } catch (e) {
      debugPrint('[Auth] удаление: $e');
      return AuthResult.failed;
    }
  }
}

final authServiceProvider = Provider<AuthService>(AuthService.new);
