import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../astro/zodiac.dart';
import '../services/preferences.dart';

/// Профиль на устройстве. У гостя хранится локально; при входе в аккаунт
/// переносится в Firestore (`users/{uid}`).
class UserProfile {
  const UserProfile({this.birthDate, this.name, this.onboardingDone = false});

  final DateTime? birthDate;
  final String? name;
  final bool onboardingDone;

  ZodiacSign? get sign => birthDate == null ? null : ZodiacSign.fromDate(birthDate!);

  UserProfile copyWith({DateTime? birthDate, String? name, bool? onboardingDone}) => UserProfile(
    birthDate: birthDate ?? this.birthDate,
    name: name ?? this.name,
    onboardingDone: onboardingDone ?? this.onboardingDone,
  );
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final rawDate = prefs.getString(PrefKeys.birthDate);
    return UserProfile(
      birthDate: rawDate == null ? null : DateTime.tryParse(rawDate),
      name: prefs.getString(PrefKeys.userName),
      onboardingDone: prefs.getBool(PrefKeys.onboardingDone) ?? false,
    );
  }

  Future<void> setBirthDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    state = state.copyWith(birthDate: normalized);
    await ref.read(sharedPreferencesProvider).setString(PrefKeys.birthDate, dayKeyOf(normalized));
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    await ref.read(sharedPreferencesProvider).setBool(PrefKeys.onboardingDone, true);
  }

  /// Сброс локальных данных (для «удалить мои данные» и отладки).
  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(PrefKeys.birthDate);
    await prefs.remove(PrefKeys.userName);
    await prefs.remove(PrefKeys.onboardingDone);
    state = const UserProfile();
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(
  UserProfileNotifier.new,
);
