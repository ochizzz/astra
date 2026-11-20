import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/astro/zodiac.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/element_colors.dart';
import '../../../core/user/user_profile.dart';
import '../../../core/widgets/constellation_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/sub_page.dart';
import '../data/sign_profiles.dart';

/// Подробный профиль знака.
class SignProfileScreen extends ConsumerWidget {
  const SignProfileScreen({super.key, required this.sign});

  final ZodiacSign sign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = signProfiles[sign]!;
    final mySign = ref.watch(userProfileProvider.select((p) => p.sign));
    final text = Theme.of(context).textTheme;
    final accent = sign.element.color;

    return SubPage(
      parent: Routes.signs,
      children: [
        // ── Шапка ──
        Center(
          child: SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.7),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstellationView(
                    key: ValueKey(sign),
                    constellation: sign.constellation,
                    starScale: 1.15,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 500),
          child: Column(
            children: [
              Text(
                '${sign.textGlyph}  ${sign.title}',
                textAlign: TextAlign.center,
                style: text.displayMedium!.copyWith(color: AppColors.goldBright),
              ),
              const SizedBox(height: 4),
              Text(sign.period, style: text.bodySmall),
              const SizedBox(height: 12),
              Text(
                profile.tagline,
                textAlign: TextAlign.center,
                style: AppTypography.quote.copyWith(fontSize: 21),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip('Стихия · ${sign.element.title}', accent),
                  _Chip('Планета · ${sign.ruler}', accent),
                  _Chip('Камень · ${profile.stone}', accent),
                  _Chip('Цвет · ${profile.color}', accent),
                  _Chip('Число · ${profile.number}', accent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Разделы ──
        FadeSlideIn(
          delay: const Duration(milliseconds: 700),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Характер'),
                const SizedBox(height: 12),
                RevealText(
                  profile.character,
                  delay: const Duration(milliseconds: 900),
                  wordDuration: const Duration(milliseconds: 18),
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final s in profile.strengths) _Strength(s)],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _Section(title: 'В любви', body: profile.love),
        _Section(title: 'В дружбе', body: profile.friendship),
        _Section(title: 'В работе', body: profile.work),
        _Section(title: 'Тень знака', body: profile.shadow, initiallyExpanded: false),
        _Section(title: 'Как поддержать', body: profile.support, initiallyExpanded: false),

        // ── Лучшие пары ──
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Лучшие пары'),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final m in profile.bestMatches)
                    Expanded(
                      child: _MatchButton(
                        sign: m,
                        onTap: () {
                          ref.read(appFeedbackProvider).tap();
                          context.go('${Routes.compat}?a=${sign.name}&b=${m.name}');
                        },
                      ),
                    ),
                ],
              ),
              if (mySign != null && mySign != sign) ...[
                const SizedBox(height: 12),
                const OrnamentDivider(),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('${Routes.compat}?a=${mySign.name}&b=${sign.name}'),
                    child: Text('Совместимость с моим знаком · ${mySign.title}'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SignSwitcher(current: sign),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.accent);

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.7),
        color: AppColors.cardBottom,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _Strength extends StatelessWidget {
  const _Strength(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('✦', style: TextStyle(color: AppColors.gold, fontSize: 10)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.goldBright),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

/// Раскрывающийся раздел профиля.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body, this.initiallyExpanded = true});

  final String title;
  final String body;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            iconColor: AppColors.gold,
            collapsedIconColor: AppColors.textMuted,
            title: SectionLabel(title),
            children: [Text(body, style: text.bodyLarge)],
          ),
        ),
      ),
    );
  }
}

class _MatchButton extends StatelessWidget {
  const _MatchButton({required this.sign, required this.onTap});

  final ZodiacSign sign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: sign.element.color.withValues(alpha: 0.6), width: 0.8),
              ),
              child: Text(
                sign.textGlyph,
                style: TextStyle(color: sign.element.color, fontSize: 22),
              ),
            ),
            const SizedBox(height: 6),
            Text(sign.title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Переход к соседним знакам по кругу зодиака.
class _SignSwitcher extends StatelessWidget {
  const _SignSwitcher({required this.current});

  final ZodiacSign current;

  @override
  Widget build(BuildContext context) {
    const all = ZodiacSign.values;
    final prev = all[(current.index + 11) % 12];
    final next = all[(current.index + 1) % 12];
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () => context.replace('${Routes.signs}/${prev.name}'),
            icon: const Icon(Icons.chevron_left_rounded),
            label: Text(prev.title),
          ),
        ),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: TextButton.icon(
              onPressed: () => context.replace('${Routes.signs}/${next.name}'),
              icon: const Icon(Icons.chevron_left_rounded),
              label: Text(next.title),
            ),
          ),
        ),
      ],
    );
  }
}

/// Найти профиль по имени из URL (`/signs/leo`).
ZodiacSign? signFromName(String? name) =>
    ZodiacSign.values.where((s) => s.name == name).firstOrNull;
