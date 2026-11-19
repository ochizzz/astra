import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/line_icons.dart';
import '../../../core/widgets/tab_page.dart';

class SignsScreen extends StatelessWidget {
  const SignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoon(
      title: 'Знаки',
      icon: AstraIcon.signs,
      description:
          'Двенадцать созвездий — двенадцать характеров. '
          'Здесь появятся подробные портреты знаков и их совместимость.',
      features: [
        'Профили 12 знаков и психотипы',
        'Совместимость знаков',
        'Гороскоп на неделю и месяц',
        'Натальная карта (после указания времени рождения)',
      ],
    );
  }
}
