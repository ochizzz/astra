import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/sign_in_ui.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/astra_buttons.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/sub_page.dart';
import '../../today/presentation/widgets/share_button.dart';
import '../data/tests_repository.dart';
import '../domain/test_models.dart';

/// Прохождение теста: вопрос за вопросом, затем карточка результата.
class TestRunScreen extends ConsumerStatefulWidget {
  const TestRunScreen({super.key, required this.test});

  final AstraTest test;

  @override
  ConsumerState<TestRunScreen> createState() => _TestRunScreenState();
}

class _TestRunScreenState extends ConsumerState<TestRunScreen> {
  int _index = 0;
  final _totals = <String, int>{};
  final _history = <Map<String, int>>[];
  TestResult? _result;
  bool _inputLocked = false;
  Timer? _unlockTimer;

  static const _switchDuration = Duration(milliseconds: 450);

  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }

  /// [question] — номер вопроса, на который отвечают. Пока идёт анимация
  /// смены вопроса, старый вопрос ещё на экране; нажатие на него (или
  /// двойной тап) не должно засчитываться ответом на следующий вопрос.
  void _answer(int question, TestAnswer a) {
    if (question != _index || _result != null || _inputLocked) return;
    // Пока новый вопрос «въезжает», ввод закрыт: иначе второй тап по тому же
    // месту экрана засчитается ответом на следующий вопрос.
    _inputLocked = true;
    _unlockTimer?.cancel();
    _unlockTimer = Timer(_switchDuration, () => _inputLocked = false);
    ref.read(appFeedbackProvider).tap();
    _history.add(a.scores);
    a.scores.forEach((k, v) => _totals[k] = (_totals[k] ?? 0) + v);
    if (_index + 1 < widget.test.questions.length) {
      setState(() => _index++);
      return;
    }
    final result = widget.test.resultFor(_totals);
    ref.read(testResultsProvider.notifier).save(widget.test.id, result.id);
    ref.read(appFeedbackProvider).reveal();
    setState(() => _result = result);
  }

  void _back() {
    if (_history.isEmpty) return;
    _history.removeLast().forEach((k, v) => _totals[k] = (_totals[k] ?? 0) - v);
    setState(() => _index--);
  }

  void _restart() => setState(() {
    _index = 0;
    _totals.clear();
    _history.clear();
    _result = null;
  });

  @override
  Widget build(BuildContext context) {
    final test = widget.test;
    final result = _result;
    // Номер вопроса фиксируем при построении: у уходящего (анимируемого)
    // вопроса останется старый номер, и его ответы будут проигнорированы.
    final question = _index;
    return SubPage(
      parent: Routes.tests,
      trailing: result == null && _index > 0
          ? TextButton(onPressed: _back, child: const Text('Назад к вопросу'))
          : null,
      children: [
        Text(test.title.toUpperCase(), textAlign: TextAlign.center, style: AppTypography.overline),
        const SizedBox(height: 16),
        _ProgressStars(
          total: test.questions.length,
          done: result == null ? _index : test.questions.length,
        ),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: _switchDuration,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: result == null
              ? _QuestionView(
                  key: ValueKey(_index),
                  number: _index + 1,
                  question: test.questions[_index],
                  onAnswer: (a) => _answer(question, a),
                )
              : _ResultView(
                  key: const ValueKey('result'),
                  test: test,
                  result: result,
                  onRestart: _restart,
                ),
        ),
      ],
    );
  }
}

/// Прогресс: звёзды-созвездие, каждая отвеченная зажигается.
class _ProgressStars extends StatelessWidget {
  const _ProgressStars({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: i < done ? 9 : 6,
            height: i < done ? 9 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done ? AppColors.goldBright : AppColors.strokeSoft,
              boxShadow: i < done ? AppColors.goldGlow(0.3) : null,
            ),
          ),
          if (i < total - 1)
            Container(
              width: 18,
              height: 0.7,
              color: i < done - 1 ? AppColors.gold.withValues(alpha: 0.7) : AppColors.strokeSoft,
            ),
        ],
      ],
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    super.key,
    required this.number,
    required this.question,
    required this.onAnswer,
  });

  final int number;
  final TestQuestion question;
  final ValueChanged<TestAnswer> onAnswer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Вопрос $number', textAlign: TextAlign.center, style: text.labelSmall),
        const SizedBox(height: 8),
        Text(question.text, textAlign: TextAlign.center, style: text.headlineLarge),
        const SizedBox(height: 28),
        for (final (i, a) in question.answers.indexed) ...[
          FadeSlideIn(
            delay: Duration(milliseconds: 120 + 70 * i),
            offset: 12,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              onTap: () => onAnswer(a),
              child: Text(a.text, style: text.bodyLarge),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({super.key, required this.test, required this.result, required this.onRestart});

  final AstraTest test;
  final TestResult result;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final isGuest = ref.watch(authUserProvider).value == null;
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.night,
            border: Border.all(color: AppColors.gold, width: 0.9),
            boxShadow: AppColors.goldGlow(0.9),
          ),
          child: Text(
            result.symbol,
            style: const TextStyle(color: AppColors.goldBright, fontSize: 48),
          ),
        ),
        const SizedBox(height: 20),
        const Text('ТВОЙ РЕЗУЛЬТАТ', style: AppTypography.overline),
        const SizedBox(height: 8),
        Text(
          result.title,
          textAlign: TextAlign.center,
          style: text.displayMedium!.copyWith(color: AppColors.goldBright),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: RevealText(
            result.description,
            delay: const Duration(milliseconds: 400),
            wordDuration: const Duration(milliseconds: 25),
            style: text.bodyLarge,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '«${result.advice}»',
          textAlign: TextAlign.center,
          style: AppTypography.quote.copyWith(fontSize: 21),
        ),
        const SizedBox(height: 20),
        ShareButton(
          contentType: 'test_result',
          text:
              'Мой результат теста «${test.title}» в «Астре» — ${result.title} ${result.symbol}\n'
              '${result.advice}',
        ),
        const SizedBox(height: 12),
        if (isGuest) ...[
          // Мягкое приглашение войти — после результата, как в концепции.
          SoftLink(
            label: 'Сохранить результат в аккаунте',
            onTap: () => signInWithGoogleUi(context, ref, source: 'test_result'),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: GhostButton(label: 'Пройти снова', onPressed: onRestart),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GhostButton(label: 'Другие тесты', onPressed: () => context.go(Routes.tests)),
            ),
          ],
        ),
      ],
    );
  }
}
