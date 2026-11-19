import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';
import 'line_icons.dart';
import 'reveal.dart';

/// Базовая раскладка вкладки: заголовок в стиле «Астры» и прокручиваемое
/// содержимое с отступом под нижнюю навигацию.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    this.overline,
    this.trailing,
    required this.children,
  });

  final String title;
  final String? overline;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 96;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overline != null) ...[
                      Text(overline!.toUpperCase(), style: AppTypography.overline),
                      const SizedBox(height: 6),
                    ],
                    Text(title, style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

/// Заглушка раздела, который появится на следующих этапах.
class ComingSoon extends StatelessWidget {
  const ComingSoon({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.features,
  });

  final String title;
  final AstraIcon icon;
  final String description;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return TabPage(
      overline: 'Скоро',
      title: title,
      children: [
        FadeSlideIn(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Floating(amplitude: 4, child: LineIcon(icon, size: 44, strokeWidth: 1)),
                const SizedBox(height: 16),
                Text(description, style: text.bodyLarge),
                const SizedBox(height: 20),
                const OrnamentDivider(),
                const SizedBox(height: 16),
                for (final f in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Text('✦', style: TextStyle(color: AppColors.gold, fontSize: 10)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f,
                            style: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
