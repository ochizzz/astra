import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Вложенный экран вкладки: кнопка «назад» и прокручиваемое содержимое
/// с отступом под нижнюю навигацию.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.parent,
    required this.children,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 0),
  });

  /// Куда вернуться, если в стеке нет предыдущего экрана.
  final String parent;
  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 96;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: padding.copyWith(
                top: padding.top + 52,
                bottom: padding.bottom + bottomInset,
              ),
              children: children,
            ),
            // Шапка поверх списка: текст мягко уходит под затемнение.
            Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.night.withValues(alpha: 0.95),
                    AppColors.night.withValues(alpha: 0.8),
                    AppColors.night.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.6, 1],
                ),
              ),
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Назад',
                      onPressed: () => context.canPop() ? context.pop() : context.go(parent),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      color: AppColors.textSecondary,
                    ),
                    const Spacer(),
                    ?trailing,
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
