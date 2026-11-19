import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

const _months = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

/// Выбор даты рождения тремя «барабанами»: день — месяц — год.
/// Свой виджет вместо системного пикера, чтобы сохранить атмосферу.
class BirthDateWheel extends StatefulWidget {
  const BirthDateWheel({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.firstYear,
    required this.lastYear,
    this.onTick,
  });

  final DateTime initial;
  final ValueChanged<DateTime> onChanged;
  final int firstYear;
  final int lastYear;

  /// Вызывается при каждом «щелчке» барабана — для лёгкой вибрации.
  final VoidCallback? onTick;

  @override
  State<BirthDateWheel> createState() => _BirthDateWheelState();
}

class _BirthDateWheelState extends State<BirthDateWheel> {
  late int _day = widget.initial.day;
  late int _month = widget.initial.month;
  late int _year = widget.initial.year;

  late final _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
  late final _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
  late final _yearCtrl = FixedExtentScrollController(initialItem: _year - widget.firstYear);

  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  void _emit() {
    if (_day > _daysInMonth) {
      _day = _daysInMonth;
      _dayCtrl.jumpToItem(_day - 1);
    }
    widget.onTick?.call();
    widget.onChanged(DateTime(_year, _month, _day));
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          // Полоса выбора: две золотые линии
          Center(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.gold.withValues(alpha: 0.45), width: 0.7),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0),
                    AppColors.gold.withValues(alpha: 0.07),
                    AppColors.gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _Wheel(
                  controller: _dayCtrl,
                  count: _daysInMonth,
                  label: (i) => '${i + 1}',
                  semanticsLabel: 'День',
                  onSelected: (i) {
                    _day = i + 1;
                    _emit();
                  },
                ),
              ),
              Expanded(
                flex: 4,
                child: _Wheel(
                  controller: _monthCtrl,
                  count: 12,
                  label: (i) => _months[i],
                  semanticsLabel: 'Месяц',
                  onSelected: (i) {
                    setState(() => _month = i + 1);
                    _emit();
                  },
                ),
              ),
              Expanded(
                flex: 3,
                child: _Wheel(
                  controller: _yearCtrl,
                  count: widget.lastYear - widget.firstYear + 1,
                  label: (i) => '${widget.firstYear + i}',
                  semanticsLabel: 'Год',
                  onSelected: (i) {
                    setState(() => _year = widget.firstYear + i);
                    _emit();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.count,
    required this.label,
    required this.onSelected,
    required this.semanticsLabel,
  });

  final FixedExtentScrollController controller;
  final int count;
  final String Function(int) label;
  final ValueChanged<int> onSelected;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        diameterRatio: 1.6,
        perspective: 0.004,
        useMagnifier: true,
        magnification: 1.18,
        overAndUnderCenterOpacity: 0.35,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, i) => Center(
            child: Text(
              label(i),
              style: AppTypography.textTheme.titleLarge!.copyWith(
                fontSize: 23,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
