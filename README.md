# Астра ✦

Мобильное приложение о зодиаке, самопознании и отношениях.
Flutter (Android + iOS) · Riverpod · go_router · Firebase.

> Концепция — [docs/CONCEPT.md](docs/CONCEPT.md) · границы продукта — [docs/SCOPE.md](docs/SCOPE.md) ·
> бизнес-модель — [docs/BUSINESS_MODEL.md](docs/BUSINESS_MODEL.md) · план — [docs/ROADMAP.md](docs/ROADMAP.md) ·
> Firebase — [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).

## Быстрый старт

```bash
flutter pub get
flutter run            # работает без Firebase — на моковом контенте
```

Требования: Flutter 3.50+ (Dart 3.14+), Android 7.0+ (minSdk 24).

```bash
flutter analyze
flutter test
# скриншоты экранов для ревью дизайна:
flutter test test/screenshots --dart-define=SCREENSHOT_DIR=$PWD/build/shots
```

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
  fonts/                    # Cormorant Garamond, Manrope, Noto Sans Symbols (OFL)
functions/                  # Cloud Functions (TypeScript): Звёздный круг, удаление данных, натальная карта
firestore.rules             # правила доступа Firestore
docs/
```

Каждая фича: `data/` (репозитории, моки) → `domain/` (модели) → `presentation/` (экраны, виджеты).
Состояние — Riverpod (`Notifier`/`FutureProvider`), навигация — go_router
(`StatefulShellRoute` для 5 вкладок, редирект на онбординг).

## Астрономия и лицензии

- Фаза и знак Луны — офлайн, свои формулы Миуса (`lib/core/astro/moon_phase.dart`).
- Натальная карта и асцендент — Cloud Function на Astronomy Engine (MIT).
- Swiss Ephemeris не используется (AGPL).

## Этапы

- [x] Каркас проекта, тема, шрифты, навигация
- [x] Онбординг
- [x] Вкладка «Сегодня» (моковый контент, анимации)
- [x] Подготовка Firebase
- [ ] MVP: знаки и совместимость, лунный календарь, 3 теста, мини-игра, дневник, вход Google, AdMob
- [ ] 1.1 / 2.0 — см. концепцию

Контент носит развлекательный характер.
