import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'auth_service.dart';

/// Вход через Google с понятными сообщениями. Возвращает true при успехе.
Future<bool> signInWithGoogleUi(
  BuildContext context,
  WidgetRef ref, {
  required String source,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref.read(authServiceProvider).signInWithGoogle(source: source);
  final message = switch (result) {
    AuthResult.success => 'Готово! Теперь твои данные хранятся в аккаунте ✦',
    AuthResult.canceled => null,
    AuthResult.unavailable => 'Вход станет доступен после подключения Firebase',
    AuthResult.failed => 'Не получилось войти. Проверь интернет и попробуй ещё раз',
  };
  if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
  return result == AuthResult.success;
}
