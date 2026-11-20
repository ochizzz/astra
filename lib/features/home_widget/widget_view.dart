import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/astro/moon_phase.dart';
import '../../core/astro/zodiac.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/moon_disc.dart';

/// Данные одного дня для виджета на главном экране.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.date,
    required this.moon,
    required this.quote,
    this.cardTitle,
    this.sign,
  });

  final DateTime date;
  final MoonPhase moon;
  final String quote;

  /// Название карты дня, если её уже открыли; иначе — «ждёт тебя».
  final String? cardTitle;
  final ZodiacSign? sign;
}

enum WidgetVariant {
  /// 2×2 на главном экране.
  small(Size(170, 170)),

  /// 4×2.
  wide(Size(340, 170));

  const WidgetVariant(this.size);

  /// Логический размер картинки (dp).
  final Size size;
}

const _months = [
  'ЯНВ',
  'ФЕВ',
  'МАР',
  'АПР',
  'МАЯ',
  'ИЮН',
  'ИЮЛ',
  'АВГ',
  'СЕН',
  'ОКТ',
  'НОЯ',
  'ДЕК',
];
const _weekdays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

/// Картинка виджета. Рисуется вне дерева приложения (без Theme и
/// MediaQuery), поэтому все стили заданы явно.
class AstraWidgetView extends StatelessWidget {
  const AstraWidgetView({super.key, required this.data, required this.variant});

  final WidgetSnapshot data;
  final WidgetVariant variant;

  static const _display = TextStyle(
    fontFamily: AppFonts.display,
    fontFamilyFallback: AppFonts.symbolFallback,
    color: AppColors.textPrimary,
    height: 1.05,
  );
  static const _body = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.symbolFallback,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  String get _dateLabel =>
      '${_weekdays[data.date.weekday - 1]} · ${data.date.day} ${_months[data.date.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final size = variant.size;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: CustomPaint(
          painter: _WidgetBackground(seed: data.date.day),
          foregroundPainter: _Border(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: variant == WidgetVariant.small ? _small() : _wide(),
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Expanded(
        child: Text(
          _dateLabel,
          style: AppTypography.overline.copyWith(fontSize: 9, letterSpacing: 1.6),
        ),
      ),
      if (data.sign != null)
        Text(
          data.sign!.textGlyph,
          style: const TextStyle(
            fontFamilyFallback: AppFonts.symbolFallback,
            color: AppColors.gold,
            fontSize: 13,
          ),
        ),
    ],
  );

  Widget _moonRow(double moonSize) => Row(
    children: [
      MoonDisc(illumination: data.moon.illumination, waxing: data.moon.isWaxing, size: moonSize),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.moon.name.title,
              maxLines: 2,
              style: _display.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text('${data.moon.lunarDay}-й лунный день', style: _body.copyWith(fontSize: 10)),
          ],
        ),
      ),
    ],
  );

  Widget _card() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '✦ КАРТА ДНЯ',
        style: AppTypography.overline.copyWith(fontSize: 8.5, letterSpacing: 1.8),
      ),
      const SizedBox(height: 3),
      Text(
        data.cardTitle ?? 'ждёт тебя',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _display.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: data.cardTitle == null ? AppColors.moonPink : AppColors.goldBright,
          fontStyle: data.cardTitle == null ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    ],
  );

  Widget _small() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header(),
      const Spacer(),
      _moonRow(44),
      const Spacer(),
      const _GoldLine(),
      const SizedBox(height: 8),
      _card(),
    ],
  );

  Widget _wide() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header(),
      const SizedBox(height: 10),
      Expanded(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_moonRow(48), _card()],
              ),
            ),
            Container(
              width: 0.7,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gold.withValues(alpha: 0),
                    AppColors.gold.withValues(alpha: 0.5),
                    AppColors.gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  // Неразрывный пробел перед тире — тире не уходит в начало строки.
                  '«${data.quote.replaceAll(' — ', '\u00A0— ')}»',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.quote.copyWith(fontSize: 15, height: 1.25),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _GoldLine extends StatelessWidget {
  const _GoldLine();

  @override
  Widget build(BuildContext context) => Container(
    height: 0.7,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.gold.withValues(alpha: 0.55), AppColors.gold.withValues(alpha: 0)],
      ),
    ),
  );
}

/// Ночное небо с туманностью и россыпью звёзд.
class _WidgetBackground extends CustomPainter {
  _WidgetBackground({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.night, AppColors.deepViolet, AppColors.dusk],
        ).createShader(rect),
    );
    final nebula = Offset(size.width * 0.85, size.height * 0.1);
    canvas.drawCircle(
      nebula,
      size.height,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.lavender.withValues(alpha: 0.16), Colors.transparent],
        ).createShader(Rect.fromCircle(center: nebula, radius: size.height)),
    );
    final rnd = math.Random(seed);
    for (var i = 0; i < (size.width / 6).round(); i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final r = 0.3 + rnd.nextDouble() * 0.8;
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = (rnd.nextDouble() < 0.25 ? AppColors.goldBright : AppColors.textPrimary)
              .withValues(alpha: 0.25 + rnd.nextDouble() * 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(_WidgetBackground old) => old.seed != seed;
}

class _Border extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius((Offset.zero & size).deflate(0.6), const Radius.circular(26)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.gold.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_Border old) => false;
}
