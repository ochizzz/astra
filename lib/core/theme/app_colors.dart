import 'package:material_ui/material_ui.dart';

/// Палитра «Астры». Все цвета приложения берутся только отсюда.
abstract final class AppColors {
  // Фон: ночное небо
  static const night = Color(0xFF0B0B1E);
  static const dusk = Color(0xFF2A1B4D);
  static const deepViolet = Color(0xFF17112F);

  // Акценты
  static const gold = Color(0xFFE8C77A);
  static const goldBright = Color(0xFFFFE3A3);
  static const goldDim = Color(0xFFA88C4E);
  static const lavender = Color(0xFFB9A3F0);
  static const moonPink = Color(0xFFF3D9E8);

  // Карточки: плотный тёмно-фиолетовый фон, звёзды лишь слегка просвечивают,
  // чтобы текст не смешивался с небом.
  static const cardTop = Color(0xE6231A48);
  static const cardBottom = Color(0xEB140E2D);

  // Текст
  static const textPrimary = Color(0xFFF5EFFF);
  static const textSecondary = Color(0xFFB8B0D0);
  static const textMuted = Color(0xFF7D769A);

  // Поверхности (стекло поверх неба)
  static const surface = Color(0x1AFFFFFF);
  static const surfaceStrong = Color(0x26FFFFFF);
  static const stroke = Color(0x33E8C77A);
  static const strokeSoft = Color(0x1FFFFFFF);

  static const skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [night, deepViolet, dusk],
    stops: [0.0, 0.55, 1.0],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldBright, gold, goldDim],
  );

  /// Мягкое золотое свечение для карточек, кнопок и иконок.
  static List<BoxShadow> goldGlow([double strength = 1]) => [
    BoxShadow(
      color: gold.withValues(alpha: 0.35 * strength),
      blurRadius: 24 * strength,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: gold.withValues(alpha: 0.12 * strength),
      blurRadius: 60 * strength,
      spreadRadius: 6,
    ),
  ];
}
