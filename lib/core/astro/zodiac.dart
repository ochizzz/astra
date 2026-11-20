enum ZodiacElement { fire, earth, air, water }

extension ElementX on ZodiacElement {
  String get title => switch (this) {
    ZodiacElement.fire => 'Огонь',
    ZodiacElement.earth => 'Земля',
    ZodiacElement.air => 'Воздух',
    ZodiacElement.water => 'Вода',
  };
}

/// Точка звезды в нормализованных координатах 0..1. Свой тип вместо `Offset`,
/// чтобы астрономическое ядро было чистым Dart (его использует и генератор
/// контента в `tool/`).
class StarPoint {
  const StarPoint(this.dx, this.dy);

  final double dx;
  final double dy;
}

/// Стилизованная схема созвездия: точки в нормализованных координатах (0..1)
/// и пары индексов — линии между звёздами.
class Constellation {
  const Constellation(this.stars, this.lines, {this.brightest = 0});

  final List<StarPoint> stars;
  final List<(int, int)> lines;

  /// Индекс самой яркой звезды — рисуется крупнее и со свечением.
  final int brightest;
}

enum ZodiacSign {
  aries(
    inSign: 'в Овне',
    title: 'Овен',
    glyph: '♈',
    start: (3, 21),
    end: (4, 19),
    element: ZodiacElement.fire,
    ruler: 'Марс',
    keywords: ['смелость', 'искра', 'первый шаг'],
    constellation: Constellation(
      [StarPoint(0.1, 0.55), StarPoint(0.45, 0.38), StarPoint(0.75, 0.42), StarPoint(0.9, 0.58)],
      [(0, 1), (1, 2), (2, 3)],
      brightest: 1,
    ),
  ),
  taurus(
    inSign: 'в Тельце',
    title: 'Телец',
    glyph: '♉',
    start: (4, 20),
    end: (5, 20),
    element: ZodiacElement.earth,
    ruler: 'Венера',
    keywords: ['нежность', 'устойчивость', 'вкус к жизни'],
    constellation: Constellation(
      [
        StarPoint(0.5, 0.58),
        StarPoint(0.4, 0.5),
        StarPoint(0.33, 0.42),
        StarPoint(0.6, 0.47),
        StarPoint(0.68, 0.38),
        StarPoint(0.12, 0.18),
        StarPoint(0.9, 0.22),
        StarPoint(0.72, 0.85),
      ],
      [(0, 1), (1, 2), (2, 5), (0, 3), (3, 4), (4, 6), (0, 7)],
    ),
  ),
  gemini(
    inSign: 'в Близнецах',
    title: 'Близнецы',
    glyph: '♊',
    start: (5, 21),
    end: (6, 20),
    element: ZodiacElement.air,
    ruler: 'Меркурий',
    keywords: ['любопытство', 'лёгкость', 'слово'],
    constellation: Constellation(
      [
        StarPoint(0.3, 0.1),
        StarPoint(0.3, 0.42),
        StarPoint(0.22, 0.88),
        StarPoint(0.6, 0.14),
        StarPoint(0.62, 0.5),
        StarPoint(0.7, 0.9),
      ],
      [(0, 1), (1, 2), (3, 4), (4, 5), (0, 3), (1, 4)],
      brightest: 3,
    ),
  ),
  cancer(
    inSign: 'в Раке',
    title: 'Рак',
    glyph: '♋',
    start: (6, 21),
    end: (7, 22),
    element: ZodiacElement.water,
    ruler: 'Луна',
    keywords: ['забота', 'интуиция', 'дом'],
    constellation: Constellation(
      [StarPoint(0.5, 0.52), StarPoint(0.45, 0.12), StarPoint(0.18, 0.86), StarPoint(0.82, 0.8)],
      [(0, 1), (0, 2), (0, 3)],
    ),
  ),
  leo(
    inSign: 'во Льве',
    title: 'Лев',
    glyph: '♌',
    start: (7, 23),
    end: (8, 22),
    element: ZodiacElement.fire,
    ruler: 'Солнце',
    keywords: ['сияние', 'щедрость', 'сердце'],
    constellation: Constellation(
      [
        StarPoint(0.2, 0.62),
        StarPoint(0.2, 0.4),
        StarPoint(0.3, 0.24),
        StarPoint(0.46, 0.22),
        StarPoint(0.45, 0.5),
        StarPoint(0.75, 0.45),
        StarPoint(0.9, 0.62),
        StarPoint(0.68, 0.72),
      ],
      [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5), (5, 6), (6, 7), (7, 4)],
    ),
  ),
  virgo(
    inSign: 'в Деве',
    title: 'Дева',
    glyph: '♍',
    start: (8, 23),
    end: (9, 22),
    element: ZodiacElement.earth,
    ruler: 'Меркурий',
    keywords: ['ясность', 'забота о деталях', 'чистота'],
    constellation: Constellation(
      [
        StarPoint(0.08, 0.3),
        StarPoint(0.28, 0.36),
        StarPoint(0.45, 0.5),
        StarPoint(0.6, 0.38),
        StarPoint(0.8, 0.28),
        StarPoint(0.5, 0.82),
        StarPoint(0.75, 0.64),
        StarPoint(0.92, 0.86),
      ],
      [(0, 1), (1, 2), (2, 3), (3, 4), (2, 5), (3, 6), (6, 7)],
      brightest: 5,
    ),
  ),
  libra(
    inSign: 'в Весах',
    title: 'Весы',
    glyph: '♎',
    start: (9, 23),
    end: (10, 22),
    element: ZodiacElement.air,
    ruler: 'Венера',
    keywords: ['гармония', 'красота', 'баланс'],
    constellation: Constellation(
      [
        StarPoint(0.5, 0.14),
        StarPoint(0.24, 0.45),
        StarPoint(0.76, 0.45),
        StarPoint(0.2, 0.82),
        StarPoint(0.8, 0.82),
      ],
      [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)],
    ),
  ),
  scorpio(
    inSign: 'в Скорпионе',
    title: 'Скорпион',
    glyph: '♏',
    start: (10, 23),
    end: (11, 21),
    element: ZodiacElement.water,
    ruler: 'Плутон',
    keywords: ['глубина', 'страсть', 'перерождение'],
    constellation: Constellation(
      [
        StarPoint(0.1, 0.18),
        StarPoint(0.16, 0.34),
        StarPoint(0.1, 0.5),
        StarPoint(0.34, 0.4),
        StarPoint(0.5, 0.52),
        StarPoint(0.6, 0.7),
        StarPoint(0.75, 0.86),
        StarPoint(0.9, 0.8),
        StarPoint(0.93, 0.62),
      ],
      [(0, 1), (1, 2), (1, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8)],
      brightest: 3,
    ),
  ),
  sagittarius(
    inSign: 'в Стрельце',
    title: 'Стрелец',
    glyph: '♐',
    start: (11, 22),
    end: (12, 21),
    element: ZodiacElement.fire,
    ruler: 'Юпитер',
    keywords: ['свобода', 'путь', 'вера'],
    constellation: Constellation(
      [
        StarPoint(0.3, 0.42),
        StarPoint(0.5, 0.3),
        StarPoint(0.7, 0.4),
        StarPoint(0.62, 0.58),
        StarPoint(0.36, 0.62),
        StarPoint(0.18, 0.78),
        StarPoint(0.84, 0.72),
        StarPoint(0.5, 0.12),
      ],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 7), (2, 6), (4, 5)],
      brightest: 3,
    ),
  ),
  capricorn(
    inSign: 'в Козероге',
    title: 'Козерог',
    glyph: '♑',
    start: (12, 22),
    end: (1, 19),
    element: ZodiacElement.earth,
    ruler: 'Сатурн',
    keywords: ['цель', 'выдержка', 'вершина'],
    constellation: Constellation(
      [
        StarPoint(0.08, 0.28),
        StarPoint(0.3, 0.46),
        StarPoint(0.55, 0.78),
        StarPoint(0.8, 0.52),
        StarPoint(0.92, 0.34),
        StarPoint(0.6, 0.38),
      ],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)],
      brightest: 4,
    ),
  ),
  aquarius(
    inSign: 'в Водолее',
    title: 'Водолей',
    glyph: '♒',
    start: (1, 20),
    end: (2, 18),
    element: ZodiacElement.air,
    ruler: 'Уран',
    keywords: ['свобода мысли', 'дружба', 'будущее'],
    constellation: Constellation(
      [
        StarPoint(0.08, 0.3),
        StarPoint(0.3, 0.24),
        StarPoint(0.45, 0.4),
        StarPoint(0.6, 0.28),
        StarPoint(0.75, 0.45),
        StarPoint(0.6, 0.72),
        StarPoint(0.88, 0.82),
      ],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (4, 6)],
      brightest: 3,
    ),
  ),
  pisces(
    inSign: 'в Рыбах',
    title: 'Рыбы',
    glyph: '♓',
    start: (2, 19),
    end: (3, 20),
    element: ZodiacElement.water,
    ruler: 'Нептун',
    keywords: ['мечта', 'сострадание', 'тайна'],
    constellation: Constellation(
      [
        StarPoint(0.14, 0.14),
        StarPoint(0.3, 0.4),
        StarPoint(0.44, 0.68),
        StarPoint(0.55, 0.88),
        StarPoint(0.7, 0.66),
        StarPoint(0.84, 0.54),
        StarPoint(0.92, 0.7),
        StarPoint(0.8, 0.8),
      ],
      [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 4)],
      brightest: 3,
    ),
  );

  const ZodiacSign({
    required this.inSign,
    required this.title,
    required this.glyph,
    required this.start,
    required this.end,
    required this.element,
    required this.ruler,
    required this.keywords,
    required this.constellation,
  });

  final String title;

  /// Предложный падеж с предлогом: «в Овне», «во Льве» — «Луна во Льве».
  final String inSign;

  /// Символ знака. Для отрисовки используйте [textGlyph] —
  /// он запрещает системе подменять символ на эмодзи.
  final String glyph;

  /// (месяц, день) начала и конца периода включительно.
  final (int, int) start;
  final (int, int) end;
  final ZodiacElement element;
  final String ruler;
  final List<String> keywords;
  final Constellation constellation;

  String get textGlyph => '$glyph︎';

  String get period {
    String fmt((int, int) md) => '${md.$2} ${_monthsGenitive[md.$1 - 1]}';
    return '${fmt(start)} — ${fmt(end)}';
  }

  /// Знак по дате рождения (по Солнцу, тропический зодиак).
  static ZodiacSign fromDate(DateTime date) {
    final md = date.month * 100 + date.day;
    for (final sign in values) {
      final s = sign.start.$1 * 100 + sign.start.$2;
      final e = sign.end.$1 * 100 + sign.end.$2;
      final inRange = s <= e ? (md >= s && md <= e) : (md >= s || md <= e);
      if (inRange) return sign;
    }
    throw StateError('Unreachable: no sign for $date');
  }

  /// Знак, в котором находится точка эклиптики с данной долготой (градусы).
  static ZodiacSign fromEclipticLongitude(double degrees) {
    final normalized = degrees % 360;
    return values[(normalized ~/ 30) % 12];
  }
}

const _monthsGenitive = [
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
