import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/user/user_profile.dart';
import '../../../core/widgets/reveal.dart';
import '../data/today_repository.dart';
import 'widgets/daily_card_section.dart';
import 'widgets/today_sections.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(todayContentProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom + 96;

    return SafeArea(
      bottom: false,
      child: switch (content) {
        AsyncData(:final value) => ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset),
          children: [
            FadeSlideIn(child: _Header(date: value.date)),
            const SizedBox(height: 20),
            DailyCardSection(card: value.card),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 250),
              child: QuoteSection(quote: value.quote),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 400),
              child: value.horoscope == null
                  ? const HoroscopePlaceholder()
                  : HoroscopeSection(horoscope: value.horoscope!),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 550),
              child: MoonSection(moon: value.moon),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 700),
              child: QuestionSection(question: value.question),
            ),
            const SizedBox(height: 24),
            const EntertainmentNote(),
          ],
        ),
        AsyncError() => Center(
          child: Text(
            'Звёзды сегодня в тумане. Попробуй открыть позже.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        _ => const Center(child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.gold)),
      },
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.date});

  final DateTime date;

  String _greeting(int hour) => switch (hour) {
    >= 5 && < 12 => 'Доброе утро',
    >= 12 && < 18 => 'Добрый день',
    >= 18 && < 23 => 'Добрый вечер',
    _ => 'Тихой ночи',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sign = ref.watch(userProfileProvider.select((p) => p.sign));
    final text = Theme.of(context).textTheme;
    final dateLabel = DateFormat('EEEE, d MMMM', 'ru').format(date);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateLabel.toUpperCase(), style: AppTypography.overline),
              const SizedBox(height: 6),
              Text(_greeting(DateTime.now().hour), style: text.displaySmall),
            ],
          ),
        ),
        if (sign != null)
          Tooltip(
            message: sign.title,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 0.8),
                boxShadow: AppColors.goldGlow(0.35),
                color: AppColors.night.withValues(alpha: 0.5),
              ),
              child: Text(
                sign.textGlyph,
                style: const TextStyle(color: AppColors.gold, fontSize: 22),
              ),
            ),
          ),
      ],
    );
  }
}
