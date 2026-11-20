import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/astro/moon_phase.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/astra_buttons.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/line_icons.dart';
import '../../../core/widgets/moon_disc.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/tab_page.dart';
import '../data/diary_repository.dart';
import '../domain/diary_models.dart';
import 'widgets/lunar_calendar.dart';
import 'widgets/mood_picker.dart';

enum _View { feed, moon }

/// Вкладка «Дневник»: лента записей и ответов + лунный календарь.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  _View _view = _View.feed;
  DateTime _selectedDay = DateUtils.dateOnly(DateTime.now());

  void _newEntry([DateTime? date]) {
    ref.read(appFeedbackProvider).tap();
    final day = dayKeyOf(date ?? DateTime.now());
    context.go('${Routes.diaryEntry}?date=$day');
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(diaryProvider);
    final answers = ref.watch(questionAnswersProvider);

    return Stack(
      children: [
        TabPage(
          overline: 'Твоё тихое место',
          title: 'Дневник',
          children: [
            _ViewSwitch(
              value: _view,
              onChanged: (v) {
                ref.read(appFeedbackProvider).tap();
                setState(() => _view = v);
              },
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _view == _View.feed
                  ? _Feed(
                      key: const ValueKey('feed'),
                      entries: entries,
                      answers: answers,
                      onNew: _newEntry,
                    )
                  : _MoonView(
                      key: const ValueKey('moon'),
                      entries: entries,
                      answers: answers,
                      selected: _selectedDay,
                      onSelect: (d) => setState(() => _selectedDay = d),
                      onNew: _newEntry,
                    ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: MediaQuery.paddingOf(context).bottom + 92,
          child: _StarFab(onTap: () => _newEntry(_view == _View.moon ? _selectedDay : null)),
        ),
      ],
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.value, required this.onChanged});

  final _View value;
  final ValueChanged<_View> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(_View v, String label) {
      final selected = v == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: selected ? AppColors.gold.withValues(alpha: 0.14) : null,
              border: Border.all(
                color: selected ? AppColors.gold.withValues(alpha: 0.7) : Colors.transparent,
                width: 0.8,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.labelLarge!.copyWith(
                color: selected ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppColors.cardBottom,
        border: Border.all(color: AppColors.strokeSoft, width: 0.6),
      ),
      child: Row(children: [tab(_View.feed, 'Записи'), tab(_View.moon, 'Лунный календарь')]),
    );
  }
}

class _StarFab extends StatelessWidget {
  const _StarFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Новая запись',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.goldGradient,
            boxShadow: AppColors.goldGlow(0.8),
          ),
          child: const Icon(Icons.edit_rounded, color: AppColors.night, size: 24),
        ),
      ),
    );
  }
}

// ─── Лента ─────────────────────────────────────────────────────────────

class _Feed extends StatelessWidget {
  const _Feed({super.key, required this.entries, required this.answers, required this.onNew});

  final List<DiaryEntry> entries;
  final List<QuestionAnswer> answers;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty && answers.isEmpty) return _EmptyState(onNew: onNew);

    // Группируем записи и ответы по дням.
    final days = <DateTime>{...entries.map((e) => e.date), ...answers.map((a) => a.date)}.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, day) in days.indexed)
          FadeSlideIn(
            delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
            child: _DayGroup(
              day: day,
              entries: entries.where((e) => e.date == day).toList(),
              answer: answers.where((a) => a.date == day).firstOrNull,
            ),
          ),
      ],
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.entries, this.answer});

  final DateTime day;
  final List<DiaryEntry> entries;
  final QuestionAnswer? answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(dayLabel(day).toUpperCase(), style: AppTypography.overline),
          ),
          for (final e in entries) ...[EntryCard(entry: e), const SizedBox(height: 10)],
          if (answer != null) AnswerCard(answer: answer!),
        ],
      ),
    );
  }
}

/// «Сегодня», «Вчера», «18 ноября», «18 ноября 2025».
String dayLabel(DateTime day) {
  final today = DateUtils.dateOnly(DateTime.now());
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Сегодня';
  if (diff == 1) return 'Вчера';
  return DateFormat(day.year == today.year ? 'd MMMM' : 'd MMMM y', 'ru').format(day);
}

class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      onTap: () => context.go('${Routes.diaryEntry}?id=${entry.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.mood != null) ...[
            Column(
              children: [
                MoodMoon(mood: entry.mood!, size: 32),
                const SizedBox(height: 4),
                Text(entry.mood!.title, style: text.labelSmall),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              entry.text.isEmpty ? 'Без слов — только настроение' : entry.text,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: entry.text.isEmpty
                  ? text.bodyMedium!.copyWith(color: AppColors.textMuted)
                  : text.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class AnswerCard extends StatelessWidget {
  const AnswerCard({super.key, required this.answer});

  final QuestionAnswer answer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Вопрос дня'),
          if (answer.question != null) ...[
            const SizedBox(height: 8),
            Text(answer.question!, style: text.titleLarge!.copyWith(fontSize: 19)),
          ],
          const SizedBox(height: 8),
          Text(
            answer.answer,
            style: AppTypography.quote.copyWith(fontSize: 19, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Floating(child: LineIcon(AstraIcon.diary, size: 48, strokeWidth: 1)),
          const SizedBox(height: 16),
          Text('Здесь будут твои мысли', style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Отмечай настроение, записывай важное и отвечай на вопрос дня — '
            'со временем ты увидишь, как Луна влияет на тебя.',
            textAlign: TextAlign.center,
            style: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          GoldButton(label: 'Первая запись', onPressed: onNew, expand: false),
        ],
      ),
    );
  }
}

// ─── Лунный календарь ──────────────────────────────────────────────────

class _MoonView extends StatelessWidget {
  const _MoonView({
    super.key,
    required this.entries,
    required this.answers,
    required this.selected,
    required this.onSelect,
    required this.onNew,
  });

  final List<DiaryEntry> entries;
  final List<QuestionAnswer> answers;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onNew;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final moon = MoonPhase.at(DateTime(selected.year, selected.month, selected.day, 12));
    final dayEntries = entries.where((e) => e.date == selected).toList();
    final answer = answers.where((a) => a.date == selected).firstOrNull;

    return Column(
      children: [
        LunarCalendar(
          selected: selected,
          onSelect: onSelect,
          markedDays: {...entries.map((e) => e.date), ...answers.map((a) => a.date)},
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: [
              MoonDisc(illumination: moon.illumination, waxing: moon.isWaxing, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dayLabel(selected).toUpperCase(), style: AppTypography.overline),
                    const SizedBox(height: 6),
                    Text(moon.name.title, style: text.headlineSmall),
                    Text(
                      'Луна ${moon.sign.inSign} · ${moon.lunarDay}-й лунный день',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      moon.name.hint,
                      style: text.bodyMedium!.copyWith(color: AppColors.moonPink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final e in dayEntries) ...[EntryCard(entry: e), const SizedBox(height: 10)],
        if (answer != null) AnswerCard(answer: answer),
        if (dayEntries.isEmpty && answer == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SoftLink(label: 'Записать мысли об этом дне', onTap: () => onNew(selected)),
          ),
      ],
    );
  }
}
