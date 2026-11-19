import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/firebase/analytics.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/card_faces.dart';
import '../../../../core/widgets/flip_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/reveal.dart';
import '../../data/today_repository.dart';
import '../../domain/today_models.dart';
import 'share_button.dart';

class DailyCardSection extends ConsumerWidget {
  const DailyCardSection({super.key, required this.card});

  final DailyCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flipped = ref.watch(todayProgressProvider.select((p) => p.cardFlipped));
    final text = Theme.of(context).textTheme;
    final width = (MediaQuery.sizeOf(context).width * 0.5).clamp(180.0, 240.0);

    return Column(
      children: [
        const SectionLabel('Карта дня'),
        const SizedBox(height: 4),
        Floating(
          amplitude: flipped ? 3 : 6,
          child: FlipCard(
            width: width,
            flipped: flipped,
            onFlip: () {
              ref.read(appFeedbackProvider).reveal();
              ref.read(analyticsProvider).dailyCardFlipped(cardId: card.id);
              ref.read(todayProgressProvider.notifier).flipCard();
            },
            back: const CardBack(hint: 'КОСНИСЬ, ЧТОБЫ ОТКРЫТЬ'),
            front: StarCardFront(number: card.number, title: card.title),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          child: flipped
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    children: [
                      Text(
                        card.title,
                        style: text.headlineMedium!.copyWith(color: AppColors.goldBright),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      RevealText(
                        card.meaning,
                        delay: const Duration(milliseconds: 500),
                        textAlign: TextAlign.center,
                        style: text.bodyLarge!.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 1400),
                        child: Column(
                          children: [
                            Text(
                              '«${card.advice}»',
                              textAlign: TextAlign.center,
                              style: AppTypography.quote.copyWith(fontSize: 21),
                            ),
                            const SizedBox(height: 14),
                            ShareButton(
                              contentType: 'daily_card',
                              text:
                                  'Моя карта дня в «Астре» — «${card.title}».\n'
                                  '${card.meaning}\n\nСовет дня: ${card.advice}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Сделай вдох, подумай о своём дне и коснись карты',
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ),
        ),
      ],
    );
  }
}
