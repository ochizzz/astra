/// Настроение — пять фаз Луны: от новолуния до полнолуния.
enum Mood {
  empty('Пусто', 0.0),
  quiet('Тихо', 0.25),
  even('Ровно', 0.5),
  bright('Светло', 0.75),
  radiant('Сияю', 1.0);

  const Mood(this.title, this.illumination);

  final String title;

  /// Освещённость диска Луны для иконки.
  final double illumination;
}

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.date,
    required this.text,
    required this.updatedAt,
    this.mood,
  });

  final String id;

  /// День записи (без времени).
  final DateTime date;
  final String text;
  final Mood? mood;
  final DateTime updatedAt;

  DiaryEntry copyWith({DateTime? date, String? text, Mood? mood, DateTime? updatedAt}) =>
      DiaryEntry(
        id: id,
        date: date ?? this.date,
        text: text ?? this.text,
        mood: mood ?? this.mood,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'date': date.toIso8601String().substring(0, 10),
    'text': text,
    'mood': mood?.name,
    'updatedAt': updatedAt.toIso8601String(),
  };

  static DiaryEntry? fromJson(Map<String, Object?> json) {
    final date = DateTime.tryParse(json['date'] as String? ?? '');
    final id = json['id'] as String?;
    if (date == null || id == null) return null;
    return DiaryEntry(
      id: id,
      date: date,
      text: json['text'] as String? ?? '',
      mood: Mood.values.where((m) => m.name == json['mood']).firstOrNull,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? date,
    );
  }
}

/// Ответ на вопрос дня — показывается в ленте дневника.
class QuestionAnswer {
  const QuestionAnswer({required this.date, required this.answer, this.question});

  final DateTime date;
  final String answer;
  final String? question;
}
