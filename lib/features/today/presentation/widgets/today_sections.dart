import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router.dart';
import '../../../../core/astro/moon_phase.dart';
import '../../../../core/firebase/analytics.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/astra_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/moon_disc.dart';
import '../../../../core/widgets/reveal.dart';
import '../../data/today_repository.dart';
import '../../domain/today_models.dart';

// ─── Цитата дня ────────────────────────────────────────────────────────

class QuoteSection extends StatelessWidget {
  const QuoteSection({super.key, required this.quote});

  final DailyQuote quote;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Цитата дня'),
          const SizedBox(height: 14),
          SizedBox(
            height: 34,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: 80,
              child: Text(
                '“',
                style: AppTypography.quote.copyWith(
                  fontSize: 64,
                  height: 1,
                  color: AppColors.gold.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          RevealText(
            quote.text,
            delay: const Duration(milliseconds: 600),
            style: AppTypography.quote,
          ),
          const SizedBox(height: 12),
          Text('— ${quote.author}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─── Гороскоп дня ──────────────────────────────────────────────────────

class HoroscopeSection extends ConsumerWidget {
  const HoroscopeSection({super.key, required this.horoscope});

  final DailyHoroscope horoscope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final sign = horoscope.sign;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            'Гороскоп · ${sign.title}',
            trailing: Text(
              sign.textGlyph,
              style: const TextStyle(color: AppColors.gold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 14),
          RevealText(
            horoscope.text,
            delay: const Duration(milliseconds: 900),
            style: text.bodyLarge,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Meter(label: 'Любовь', value: horoscope.scores.love),
              ),
              Expanded(
                child: _Meter(label: 'Дела', value: horoscope.scores.work),
              ),
              Expanded(
                child: _Meter(label: 'Энергия', value: horoscope.scores.energy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const OrnamentDivider(),
          const SizedBox(height: 10),
          // Мягкое приглашение войти — без всплывающих окон.
          SoftLink(
            label: 'Уточнить по времени рождения',
            onTap: () {
              ref.read(analyticsProvider).signInPromptShown(source: 'horoscope');
              context.go(Routes.profile);
            },
          ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Semantics(
          label: '$label: $value из 5',
          excludeSemantics: true,
          child: Row(
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Text(
                    '✦',
                    style: TextStyle(
                      fontSize: 12,
                      color: i < value ? AppColors.gold : AppColors.strokeSoft,
                      shadows: i < value
                          ? [Shadow(color: AppColors.gold.withValues(alpha: 0.6), blurRadius: 6)]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Если дата рождения не указана — показываем приглашение вместо гороскопа.
class HoroscopePlaceholder extends StatelessWidget {
  const HoroscopePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Гороскоп дня'),
          const SizedBox(height: 12),
          Text(
            'Укажи дату рождения, и здесь появится гороскоп для твоего знака.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          SoftLink(label: 'Указать дату', onTap: () => context.go(Routes.profile)),
        ],
      ),
    );
  }
}

// ─── Луна ──────────────────────────────────────────────────────────────

class MoonSection extends StatelessWidget {
  const MoonSection({super.key, required this.moon});

  final MoonPhase moon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final percent = (moon.illumination * 100).round();
    return GlassCard(
      child: Row(
        children: [
          Floating(
            amplitude: 3,
            child: MoonDisc(illumination: moon.illumination, waxing: moon.isWaxing, size: 76),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Луна сегодня'),
                const SizedBox(height: 8),
                Text(moon.name.title, style: text.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  'Луна в знаке ${moon.sign.title} · ${moon.lunarDay}-й лунный день · $percent%',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(moon.name.hint, style: text.bodyMedium!.copyWith(color: AppColors.moonPink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Вопрос дня ────────────────────────────────────────────────────────

class QuestionSection extends ConsumerStatefulWidget {
  const QuestionSection({super.key, required this.question});

  final DailyQuestion question;

  @override
  ConsumerState<QuestionSection> createState() => _QuestionSectionState();
}

class _QuestionSectionState extends ConsumerState<QuestionSection> {
  final _controller = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    await ref.read(todayProgressProvider.notifier).saveAnswer(_controller.text);
    ref.read(appFeedbackProvider).success();
    ref.read(analyticsProvider).questionAnswered();
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final answer = ref.watch(todayProgressProvider.select((p) => p.answer));
    final text = Theme.of(context).textTheme;
    final showInput = answer == null || _editing;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Вопрос дня'),
          const SizedBox(height: 12),
          Text(widget.question.text, style: text.headlineSmall),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: showInput
                ? Column(
                    key: const ValueKey('input'),
                    children: [
                      TextField(
                        controller: _controller,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Напиши пару строк для себя…',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) => GoldButton(
                          label: 'Сохранить в дневник',
                          onPressed: _controller.text.trim().isEmpty ? null : _save,
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('answer'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer,
                        style: AppTypography.quote.copyWith(
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.check_rounded, size: 16, color: AppColors.gold),
                          const SizedBox(width: 6),
                          Expanded(child: Text('Сохранено в дневнике', style: text.bodySmall)),
                          TextButton(
                            onPressed: () {
                              _controller.text = answer;
                              setState(() => _editing = true);
                            },
                            child: const Text('Изменить'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Пометка «для развлечения» ────────────────────────────────────────

class EntertainmentNote extends StatelessWidget {
  const EntertainmentNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Прогнозы «Астры» созданы для вдохновения и развлечения '
        'и не заменяют советов специалистов.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
