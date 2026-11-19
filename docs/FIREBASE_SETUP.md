# Подключение Firebase

Приложение уже готово к Firebase, но **работает и без него**: пока в
`lib/firebase_options.dart` заглушка, весь контент моковый, а данные хранятся
на устройстве. Как только конфигурация появится, `FirebaseBootstrap`
поднимет Firebase и Crashlytics, а аналитика начнёт отправлять события.

## Что уже сделано в репозитории

| Что | Где |
|---|---|
| Инициализация без падений, если Firebase не настроен | `lib/core/firebase/firebase_bootstrap.dart` |
| Crashlytics (в debug выключен) | там же |
| Обёртка аналитики, список событий | `lib/core/firebase/analytics.dart` |
| Правила Firestore | `firestore.rules` |
| Конфиг Firebase CLI и эмуляторов | `firebase.json` |
| Cloud Functions (TypeScript, Node 22, регион `europe-west1`) | `functions/` |
| — `setStarCircle` / `matchContacts` — «Звёздный круг» по хэшам | `functions/src/star_circle.ts` |
| — `cleanupDeletedUser` — удаление всех данных при удалении аккаунта | `functions/src/account.ts` |
| — `natalChart` — планеты и асцендент (Astronomy Engine, MIT) | `functions/src/natal.ts` |

## Что нужно от вас

### Сейчас (для MVP)

1. **Подтвердить идентификатор приложения** — `app.astra.mobile`
   (Android applicationId и iOS bundle id). После первой публикации в Google
   Play его нельзя изменить. Если нужен другой (например, на ваш домен) —
   скажите, поменяю.
2. **Создать проект Firebase** в [console.firebase.google.com](https://console.firebase.google.com)
   и сообщить его **Project ID**.
   - Тариф **Blaze** (оплата по факту) — без него не работают Cloud Functions.
     Для старта расходы обычно в пределах бесплатных квот.
   - Включить **Google Analytics** при создании проекта.
3. **Сгенерировать конфигурацию** (из корня репозитория, на своём компьютере):
   ```bash
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --project=<PROJECT_ID> \
     --platforms=android,ios \
     --android-package-name=app.astra.mobile \
     --ios-bundle-id=app.astra.mobile
   ```
   Команда перезапишет `lib/firebase_options.dart`, создаст
   `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
   и подключит Gradle-плагины. Эти файлы можно коммитить — это не секреты
   (ключи в них ограничиваются по приложению и App Check).
   *Альтернатива:* пришлите мне содержимое `google-services.json` и
   `GoogleService-Info.plist` — я сам добавлю их и `firebase_options.dart`.
4. **SHA-1 и SHA-256 отпечатки** для входа через Google — добавить в
   настройки Android-приложения в Firebase:
   - debug: `cd android && ./gradlew signingReport`;
   - release: из Play Console → Настройка → Целостность приложения
     (ключ App Signing **и** ключ загрузки).
5. **Authentication → Sign-in method:** включить **Google**.
6. **Firestore:** создать базу в режиме production, регион `eur3` (Европа)
   или ближайший к аудитории. Затем задеплоить правила и функции:
   ```bash
   firebase use <PROJECT_ID>
   firebase deploy --only firestore:rules,functions
   ```
7. **Crashlytics:** открыть раздел в консоли и нажать «Включить».
8. **App Check:** зарегистрировать Android-приложение с провайдером
   **Play Integrity** (функции уже требуют App Check — `enforceAppCheck: true`).

### Позже (1.1 и 2.0)

| Этап | Что понадобится |
|---|---|
| MVP, реклама | AdMob: **App ID** (`ca-app-pub-…~…`) и ID рекламных блоков (баннер, межстраничный, с вознаграждением) |
| 1.1, Премиум | RevenueCat: **публичные SDK-ключи** для Android/iOS; продукты подписки в Play Console; Google Play service account для RevenueCat (передаётся в RevenueCat, не в репозиторий) |
| 1.1, пуши | Для iOS — APNs-ключ (.p8) в настройках Cloud Messaging |
| 2.0, вход по телефону | Включить **Phone** в Authentication, тестовые номера для разработки; App Check обязателен (защита от SMS-фрода) |
| 2.0, iOS | Apple Developer Program; **Sign in with Apple** (Services ID, ключ .p8, Team ID) — обязателен в App Store при наличии входа через Google |
| Публикация | Аккаунт Google Play Console; **URL политики конфиденциальности**; **веб-страница удаления аккаунта** (нужен домен или Firebase Hosting); e-mail поддержки |

**Не присылайте в чат и не коммитьте:** ключ подписи (`.jks`), пароли к нему,
JSON сервисных аккаунтов, секретные ключи RevenueCat, `.p8`-ключи Apple. Их
лучше хранить в секретах CI или передавать напрямую в соответствующие
консоли.

## Модель данных Firestore

```
content/{type}/items/{id}        # cards, quotes, questions, tests, signs — только чтение
horoscopes/{yyyy-MM-dd}/signs/{sign}   # общие гороскопы на день — только чтение

users/{uid}                      # профиль: birthDate, birthTime?, birthPlace{name,lat,lon,tz}?,
                                 # sign, publicName?; сервер: premium, starCircleEnabled, createdAt
users/{uid}/diary/{entryId}      # записи дневника
users/{uid}/answers/{yyyy-MM-dd} # ответы на вопрос дня
users/{uid}/testResults/{testId}
users/{uid}/circle/{friendUid}   # Звёздный круг — пишет только сервер

phoneIndex/{sha256(E.164)}       # { uid } — только сервер, клиентам закрыто
```

## Перенос данных гостя в аккаунт

Ключи локального хранилища собраны в `PrefKeys` (`lib/core/services/preferences.dart`).
При первом входе приложение:
1. входит через `signInWithCredential` (Google/Apple);
2. переносит из `SharedPreferences` дату рождения, ответы на вопросы дня,
   записи дневника и результаты тестов в `users/{uid}/…` (батчем, с `merge`);
3. помечает перенос выполненным, локальные данные оставляет как кэш.

## Локальная разработка с эмуляторами

```bash
cd functions && npm install && cd ..
firebase emulators:start
```
