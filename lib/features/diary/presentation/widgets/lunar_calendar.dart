import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/astro/moon_phase.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/moon_disc.dart';

/// Лунный календарь на месяц: фаза Луны на каждый день (офлайн-расчёт),
/// отметки дней с записями, выбор дня.
class LunarCalendar extends StatefulWidget {
  const LunarCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.markedDays,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  /// Дни, в которые есть записи или ответы.
  final Set<DateTime> markedDays;

  @override
  State<LunarCalendar> createState() => _LunarCalendarState();
}

class _LunarCalendarState extends State<LunarCalendar> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  void _shift(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final leading = (_month.weekday + 6) % 7; // понедельник — первый
    final title = DateFormat('LLLL y', 'ru').format(_month);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Предыдущий месяц',
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.gold),
              ),
              Expanded(
                child: Text(
                  '${title[0].toUpperCase()}${title.substring(1)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Следующий месяц',
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final d in _weekdays)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: AppTypography.overline.copyWith(fontSize: 9, letterSpacing: 1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.72,
            ),
            itemCount: leading + daysInMonth,
            itemBuilder: (context, i) {
              if (i < leading) return const SizedBox.shrink();
              final day = DateTime(_month.year, _month.month, i - leading + 1);
              return _DayCell(
                day: day,
                isToday: day == today,
                isSelected: DateUtils.isSameDay(day, widget.selected),
                marked: widget.markedDays.contains(day),
                onTap: () => widget.onSelect(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.marked,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final moon = MoonPhase.at(DateTime(day.year, day.month, day.day, 12));
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${day.day}, ${moon.name.title}${marked ? ', есть запись' : ''}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected ? AppColors.gold.withValues(alpha: 0.12) : null,
            border: Border.all(
              color: isSelected
                  ? AppColors.gold
                  : isToday
                  ? AppColors.gold.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MoonDisc(illumination: moon.illumination, waxing: moon.isWaxing, size: 24),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: isToday ? AppColors.gold : AppColors.textPrimary,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              SizedBox(
                height: 6,
                child: marked
                    ? Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
