import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/astro/moon_phase.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/astra_buttons.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/moon_disc.dart';
import '../../../core/widgets/sub_page.dart';
import '../data/diary_repository.dart';
import '../domain/diary_models.dart';
import 'widgets/mood_picker.dart';

/// Новая запись или редактирование существующей.
class DiaryEntryScreen extends ConsumerStatefulWidget {
  const DiaryEntryScreen({super.key, this.entryId, this.initialDate});

  final String? entryId;
  final DateTime? initialDate;

  @override
  ConsumerState<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends ConsumerState<DiaryEntryScreen> {
  late final DiaryEntry? _existing = widget.entryId == null
      ? null
      : ref.read(diaryProvider).where((e) => e.id == widget.entryId).firstOrNull;

  late DateTime _date = _existing?.date ?? DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
  late Mood? _mood = _existing?.mood;
  late final _text = TextEditingController(text: _existing?.text ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSave => _mood != null || _text.text.trim().isNotEmpty;

  void _close() => context.canPop() ? context.pop() : context.go(Routes.diary);

  Future<void> _save() async {
    await ref
        .read(diaryProvider.notifier)
        .save(id: _existing?.id, date: _date, text: _text.text, mood: _mood);
    ref.read(appFeedbackProvider).success();
    if (mounted) _close();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepViolet,
        title: const Text('Удалить запись?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(diaryProvider.notifier).delete(_existing!.id);
    if (mounted) _close();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      locale: const Locale('ru'),
    );
    if (picked != null) setState(() => _date = DateUtils.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final moon = MoonPhase.at(DateTime(_date.year, _date.month, _date.day, 12));

    return SubPage(
      parent: Routes.diary,
      trailing: _existing == null
          ? null
          : IconButton(
              tooltip: 'Удалить',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
            ),
      children: [
        Text(_existing == null ? 'Новая запись' : 'Запись', style: text.displaySmall),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _pickDate,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                MoonDisc(illumination: moon.illumination, waxing: moon.isWaxing, size: 22),
                const SizedBox(width: 10),
                Text(
                  DateFormat('d MMMM y', 'ru').format(_date),
                  style: text.titleMedium!.copyWith(color: AppColors.gold),
                ),
                const SizedBox(width: 6),
                Text('· ${moon.name.title}', style: text.bodySmall),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(left: 6), child: SectionLabel('Настроение')),
              const SizedBox(height: 12),
              MoodPicker(
                value: _mood,
                onChanged: (m) {
                  ref.read(appFeedbackProvider).tap();
                  setState(() => _mood = m);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _text,
          minLines: 8,
          maxLines: 20,
          maxLength: 5000,
          textCapitalization: TextCapitalization.sentences,
          style: text.bodyLarge,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Что сегодня на душе?', counterText: ''),
        ),
        const SizedBox(height: 20),
        GoldButton(label: 'Сохранить', onPressed: _canSave ? _save : null),
        const SizedBox(height: 12),
        Text(
          'Записи хранятся на устройстве, а после входа — ещё и в твоём аккаунте.',
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.labelSmall,
        ),
      ],
    );
  }
}
