import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/moon_disc.dart';
import '../../domain/diary_models.dart';

/// Выбор настроения: пять фаз Луны.
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.value, required this.onChanged});

  final Mood? value;
  final ValueChanged<Mood> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final m in Mood.values)
          Semantics(
            button: true,
            selected: m == value,
            label: 'Настроение: ${m.title}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: m == value ? AppColors.gold : Colors.transparent,
                    width: 0.8,
                  ),
                  color: m == value ? AppColors.gold.withValues(alpha: 0.08) : null,
                ),
                child: Column(
                  children: [
                    MoodMoon(mood: m, size: 38),
                    const SizedBox(height: 6),
                    Text(
                      m.title,
                      style: Theme.of(context).textTheme.labelSmall!
                          .copyWith(color: m == value ? AppColors.gold : AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Иконка настроения — Луна с освещённостью по настроению.
class MoodMoon extends StatelessWidget {
  const MoodMoon({super.key, required this.mood, this.size = 28});

  final Mood mood;
  final double size;

  @override
  Widget build(BuildContext context) =>
      MoonDisc(illumination: mood.illumination, waxing: true, size: size);
}
