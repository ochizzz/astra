import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

/// «Проявление» текста: слова возникают по очереди из лёгкой дымки.
///
/// Раскладка текста не меняется во время анимации (меняется только
/// прозрачность слов), поэтому строки не прыгают.
class RevealText extends StatefulWidget {
  const RevealText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.delay = Duration.zero,
    this.wordDuration = const Duration(milliseconds: 55),
    this.play = true,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Duration delay;

  /// Сдвиг старта между соседними словами.
  final Duration wordDuration;

  /// Если false — текст скрыт; при смене на true запускается анимация.
  final bool play;

  @override
  State<RevealText> createState() => _RevealTextState();
}

class _RevealTextState extends State<RevealText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<String> _words;

  static const _fadePerWord = 8.0; // слово проявляется за ~8 «шагов»

  @override
  void initState() {
    super.initState();
    _words = _split(widget.text);
    _controller = AnimationController(vsync: this, duration: _totalDuration());
    if (widget.play) _start();
  }

  List<String> _split(String text) => RegExp(r'\S+\s*').allMatches(text).map((m) => m[0]!).toList();

  Duration get _wordsDuration => widget.wordDuration * (_words.length + _fadePerWord).round();

  /// Задержка — часть длительности контроллера, а не отдельный таймер:
  /// так анимация корректно останавливается вместе с виджетом.
  Duration _totalDuration() => widget.delay + _wordsDuration;

  void _start() => _controller.forward(from: 0);

  @override
  void didUpdateWidget(RevealText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _words = _split(widget.text);
      _controller.duration = _totalDuration();
      if (widget.play) _start();
    } else if (!old.play && widget.play) {
      _start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(widget.style);
    final baseColor = base.color ?? Colors.white;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final steps = _words.length + _fadePerWord;
        final total = _controller.duration!.inMicroseconds;
        final elapsed = _controller.value * total - widget.delay.inMicroseconds;
        final t = MediaQuery.of(context).disableAnimations
            ? 1.0
            : (elapsed / _wordsDuration.inMicroseconds).clamp(0.0, 1.0);
        final progress = t * steps;
        return Text.rich(
          TextSpan(
            children: [
              for (var i = 0; i < _words.length; i++)
                TextSpan(
                  text: _words[i],
                  style: TextStyle(
                    color: baseColor.withValues(
                      alpha:
                          baseColor.a *
                          Curves.easeOut.transform(((progress - i) / _fadePerWord).clamp(0.0, 1.0)),
                    ),
                  ),
                ),
            ],
          ),
          style: base,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}

/// Плавное появление блока: из прозрачности, чуть снизу и из лёгкого размытия.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.offset = 24,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  )..forward();

  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMicroseconds / (widget.delay + widget.duration).inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        final blur = (1 - v) * 6;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.offset),
            child: blur < 0.05
                ? child
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: child,
                  ),
          ),
        );
      },
    );
  }
}

/// Медленное «дыхание» — лёгкое покачивание вверх-вниз, для карт и символов.
class Floating extends StatefulWidget {
  const Floating({super.key, required this.child, this.amplitude = 6});

  final Widget child;
  final double amplitude;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin(_c.value * 2 * math.pi) * widget.amplitude),
        child: child,
      ),
    );
  }
}
