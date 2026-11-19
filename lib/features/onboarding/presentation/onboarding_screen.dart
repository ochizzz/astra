import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/astro/zodiac.dart';
import '../../../core/firebase/analytics.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/user/user_profile.dart';
import '../../../core/widgets/astra_buttons.dart';
import '../../../core/widgets/card_faces.dart';
import '../../../core/widgets/constellation_view.dart';
import '../../../core/widgets/flip_card.dart';
import '../../../core/widgets/reveal.dart';
import 'widgets/birth_date_wheel.dart';

enum _Step { welcome, birthDate, sign, card }

/// Знакомство: приветствие → дата рождения → знак → «твоя карта».
/// Вход в аккаунт предлагается мягко на последнем шаге и его можно пропустить.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  late DateTime _birthDate =
      ref.read(userProfileProvider).birthDate ?? DateTime(DateTime.now().year - 22, 6, 15);

  ZodiacSign get _sign => ZodiacSign.fromDate(_birthDate);

  void _go(_Step step) {
    ref.read(appFeedbackProvider).tap();
    setState(() => _step = step);
  }

  Future<void> _confirmDate() async {
    await ref.read(userProfileProvider.notifier).setBirthDate(_birthDate);
    ref.read(appFeedbackProvider).reveal();
    setState(() => _step = _Step.sign);
  }

  Future<void> _finish() async {
    ref.read(appFeedbackProvider).success();
    await ref.read(userProfileProvider.notifier).completeOnboarding();
    ref.read(analyticsProvider).onboardingCompleted(sign: _sign.name);
    if (mounted) context.go(Routes.today);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_Step.values[_step.index - 1]);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                step: _step.index,
                total: _Step.values.length,
                onBack: _step == _Step.welcome ? null : () => _go(_Step.values[_step.index - 1]),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.97, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      _Step.welcome => _WelcomeStep(onNext: () => _go(_Step.birthDate)),
                      _Step.birthDate => _BirthDateStep(
                        date: _birthDate,
                        onChanged: (d) => setState(() => _birthDate = d),
                        onNext: _confirmDate,
                      ),
                      _Step.sign => _SignStep(sign: _sign, onNext: () => _go(_Step.card)),
                      _Step.card => _CardStep(sign: _sign, onFinish: _finish),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.total, this.onBack});

  final int step;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                tooltip: 'Назад',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: AppColors.textSecondary,
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == step ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i <= step ? AppColors.gold : AppColors.strokeSoft,
                    boxShadow: i == step ? AppColors.goldGlow(0.3) : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.children, required this.actions});

  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: children),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...actions,
        ],
      ),
    );
  }
}

// ─── Шаг 1. Приветствие ────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _StepLayout(
      actions: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 1600),
          child: GoldButton(label: 'Начать знакомство', onPressed: onNext),
        ),
      ],
      children: [
        const Floating(child: SizedBox(width: 160, height: 160, child: _AstraEmblem())),
        const SizedBox(height: 32),
        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          child: ShaderMask(
            shaderCallback: AppColors.goldGradient.createShader,
            child: Text(
              'Астра',
              style: text.displayLarge!.copyWith(
                fontSize: 64,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        RevealText(
          'Звёзды знают о тебе чуть больше, чем кажется. Давай познакомимся.',
          delay: const Duration(milliseconds: 800),
          textAlign: TextAlign.center,
          style: text.bodyLarge!.copyWith(color: AppColors.textSecondary, fontSize: 17),
        ),
      ],
    );
  }
}

/// Логотип: созвездие-звезда в кольце.
class _AstraEmblem extends StatelessWidget {
  const _AstraEmblem();

  static const _star = Constellation(
    [
      Offset(0.5, 0.08),
      Offset(0.62, 0.38),
      Offset(0.92, 0.5),
      Offset(0.62, 0.62),
      Offset(0.5, 0.92),
      Offset(0.38, 0.62),
      Offset(0.08, 0.5),
      Offset(0.38, 0.38),
      Offset(0.5, 0.5),
    ],
    [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0)],
    brightest: 8,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 0.7),
            boxShadow: AppColors.goldGlow(0.4),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(22),
          child: ConstellationView(constellation: _star, starScale: 1.1),
        ),
      ],
    );
  }
}

// ─── Шаг 2. Дата рождения ──────────────────────────────────────────────

class _BirthDateStep extends ConsumerWidget {
  const _BirthDateStep({required this.date, required this.onChanged, required this.onNext});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final sign = ZodiacSign.fromDate(date);
    final now = DateTime.now();
    return _StepLayout(
      actions: [GoldButton(label: 'Дальше', onPressed: onNext)],
      children: [
        Text('Твоя дата рождения', style: text.headlineLarge, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          'По ней мы найдём твой знак. Время и место можно добавить позже — '
          'для асцендента и Луны.',
          textAlign: TextAlign.center,
          style: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        BirthDateWheel(
          initial: date,
          firstYear: 1940,
          lastYear: now.year - 6,
          onChanged: onChanged,
          onTick: ref.read(appFeedbackProvider).tap,
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: Row(
            key: ValueKey(sign),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sign.textGlyph, style: const TextStyle(color: AppColors.gold, fontSize: 22)),
              const SizedBox(width: 10),
              Text(sign.title, style: text.titleLarge!.copyWith(color: AppColors.goldBright)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Шаг 3. Знак ───────────────────────────────────────────────────────

class _SignStep extends StatelessWidget {
  const _SignStep({required this.sign, required this.onNext});

  final ZodiacSign sign;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _StepLayout(
      actions: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 2400),
          child: GoldButton(label: 'Открыть мою карту', onPressed: onNext),
        ),
      ],
      children: [
        SizedBox(
          width: 230,
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.stroke, width: 0.7),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: ConstellationView(constellation: sign.constellation, starScale: 1.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        FadeSlideIn(
          delay: const Duration(milliseconds: 900),
          child: Column(
            children: [
              const Text('ТВОЙ ЗНАК', style: AppTypography.overline),
              const SizedBox(height: 8),
              Text(
                '${sign.textGlyph}  ${sign.title}',
                style: text.displayMedium!.copyWith(color: AppColors.goldBright),
              ),
              const SizedBox(height: 6),
              Text(sign.period, style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 1300),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [_Chip('Стихия · ${sign.element.title}'), _Chip('Планета · ${sign.ruler}')],
          ),
        ),
        const SizedBox(height: 20),
        RevealText(
          'Твои слова-ключи: ${sign.keywords.join(', ')}.',
          delay: const Duration(milliseconds: 1700),
          textAlign: TextAlign.center,
          style: AppTypography.quote.copyWith(fontSize: 21),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke, width: 0.7),
        color: AppColors.surface,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

// ─── Шаг 4. Твоя карта ─────────────────────────────────────────────────

class _CardStep extends ConsumerStatefulWidget {
  const _CardStep({required this.sign, required this.onFinish});

  final ZodiacSign sign;
  final VoidCallback onFinish;

  @override
  ConsumerState<_CardStep> createState() => _CardStepState();
}

class _CardStepState extends ConsumerState<_CardStep> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sign = widget.sign;
    return _StepLayout(
      actions: [
        AnimatedOpacity(
          opacity: _flipped ? 1 : 0,
          duration: const Duration(milliseconds: 600),
          child: IgnorePointer(
            ignoring: !_flipped,
            child: Column(
              children: [
                GoldButton(label: 'К звёздам', onPressed: widget.onFinish),
                const SizedBox(height: 12),
                GhostButton(
                  label: 'Сохранить в аккаунте Google',
                  onPressed: () {
                    ref.read(analyticsProvider).signInPromptShown(source: 'onboarding');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Вход появится совсем скоро. Пока всё бережно хранится на устройстве.',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text('Вход необязателен — можно войти позже в профиле', style: text.labelSmall),
              ],
            ),
          ),
        ),
      ],
      children: [
        Text('Твоя карта', style: text.headlineLarge),
        const SizedBox(height: 8),
        Text(
          _flipped ? ' ' : 'Коснись карты, чтобы открыть её',
          style: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        FlipCard(
          width: 200,
          flipped: _flipped,
          onFlip: () {
            ref.read(appFeedbackProvider).reveal();
            setState(() => _flipped = true);
          },
          back: const CardBack(hint: 'КОСНИСЬ'),
          front: StarCardFront(
            number: sign.index + 1,
            title: sign.title,
            subtitle: '${sign.element.title} · ${sign.ruler}',
            emblem: ConstellationView(
              constellation: sign.constellation,
              animate: false,
              starScale: 0.8,
            ),
          ),
        ),
        RevealText(
          'Каждый день здесь тебя будет ждать карта дня, тёплая цитата и вопрос '
          'для размышлений.',
          play: _flipped,
          delay: const Duration(milliseconds: 700),
          textAlign: TextAlign.center,
          style: text.bodyLarge!.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
