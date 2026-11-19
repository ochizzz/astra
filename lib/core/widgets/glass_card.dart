import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Карточка поверх звёздного неба: плотный тёмный фон (≈90% непрозрачности)
/// и тонкая золотая кайма.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.glow = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final VoidCallback? onTap;

  static const radius = BorderRadius.all(Radius.circular(28));

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: glow
              ? [
                  Color.alphaBlend(AppColors.gold.withValues(alpha: 0.10), AppColors.cardTop),
                  AppColors.cardBottom,
                ]
              : const [AppColors.cardTop, AppColors.cardBottom],
        ),
        // Тень под полупрозрачной карточкой просвечивает и «грязнит» фон,
        // поэтому «свечение» здесь — это золотой отлив и более яркая кайма.
        border: Border.all(
          color: glow ? AppColors.gold.withValues(alpha: 0.55) : AppColors.stroke,
          width: 0.7,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(borderRadius: radius, onTap: onTap, child: card),
    );
  }
}

/// Надпись над секцией: «ЦИТАТА ДНЯ», с маленькой звёздочкой.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('✦', style: TextStyle(color: AppColors.gold, fontSize: 10)),
        const SizedBox(width: 8),
        Expanded(child: Text(text.toUpperCase(), style: AppTypography.overline)),
        ?trailing,
      ],
    );
  }
}

/// Тонкая золотая разделительная линия с ромбом посередине.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    Widget line(bool reverse) => Expanded(
      child: Container(
        height: 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gold.withValues(alpha: 0), AppColors.gold.withValues(alpha: 0.6)],
          ),
        ),
        transform: reverse ? (Matrix4.identity()..scaleByDouble(-1, 1, 1, 1)) : null,
        transformAlignment: Alignment.center,
      ),
    );
    return Row(
      children: [
        line(false),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('◆', style: TextStyle(color: AppColors.gold, fontSize: 7)),
        ),
        line(true),
      ],
    );
  }
}
