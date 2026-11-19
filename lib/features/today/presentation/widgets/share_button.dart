import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/firebase/analytics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/line_icons.dart';

/// Поделиться текстом. В 1.1 заменится на генерацию картинки 9:16
/// для Stories (RepaintBoundary → PNG → share).
class ShareButton extends ConsumerWidget {
  const ShareButton({super.key, required this.text, required this.contentType});

  final String text;
  final String contentType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () async {
        ref.read(analyticsProvider).shared(contentType: contentType);
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.stroke, width: 0.7)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      icon: const LineIcon(AstraIcon.share, size: 18),
      label: const Text('Поделиться'),
    );
  }
}
