# Астра ✦

Мобильное приложение о зодиаке, самопознании и отношениях.
Flutter (Android + iOS) · Riverpod · go_router · Firebase.

> Полная концепция продукта — в [docs/CONCEPT.md](docs/CONCEPT.md).
> Настройка Firebase — в [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).

## Быстрый старт

```bash
flutter pub get
flutter run            # работает без Firebase — на моковом контенте
```

Требования: Flutter 3.38+ (Dart 3.10+), Android SDK 24+.

## Структура

```
lib/
  main.dart                 # точка входа, ProviderScope
  app/
    app.dart                # MaterialApp.router
    router.dart             # go_router: онбординг + 5 вкладок (StatefulShellRoute)
    shell.dart              # нижняя навигация
  core/
    theme/                  # цвета, типографика, ThemeData
    widgets/                # общие виджеты: звёздное небо, свечение, кнопки, иконки
    astro/                  # знаки зодиака, фаза Луны (Миус, офлайн)
    services/               # локальное хранилище, haptics/звук
    firebase/               # подготовка к подключению Firebase
  features/
    onboarding/             # дата рождения → знак → «твоя карта»
    today/                  # карта дня, цитата, гороскоп, вопрос, Луна
    signs/                  # (заготовка) профили знаков, совместимость
    tests/                  # (заготовка) тесты и мини-игры
    diary/                  # (заготовка) дневник, лунный календарь
    profile/                # (заготовка) профиль, вход, настройки
assets/
  fonts/                    # Cormorant Garamond, Manrope (OFL)
docs/
```

Каждая фича: `data/` (репозитории, моки) → `domain/` (модели) → `presentation/` (экраны, виджеты, провайдеры).

## Этапы

- [x] Каркас проекта, тема, шрифты, навигация
- [x] Онбординг
- [x] Вкладка «Сегодня» (моковый контент, анимации)
- [x] Подготовка Firebase
- [ ] MVP: знаки и совместимость, лунный календарь, 3 теста, мини-игра, дневник, вход Google, AdMob
- [ ] 1.1 / 2.0 — см. концепцию

Контент носит развлекательный характер.
