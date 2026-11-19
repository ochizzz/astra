// Сгенерировано tool/gen_firebase_options.dart — не редактируйте вручную.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.android => android,
    _ => throw UnsupportedError('Firebase не настроен для этой платформы'),
  };

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDHpfqz0zgY10zLo-6ZHuKBTMVKdl6NV90',
    appId: '1:414498966999:android:8038ce56d7a0c72466cf92',
    messagingSenderId: '414498966999',
    projectId: 'astra-app-9a449',
    storageBucket: 'astra-app-9a449.firebasestorage.app',
  );
}
