import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Шрифты: Cormorant Garamond — заголовки, Manrope — текст.
abstract final class AppFonts {
  static const display = 'CormorantGaramond';
  static const body = 'Manrope';

  /// Резервные шрифты для символов, которых нет в основных гарнитурах.
  static const symbolFallback = ['AstraSymbols', 'AstraSymbolsStars'];
}

abstract final class AppTypography {
  static const _display = TextStyle(
    fontFamily: AppFonts.display,
    fontFamilyFallback: AppFonts.symbolFallback,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static const _body = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.symbolFallback,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextTheme get textTheme => TextTheme(
    displayLarge: _display.copyWith(fontSize: 56, fontWeight: FontWeight.w500),
    displayMedium: _display.copyWith(fontSize: 44, fontWeight: FontWeight.w500),
    displaySmall: _display.copyWith(fontSize: 36, fontWeight: FontWeight.w500),
    headlineLarge: _display.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
    headlineMedium: _display.copyWith(fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall: _display.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: _display.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: _body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: _body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: _body.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: _body.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: _body.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    labelLarge: _body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.4),
    labelMedium: _body.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
      color: AppColors.gold,
    ),
    labelSmall: _body.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6,
      color: AppColors.textMuted,
    ),
  );

  /// Курсив для цитат.
  static const quote = TextStyle(
    fontFamily: AppFonts.display,
    fontFamilyFallback: AppFonts.symbolFallback,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    fontSize: 24,
    height: 1.3,
    color: AppColors.moonPink,
  );

  /// Надпись-«оверлайн» над секцией: ЦИТАТА ДНЯ, ГОРОСКОП и т.п.
  static const overline = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.symbolFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.4,
    color: AppColors.gold,
  );
}
