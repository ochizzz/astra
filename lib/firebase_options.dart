// ЗАГЛУШКА. Этот файл будет перезаписан командой:
//
//   flutterfire configure --project=astra-app-9a449 \
//     --platforms=android,ios --android-package-name=app.astra.mobile \
//     --ios-bundle-id=app.astra.mobile
//
// Пока здесь заглушка, приложение работает без Firebase (моковый контент,
// локальное хранение). Подробности — docs/FIREBASE_SETUP.md.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform =>
      throw UnsupportedError('Firebase ещё не настроен: запустите `flutterfire configure`.');
}
