import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/astro/zodiac.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/firebase/analytics.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/element_colors.dart';
import '../../../core/user/user_profile.dart';
import '../../../core/widgets/astra_buttons.dart';
import '../../../core/widgets/constellation_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/ring_meter.dart';
import '../../../core/widgets/sub_page.dart';
import '../../today/presentation/widgets/share_button.dart';
import '../data/compat_pairs.dart';
import '../domain/sign_models.dart';

/// Совместимость двух знаков.
class CompatScreen extends ConsumerStatefulWidget {
  const CompatScreen({super.key, this.initialA, this.initialB});

  final ZodiacSign? initialA;
  final ZodiacSign? initialB;

  @override
  ConsumerState<CompatScreen> createState() => _CompatScreenState();
}

class _CompatScreenState extends ConsumerState<CompatScreen> {
  late ZodiacSign _a = widget.initialA ?? ref.read(userProfileProvider).sign ?? ZodiacSign.aries;
  late ZodiacSign _b = widget.initialB ?? ZodiacSign.values[(_a.index + 4) % 12];

  bool _picking = false;

  Future<void> _pick({required bool first}) async {
    if (_picking) return; // двойной тап не открывает две шторки
    _picking = true;
    try {
      await _pickSign(first: first);
    } finally {
      _picking = false;
    }
  }

  Future<void> _pickSign({required bool first}) async {
    ref.read(appFeedbackProvider).tap();
    final picked = await showModalBottomSheet<ZodiacSign>(
      context: context,
      backgroundColor: AppColors.deepViolet,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _SignPickerSheet(selected: first ? _a : _b),
    );
    if (picked == null) return;
    ref.read(appFeedbackProvider).reveal();
    setState(() => first ? _a = picked : _b = picked);
  }

  @override
  Widget build(BuildContext context) {
    final pair = compatPairs[pairKey(_a, _b)]!;
    final text = Theme.of(context).textTheme;
    final isGuest = ref.watch(authUserProvider).value == null;

    return SubPage(
      parent: Routes.signs,
      children: [
        const Text('СОВМЕСТИМОСТЬ', textAlign: TextAlign.center, style: AppTypography.overline),
        const SizedBox(height: 16),
        _PairHeader(
          a: _a,
          b: _b,
          overall: pair.overall,
          onTapA: () => _pick(first: true),
          onTapB: () => _pick(first: false),
        ),
        const SizedBox(height: 4),
        Text(
          'Коснись знака, чтобы выбрать другой',
          textAlign: TextAlign.center,
          style: text.labelSmall,
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Column(
            key: ValueKey(pairKey(_a, _b)),
            children: [
              Text(
                pair.title,
                textAlign: TextAlign.center,
                style: text.displaySmall!.copyWith(color: AppColors.goldBright),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RingMeter(value: pair.love, label: 'Любовь', color: AppColors.moonPink),
                  RingMeter(
                    value: pair.friendship,
                    label: 'Дружба',
                    color: AppColors.lavender,
                    delay: const Duration(milliseconds: 150),
                  ),
                  RingMeter(
                    value: pair.work,
                    label: 'Работа',
                    delay: const Duration(milliseconds: 300),
                  ),
                  RingMeter(
                    value: pair.passion,
                    label: 'Страсть',
                    color: AppColors.goldBright,
                    delay: const Duration(milliseconds: 450),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('О паре'),
                    const SizedBox(height: 12),
                    RevealText(
                      pair.summary,
                      wordDuration: const Duration(milliseconds: 25),
                      style: text.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('В чём ваша сила'),
                    const SizedBox(height: 10),
                    Text(pair.strength, style: text.bodyLarge),
                    const SizedBox(height: 18),
                    const SectionLabel('Над чем поработать'),
                    const SizedBox(height: 10),
                    Text(pair.growth, style: text.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '«${pair.advice}»',
                textAlign: TextAlign.center,
                style: AppTypography.quote.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 16),
              ShareButton(
                contentType: 'compatibility',
                text:
                    'Совместимость ${_a.title} и ${_b.title} в «Астре» — ${pair.overall}%.\n'
                    '«${pair.title}»: ${pair.advice}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isGuest)
          Center(
            child: SoftLink(
              label: 'Совместимость с реальным человеком — после входа',
              onTap: () {
                ref.read(analyticsProvider).signInPromptShown(source: 'compatibility');
                context.go(Routes.profile);
              },
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Совместимость знаков — повод для разговора, а не приговор ✦',
          textAlign: TextAlign.center,
          style: text.labelSmall,
        ),
      ],
    );
  }
}

/// Два созвездия, соединённые пульсирующей нитью, и общий процент.
class _PairHeader extends StatefulWidget {
  const _PairHeader({
    required this.a,
    required this.b,
    required this.overall,
    required this.onTapA,
    required this.onTapB,
  });

  final ZodiacSign a;
  final ZodiacSign b;
  final int overall;
  final VoidCallback onTapA;
  final VoidCallback onTapB;

  @override
  State<_PairHeader> createState() => _PairHeaderState();
}

class _PairHeaderState extends State<_PairHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => CustomPaint(painter: _ThreadPainter(_pulse.value)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _SignOrb(sign: widget.a, onTap: widget.onTapA),
              ),
              const SizedBox(width: 96),
              Expanded(
                child: _SignOrb(sign: widget.b, onTap: widget.onTapB),
              ),
            ],
          ),
          TweenAnimationBuilder<double>(
            key: ValueKey(widget.overall),
            tween: Tween(begin: 0, end: widget.overall.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.night,
                border: Border.all(color: AppColors.gold, width: 0.9),
                boxShadow: AppColors.goldGlow(0.6),
              ),
              child: Text(
                '${v.round()}%',
                style: AppTypography.textTheme.headlineMedium!.copyWith(
                  color: AppColors.goldBright,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOrb extends StatelessWidget {
  const _SignOrb({required this.sign, required this.onTap});

  final ZodiacSign sign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = sign.element.color;
    return Semantics(
      button: true,
      label: 'Выбрать знак, сейчас ${sign.title}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(sign),
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBottom,
                  border: Border.all(color: accent.withValues(alpha: 0.6), width: 0.8),
                ),
                child: ConstellationView(
                  constellation: sign.constellation,
                  starScale: 0.8,
                  color: accent,
                  duration: const Duration(milliseconds: 1400),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${sign.textGlyph} ${sign.title}',
              style: AppTypography.textTheme.titleLarge!.copyWith(fontSize: 19),
            ),
          ],
        ),
      ),
    );
  }
}

/// Золотая нить между знаками с бегущими искрами.
class _ThreadPainter extends CustomPainter {
  _ThreadPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final y = 56.0 + 8;
    final left = Offset(size.width * 0.25 + 40, y);
    final right = Offset(size.width * 0.75 - 40, y);
    final line = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x00E8C77A), AppColors.gold, Color(0x00E8C77A)],
      ).createShader(Rect.fromPoints(left.translate(0, -1), right.translate(0, 1)))
      ..strokeWidth = 0.9;
    canvas.drawLine(left, right, line);
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      final pos = Offset.lerp(left, right, p)!;
      final a = math.sin(math.pi * p);
      canvas.drawCircle(pos, 2.2, Paint()..color = AppColors.goldBright.withValues(alpha: a));
      canvas.drawCircle(
        pos,
        6,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.3 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_ThreadPainter old) => old.t != t;
}

class _SignPickerSheet extends StatelessWidget {
  const _SignPickerSheet({required this.selected});

  final ZodiacSign selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Выбери знак', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final s in ZodiacSign.values)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, s),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: s == selected ? AppColors.gold : AppColors.strokeSoft,
                          width: s == selected ? 1 : 0.6,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.textGlyph, style: TextStyle(color: s.element.color, fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(s.title, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
