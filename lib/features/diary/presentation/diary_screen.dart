import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/line_icons.dart';
import '../../../core/widgets/tab_page.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoon(
      title: 'Дневник',
      icon: AstraIcon.diary,
      description:
          'Твоё тихое место: мысли, настроение и ответы на вопрос дня. '
          'Ответы со вкладки «Сегодня» уже сохраняются на устройстве.',
      features: [
        'Записи и настроение дня',
        'Ответы на вопрос дня',
        'Лунный календарь',
        'Синхронизация в облаке — после входа',
      ],
    );
  }
}
