import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/line_icons.dart';
import '../../../core/widgets/tab_page.dart';

class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoon(
      title: 'Тесты и игры',
      icon: AstraIcon.tests,
      description:
          'Узнай о себе что-то новое — легко и красиво. '
          'Результатом можно будет поделиться в Stories.',
      features: [
        'Каталог тестов о характере и отношениях',
        'Результат-карточка для Stories',
        'Шар судьбы',
        '«Выбери звезду» и колесо удачи',
      ],
    );
  }
}
