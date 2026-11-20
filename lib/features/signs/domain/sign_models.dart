// Модели раздела «Знаки». Чистый Dart — контент можно генерировать и
// проверять скриптами без Flutter.

import '../../../core/astro/zodiac.dart';

/// Подробный профиль знака.
class SignProfile {
  const SignProfile({
    required this.sign,
    required this.tagline,
    required this.character,
    required this.strengths,
    required this.shadow,
    required this.love,
    required this.friendship,
    required this.work,
    required this.support,
    required this.stone,
    required this.color,
    required this.number,
    required this.bestMatches,
  });

  final ZodiacSign sign;

  /// Одна поэтичная строка под названием знака (до 70 символов).
  final String tagline;

  /// Характер: 2–3 абзаца через `\n\n`, всего 500–800 символов.
  final String character;

  /// Ровно 4 коротких сильных стороны (2–4 слова каждая).
  final List<String> strengths;

  /// «Тень» знака — мягко, без осуждения, 200–350 символов.
  final String shadow;

  /// Знак в любви, дружбе и работе: по 250–400 символов.
  final String love;
  final String friendship;
  final String work;

  /// Как поддержать человека этого знака: 150–250 символов.
  final String support;

  /// Камень, цвет и число знака.
  final String stone;
  final String color;
  final int number;

  /// Ровно три самых гармоничных знака.
  final List<ZodiacSign> bestMatches;
}

/// Совместимость пары знаков. Порядок знаков в паре не важен.
class PairCompatibility {
  const PairCompatibility({
    required this.love,
    required this.friendship,
    required this.work,
    required this.passion,
    required this.title,
    required this.summary,
    required this.strength,
    required this.growth,
    required this.advice,
  });

  /// Оценки 40..98 (в процентах).
  final int love;
  final int friendship;
  final int work;
  final int passion;

  /// Образное название пары, 2–5 слов: «Пламя и ветер».
  final String title;

  /// Описание пары, 300–500 символов.
  final String summary;

  /// В чём сила пары, 120–220 символов.
  final String strength;

  /// Над чем работать — мягко, 120–220 символов.
  final String growth;

  /// Совет паре, одна фраза до 120 символов.
  final String advice;

  int get overall => ((love + friendship + work + passion) / 4).round();
}

/// Ключ пары, не зависящий от порядка: `aries+leo`.
String pairKey(ZodiacSign a, ZodiacSign b) =>
    a.index <= b.index ? '${a.name}+${b.name}' : '${b.name}+${a.name}';
