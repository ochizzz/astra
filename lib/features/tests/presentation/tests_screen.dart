import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/line_icons.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/tab_page.dart';
import '../data/tests_repository.dart';
import '../domain/test_models.dart';

/// Вкладка «Тесты и игры»: каталог тестов и мини-игры.
class TestsScreen extends ConsumerWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(testsProvider);
    final done = ref.watch(testResultsProvider);

    return TabPage(
      overline: 'Узнай себя',
      title: 'Тесты и игры',
      children: [
        const SectionLabel('Игры'),
        const SizedBox(height: 12),
        FadeSlideIn(
          child: _GameCard(
            title: 'Шар судьбы',
            subtitle: 'Задай вопрос и встряхни телефон',
            onTap: () {
              ref.read(appFeedbackProvider).tap();
              context.go(Routes.magicBall);
            },
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: _SoonCard(title: 'Выбери звезду')),
            SizedBox(width: 12),
            Expanded(child: _SoonCard(title: 'Колесо удачи')),
          ],
        ),
        const SizedBox(height: 28),
        const SectionLabel('Тесты'),
        const SizedBox(height: 12),
        for (final (i, t) in tests.indexed) ...[
          FadeSlideIn(
            delay: Duration(milliseconds: 120 + 80 * i),
            child: _TestCard(
              test: t,
              result: t.results.where((r) => r.id == done[t.id]).firstOrNull,
              onTap: () {
                ref.read(appFeedbackProvider).tap();
                context.go('${Routes.tests}/${t.id}');
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test, required this.onTap, this.result});

  final AstraTest test;
  final TestResult? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 0.8),
            ),
            child: Text(
              result?.symbol ?? '✦',
              style: const TextStyle(color: AppColors.gold, fontSize: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.title, style: text.headlineSmall!.copyWith(fontSize: 22)),
                const SizedBox(height: 2),
                Text(test.subtitle, style: text.bodySmall),
                const SizedBox(height: 6),
                Text(
                  result == null
                      ? '${test.questions.length} вопросов · ${test.minutes} мин'
                      : 'Твой результат: ${result!.title}',
                  style: text.labelSmall!.copyWith(
                    color: result == null ? AppColors.textMuted : AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      glow: true,
      onTap: onTap,
      child: Row(
        children: [
          const Floating(amplitude: 3, child: _MiniOrb()),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.headlineSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.gold),
        ],
      ),
    );
  }
}

class _MiniOrb extends StatelessWidget {
  const _MiniOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFF6E58B8), Color(0xFF2A1B4D), AppColors.night],
          stops: [0, 0.6, 1],
        ),
        boxShadow: [BoxShadow(color: AppColors.lavender.withValues(alpha: 0.35), blurRadius: 18)],
      ),
      child: const Center(
        child: Text('✦', style: TextStyle(color: AppColors.goldBright, fontSize: 16)),
      ),
    );
  }
}

class _SoonCard extends StatelessWidget {
  const _SoonCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LineIcon(AstraIcon.sparkle, size: 22, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(title, style: text.titleMedium),
          Text('скоро', style: text.labelSmall),
        ],
      ),
    );
  }
}
