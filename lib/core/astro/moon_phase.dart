import 'dart:math' as math;

import 'zodiac.dart';

/// Фаза Луны и знак Луны — локальный офлайн-расчёт.
///
/// Используются формулы низкой точности из книги Жана Миуса
/// «Astronomical Algorithms» (гл. 25, 47, 48). Точность долготы Луны ~0.3°,
/// освещённости — доли процента: для лунного календаря этого достаточно,
/// а лицензия кода — наша (формулы не защищены авторским правом).
/// Для натальной карты используется серверный расчёт (Astronomy Engine, MIT).
class MoonPhase {
  const MoonPhase._({
    required this.illumination,
    required this.elongation,
    required this.moonLongitude,
  });

  factory MoonPhase.at(DateTime moment) {
    final t = (_julianDay(moment.toUtc()) - 2451545.0) / 36525.0;

    final d = _norm(297.8501921 + 445267.1114034 * t); // элонгация (ср.)
    final m = _norm(357.5291092 + 35999.0502909 * t); // ср. аномалия Солнца
    final mp = _norm(134.9633964 + 477198.8675055 * t); // ср. аномалия Луны
    final lp = _norm(218.3164477 + 481267.88123421 * t); // ср. долгота Луны
    final f = _norm(93.2720950 + 483202.0175233 * t); // аргумент широты
    final l0 = _norm(280.46646 + 36000.76983 * t); // ср. долгота Солнца

    final moonLon = _norm(
      lp +
          6.288774 * _sin(mp) +
          1.274027 * _sin(2 * d - mp) +
          0.658314 * _sin(2 * d) +
          0.213618 * _sin(2 * mp) -
          0.185116 * _sin(m) -
          0.114332 * _sin(2 * f) +
          0.058793 * _sin(2 * d - 2 * mp) +
          0.057066 * _sin(2 * d - m - mp) +
          0.053322 * _sin(2 * d + mp),
    );
    final sunLon = _norm(l0 + 1.914602 * _sin(m) + 0.019993 * _sin(2 * m));

    // Фазовый угол (48.4)
    final i = _norm(
      180 -
          d -
          6.289 * _sin(mp) +
          2.100 * _sin(m) -
          1.274 * _sin(2 * d - mp) -
          0.658 * _sin(2 * d) -
          0.214 * _sin(2 * mp) -
          0.110 * _sin(d),
    );

    return MoonPhase._(
      illumination: (1 + _cos(i)) / 2,
      elongation: _norm(moonLon - sunLon),
      moonLongitude: moonLon,
    );
  }

  static const synodicMonth = 29.530588853;

  /// Доля освещённого диска, 0..1.
  final double illumination;

  /// Элонгация Луны от Солнца по долготе, 0..360°. 0 — новолуние, 180 — полнолуние.
  final double elongation;

  /// Геоцентрическая эклиптическая долгота Луны, градусы.
  final double moonLongitude;

  bool get isWaxing => elongation < 180;

  /// Возраст Луны в сутках с последнего новолуния (приблизительно).
  double get age => elongation / 360 * synodicMonth;

  /// Лунный день 1..30 (упрощённо — по возрасту Луны).
  int get lunarDay => math.min(30, age.floor() + 1);

  ZodiacSign get sign => ZodiacSign.fromEclipticLongitude(moonLongitude);

  MoonPhaseName get name {
    final index = ((elongation + 22.5) % 360 ~/ 45);
    return MoonPhaseName.values[index];
  }

  static double _julianDay(DateTime utc) => utc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;

  static double _norm(double deg) {
    final r = deg % 360;
    return r < 0 ? r + 360 : r;
  }

  static double _sin(double deg) => math.sin(deg * math.pi / 180);
  static double _cos(double deg) => math.cos(deg * math.pi / 180);
}

enum MoonPhaseName {
  newMoon('Новолуние', 'Время тихих намерений и новых начал.'),
  waxingCrescent('Растущий серп', 'Хорошо начинать и пробовать.'),
  firstQuarter('Первая четверть', 'Время решений и первых шагов.'),
  waxingGibbous('Растущая Луна', 'Энергии всё больше — доводи начатое.'),
  fullMoon('Полнолуние', 'Чувства ярче, а ответы ближе.'),
  waningGibbous('Убывающая Луна', 'Время благодарности и разговоров.'),
  lastQuarter('Последняя четверть', 'Отпусти лишнее и разбери завалы.'),
  waningCrescent('Убывающий серп', 'Отдых, сны и восстановление.');

  const MoonPhaseName(this.title, this.hint);

  final String title;
  final String hint;
}
