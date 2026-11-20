import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'tap_guard.dart';

/// Основная кнопка: золотой градиент со свечением и мягким нажатием.
///
/// Если [onPressed] возвращает Future, кнопка блокируется до его завершения
/// и показывает индикатор — повторные нажатия не выполняют действие дважды.
class GoldButton extends StatefulWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final GuardedTap? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;
  final _guard = TapGuard();

  void _tap() {
    final action = widget.onPressed;
    if (action == null) return;
    _guard.run(
      action,
      onBusyChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _guard.busy;
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: enabled ? _tap : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.6,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: widget.expand ? double.infinity : null,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
              decoration: BoxDecoration(
                gradient: enabled ? AppColors.goldGradient : null,
                border: enabled ? null : Border.all(color: AppColors.stroke, width: 0.8),
                borderRadius: BorderRadius.circular(30),
                boxShadow: enabled ? AppColors.goldGlow(_pressed ? 0.5 : 0.8) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy) ...[
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.6, color: AppColors.night),
                    ),
                    const SizedBox(width: 10),
                  ] else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: enabled ? AppColors.night : AppColors.goldDim,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.labelLarge!.copyWith(
                        color: enabled ? AppColors.night : AppColors.goldDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Второстепенная кнопка: прозрачная с тонкой золотой каймой.
/// Защищена от повторных нажатий так же, как [GoldButton].
class GhostButton extends StatefulWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final GuardedTap? onPressed;
  final Widget? icon;
  final bool expand;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  final _guard = TapGuard();

  @override
  Widget build(BuildContext context) {
    final action = widget.onPressed;
    return SizedBox(
      width: widget.expand ? double.infinity : null,
      child: OutlinedButton(
        onPressed: action == null || _guard.busy
            ? null
            : () => _guard.run(
                action,
                onBusyChanged: () {
                  if (mounted) setState(() {});
                },
              ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          disabledForegroundColor: AppColors.goldDim,
          side: const BorderSide(color: AppColors.stroke, width: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_guard.busy) ...[
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 1.4, color: AppColors.gold),
              ),
              const SizedBox(width: 10),
            ] else if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(widget.label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

/// Текстовая ссылка-приглашение: «Уточнить по времени рождения →».
class SoftLink extends StatefulWidget {
  const SoftLink({super.key, required this.label, required this.onTap});

  final String label;
  final GuardedTap onTap;

  @override
  State<SoftLink> createState() => _SoftLinkState();
}

class _SoftLinkState extends State<SoftLink> {
  final _guard = TapGuard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _guard.run(
        widget.onTap,
        onBusyChanged: () {
          if (mounted) setState(() {});
        },
      ),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _guard.busy ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  style: AppTypography.textTheme.bodyMedium!.copyWith(
                    color: AppColors.lavender,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.lavender),
            ],
          ),
        ),
      ),
    );
  }
}
