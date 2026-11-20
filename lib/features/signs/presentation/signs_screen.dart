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
import '../../../core/widgets/tab_page.dart';

/// Вкладка «Знаки»: вход в совместимость и галерея 12 созвездий.
class SignsScreen extends ConsumerWidget {
  const SignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySign = ref.watch(userProfileProvider.select((p) => p.sign));
    // Свой знак — первым.
    final signs = [?mySign, ...ZodiacSign.values.where((s) => s != mySign)];

    return TabPage(
      overline: '12 созвездий',
      title: 'Знаки',
      children: [
        FadeSlideIn(child: _CompatBanner(mySign: mySign)),
        const SizedBox(height: 24),
        const SectionLabel('Профили знаков'),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.74,
          ),
          itemCount: signs.length,
          itemBuilder: (context, i) => FadeSlideIn(
            delay: Duration(milliseconds: 60 * i),
            child: SignTile(
              sign: signs[i],
              isMine: signs[i] == mySign,
              onTap: () {
                ref.read(appFeedbackProvider).tap();
                context.go('${Routes.signs}/${signs[i].name}');
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CompatBanner extends ConsumerWidget {
  const _CompatBanner({required this.mySign});

  final ZodiacSign? mySign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      glow: true,
      onTap: () {
        ref.read(appFeedbackProvider).tap();
        context.go(Routes.compat);
      },
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 56,
            child: Stack(
              children: [
                _GlyphCircle(glyph: (mySign ?? ZodiacSign.leo).textGlyph, left: 0),
                const _GlyphCircle(glyph: '✦', left: 26),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Совместимость', style: text.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  'Любовь, дружба, работа и страсть для любой пары знаков',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.gold),
        ],
      ),
    );
  }
}

class _GlyphCircle extends StatelessWidget {
  const _GlyphCircle({required this.glyph, required this.left});

  final String glyph;
  final double left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 2,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.deepViolet,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 0.8),
        ),
        child: Text(glyph, style: const TextStyle(color: AppColors.gold, fontSize: 22)),
      ),
    );
  }
}

/// Плитка знака: созвездие, символ, название и период.
class SignTile extends StatelessWidget {
  const SignTile({super.key, required this.sign, required this.onTap, this.isMine = false});

  final ZodiacSign sign;
  final VoidCallback onTap;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final accent = sign.element.color;
    return Semantics(
      button: true,
      label: '${sign.title}${isMine ? ', твой знак' : ''}',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(accent.withValues(alpha: 0.10), AppColors.cardTop),
                  AppColors.cardBottom,
                ],
              ),
              border: Border.all(
                color: isMine ? AppColors.gold : accent.withValues(alpha: 0.28),
                width: isMine ? 1 : 0.7,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  child: Column(
                    children: [
                      Expanded(
                        child: ConstellationView(
                          constellation: sign.constellation,
                          animate: false,
                          starScale: 0.55,
                          strokeWidth: 0.8,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sign.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.titleLarge!.copyWith(fontSize: 18),
                      ),
                      Text(sign.textGlyph, style: TextStyle(color: accent, fontSize: 13)),
                    ],
                  ),
                ),
                if (isMine)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ты',
                        style: AppTypography.overline.copyWith(
                          color: AppColors.night,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
