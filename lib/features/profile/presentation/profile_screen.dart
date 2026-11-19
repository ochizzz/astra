import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/sign_in_ui.dart';
import '../../../core/firebase/push_service.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/user/user_profile.dart';
import '../../../core/widgets/astra_buttons.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/tab_page.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final feedback = ref.watch(feedbackSettingsProvider);
    final user = ref.watch(authUserProvider).value;
    final pushEnabled = ref.watch(pushProvider);
    final text = Theme.of(context).textTheme;
    final sign = profile.sign;

    return TabPage(
      overline: user == null ? 'Гостевой режим' : (user.displayName ?? 'Аккаунт'),
      title: 'Профиль',
      children: [
        GlassCard(
          glow: true,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 0.8),
                ),
                child: Text(
                  sign?.textGlyph ?? '✦',
                  style: const TextStyle(color: AppColors.gold, fontSize: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sign?.title ?? 'Знак не выбран', style: text.headlineSmall),
                    if (profile.birthDate != null)
                      Text(
                        DateFormat('d MMMM y', 'ru').format(profile.birthDate!),
                        style: text.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Аккаунт'),
              const SizedBox(height: 12),
              if (user == null) ...[
                Text(
                  'Войди, чтобы сохранить дневник в облаке, указать время и место '
                  'рождения и получать личные гороскопы.',
                  style: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                GhostButton(
                  label: 'Войти через Google',
                  icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () => signInWithGoogleUi(context, ref, source: 'profile'),
                ),
              ] else ...[
                Text(user.email ?? user.displayName ?? 'Вход выполнен', style: text.titleMedium),
                const SizedBox(height: 4),
                Text('Дата рождения и ответы синхронизируются с аккаунтом.', style: text.bodySmall),
                const SizedBox(height: 8),
                SoftLink(label: 'Выйти', onTap: () => ref.read(authServiceProvider).signOut()),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              SwitchListTile(
                value: pushEnabled,
                onChanged: (on) => _togglePush(context, ref, on),
                title: const Text('Уведомления'),
                subtitle: Text('Гороскоп дня и лунные события', style: text.bodySmall),
              ),
              SwitchListTile(
                value: feedback.haptics,
                onChanged: ref.read(feedbackSettingsProvider.notifier).setHaptics,
                title: const Text('Вибрация'),
              ),
              SwitchListTile(
                value: feedback.sound,
                onChanged: ref.read(feedbackSettingsProvider.notifier).setSound,
                title: const Text('Звуки'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Приватность'),
              const SizedBox(height: 12),
              Text(
                user == null
                    ? 'Пока ты в гостевом режиме, все данные хранятся только на этом '
                          'устройстве.'
                    : 'Удаление аккаунта сотрёт все твои данные в облаке и на '
                          'устройстве без возможности восстановления.',
                style: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              SoftLink(
                label: user == null ? 'Удалить мои данные с устройства' : 'Удалить аккаунт',
                onTap: () =>
                    user == null ? _confirmReset(context, ref) : _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepViolet,
        title: const Text('Удалить данные?'),
        content: const Text(
          'Дата рождения и настройки будут удалены, и ты снова увидишь знакомство.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(userProfileProvider.notifier).reset();
    if (context.mounted) context.go(Routes.onboarding);
  }

  Future<void> _togglePush(BuildContext context, WidgetRef ref, bool on) async {
    final push = ref.read(pushProvider.notifier);
    if (!on) return push.disable();
    final messenger = ScaffoldMessenger.of(context);
    if (!push.available) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Уведомления заработают после подключения Firebase')),
      );
      return;
    }
    final ok = await push.enable();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Разреши уведомления в настройках телефона')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepViolet,
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Аккаунт, дата рождения, ответы и записи дневника будут удалены '
          'навсегда. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(authServiceProvider).deleteAccount();
    if (result == AuthResult.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Аккаунт и данные удалены')));
      if (context.mounted) context.go(Routes.onboarding);
    } else if (result == AuthResult.failed) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось удалить аккаунт. Попробуй ещё раз')),
      );
    }
  }
}
