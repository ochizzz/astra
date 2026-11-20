import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/user/user_profile.dart';
import '../core/widgets/starry_sky.dart';
import '../features/home_widget/home_widget_sync.dart';
import '../features/today/data/today_repository.dart';
import 'router.dart';

class AstraApp extends ConsumerWidget {
  const AstraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Виджет на главном экране: перерисовать, когда загрузился контент дня
    // (в т.ч. после смены знака) или открыта карта дня.
    void refreshWidget() {
      if (ref.read(userProfileProvider).onboardingDone) {
        ref.read(homeWidgetSyncProvider).scheduleRefresh();
      }
    }

    ref.listen(todayContentProvider, (_, next) {
      if (next.hasValue) refreshWidget();
    });
    ref.listen(todayProgressProvider.select((p) => p.cardFlipped), (_, _) => refreshWidget());

    return MaterialApp.router(
      title: 'Астра',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      // Одно небо под всеми экранами: переходы не «перезапускают» звёзды.
      builder: (context, child) =>
          Stack(fit: StackFit.expand, children: [const StarrySky(), ?child]),
    );
  }
}
