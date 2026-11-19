// Создаёт lib/firebase_options.dart из конфигов, скачанных в консоли Firebase.
// Нужен, если не хочется ставить flutterfire CLI.
//
//   dart run tool/gen_firebase_options.dart
//
// Читает: android/app/google-services.json (обязательно)
//         ios/Runner/GoogleService-Info.plist (если есть)
import 'dart:convert';
import 'dart:io';

const packageName = 'app.astra.mobile';

void main() {
  final androidFile = File('android/app/google-services.json');
  if (!androidFile.existsSync()) {
    stderr.writeln('Нет ${androidFile.path}. Скачайте его в консоли Firebase.');
    exit(1);
  }
  final json = jsonDecode(androidFile.readAsStringSync()) as Map<String, dynamic>;
  final project = json['project_info'] as Map<String, dynamic>;
  final clients = (json['client'] as List).cast<Map<String, dynamic>>();
  final client = clients.firstWhere(
    (c) => c['client_info']['android_client_info']['package_name'] == packageName,
    orElse: () => throw StateError('В google-services.json нет приложения $packageName'),
  );
  final android = {
    'apiKey': (client['api_key'] as List).first['current_key'],
    'appId': client['client_info']['mobilesdk_app_id'],
    'messagingSenderId': project['project_number'],
    'projectId': project['project_id'],
    'storageBucket': project['storage_bucket'],
  };
  final hasWebClient = (client['oauth_client'] as List? ?? const []).any(
    (c) => c['client_type'] == 3,
  );
  if (!hasWebClient) {
    stderr.writeln(
      '⚠ В google-services.json нет OAuth-клиента. Включите вход через Google в '
      'Authentication и скачайте файл заново — иначе вход не заработает.',
    );
  }

  Map<String, String>? ios;
  final plist = File('ios/Runner/GoogleService-Info.plist');
  if (plist.existsSync()) {
    final text = plist.readAsStringSync();
    String? key(String k) =>
        RegExp('<key>$k</key>\\s*<string>([^<]*)</string>').firstMatch(text)?.group(1);
    ios = {
      'apiKey': key('API_KEY')!,
      'appId': key('GOOGLE_APP_ID')!,
      'messagingSenderId': key('GCM_SENDER_ID')!,
      'projectId': key('PROJECT_ID')!,
      'storageBucket': key('STORAGE_BUCKET') ?? '',
      if (key('CLIENT_ID') != null) 'iosClientId': key('CLIENT_ID')!,
      'iosBundleId': key('BUNDLE_ID') ?? packageName,
    };
  }

  String options(Map<String, Object?> m) => [
    'FirebaseOptions(',
    for (final e in m.entries) "    ${e.key}: '${e.value}',",
    '  )',
  ].join('\n');

  final out = StringBuffer()
    ..writeln('// Сгенерировано tool/gen_firebase_options.dart — не редактируйте вручную.')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln("import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;")
    ..writeln(
      "import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;",
    )
    ..writeln()
    ..writeln('class DefaultFirebaseOptions {')
    ..writeln('  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {')
    ..writeln('    TargetPlatform.android => android,')
    ..write(ios != null ? '    TargetPlatform.iOS => ios,\n' : '')
    ..writeln("    _ => throw UnsupportedError('Firebase не настроен для этой платформы'),")
    ..writeln('  };')
    ..writeln()
    ..writeln('  static const android = ${options(android)};')
    ..write(ios != null ? '\n  static const ios = ${options(ios)};\n' : '')
    ..writeln('}');
  File('lib/firebase_options.dart').writeAsStringSync(out.toString());
  stdout.writeln('✦ lib/firebase_options.dart создан (проект ${android['projectId']})');
}
