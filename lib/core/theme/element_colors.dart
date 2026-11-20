import 'package:material_ui/material_ui.dart';

import '../astro/zodiac.dart';
import 'app_colors.dart';

/// Оттенок свечения стихии — в рамках общей палитры.
extension ZodiacElementColor on ZodiacElement {
  Color get color => switch (this) {
    ZodiacElement.fire => AppColors.gold,
    ZodiacElement.earth => const Color(0xFFD8C39C),
    ZodiacElement.air => AppColors.moonPink,
    ZodiacElement.water => AppColors.lavender,
  };
}
