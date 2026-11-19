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

## Запуск за 15 минут (бесплатный тариф Spark)

Всё, кроме Cloud Functions, работает на Spark без привязки карты.

### 1. Проект
1. [console.firebase.google.com](https://console.firebase.google.com) → **Add project** → имя `astra`.
2. Google Analytics — **включить** (аккаунт Analytics по умолчанию).

### 2. Android-приложение
1. Project Overview → значок Android.
2. Package name: **`app.astra.mobile`**, nickname: `Астра Android`.
3. **SHA-1 отладочного ключа** (на компьютере, где собираете приложение):
   ```bash
   keytool -list -v -alias androiddebugkey -storepass android \
     -keystore ~/.android/debug.keystore
   ```
   Скопируйте строки `SHA1` и `SHA256` и добавьте обе
   (Project settings → Your apps → Add fingerprint).
   Release-отпечатки добавим перед публикацией (Play Console → Целостность приложения).
4. Скачивать `google-services.json` пока **не нужно** — сначала шаг 3.

### 3. Сервисы (левое меню → Build / Run)
| Раздел | Действие |
|---|---|
| **Authentication** | Get started → Sign-in method → **Google** → Enable, укажите e-mail поддержки |
| **Firestore Database** | Create database → регион **eur3 (europe-west)** → Production mode |
| **Crashlytics** | Enable |
| **App Check** | Apps → Android → **Play Integrity** → Register (принудительную проверку пока не включаем) |
| **Messaging** | ничего делать не нужно |

### 4. Конфиг в репозиторий
Project settings → Your apps → Android → **скачать `google-services.json`**
(именно после включения входа Google — тогда в файле будет OAuth-клиент).
Положите в `android/app/` и выполните:
```bash
dart run tool/gen_firebase_options.dart   # создаст lib/firebase_options.dart
```
или просто пришлите содержимое файла в чат — это не секрет, я сделаю сам.
Gradle-плагины Firebase и Crashlytics включатся автоматически, как только файл появится.

### 5. Правила и контент дня
```bash
npm install -g firebase-tools && firebase login
firebase use --add                     # выбрать проект
firebase deploy --only firestore:rules

dart run tool/build_daily.dart --days 120          # контент на 4 месяца
gcloud auth application-default login
(cd functions && npm install) && npm --prefix functions run seed -- --project astra-app-9a449
```
Если в Firestore нет документа на нужный день, приложение молча берёт встроенный контент.

### 6. Отладка App Check
При первом запуске debug-сборки в logcat появится строка
`Enter this debug secret into the allow list…` — добавьте этот токен в
App Check → Apps → ⋮ → Manage debug tokens.

## Что уже подключено в коде

| Функция | Где |
|---|---|
| Вход через Google (Credential Manager) + выход | `lib/core/auth/auth_service.dart` |
| Перенос данных гостя в аккаунт и обратно при входе на новом устройстве | `lib/core/auth/cloud_sync.dart` |
| Синхронизация даты рождения и ответов на вопрос дня | там же |
| Удаление аккаунта со всеми данными прямо из приложения (без Cloud Functions) | `AuthService.deleteAccount` |
| Контент дня из `daily/{день}` с офлайн-кэшем и запасным встроенным контентом | `FirestoreTodayRepository` |
| Пуши: тема `daily` для всех + ID устройства в аккаунт; разрешение — только по переключателю в профиле | `lib/core/firebase/push_service.dart` |
| Crashlytics, Analytics (`login`, `onboarding_completed`, `daily_card_flipped`, …), App Check | `lib/core/firebase/` |

## Позже — тариф Blaze (2.0)

Cloud Functions (`functions/`) нужны для «Звёздного круга», натальной карты на
сервере и вход по SMS. Для них потребуется тариф Blaze (карта), затем
`firebase deploy --only functions`.

| Этап | Что понадобится |
|---|---|
| MVP, реклама | AdMob: **App ID** и ID рекламных блоков |
| 1.1, Премиум | RevenueCat: **публичные SDK-ключи**; продукты подписки в Play Console |
| 1.1, пуши iOS | APNs-ключ (.p8) в Cloud Messaging |
| 2.0, телефон | Phone в Authentication, тестовые номера, тариф Blaze |
| 2.0, iOS | Apple Developer Program, **Sign in with Apple**, `GoogleService-Info.plist` |
| Публикация | Google Play Console; URL политики конфиденциальности; веб-страница удаления аккаунта |

**Не присылайте в чат и не коммитьте:** ключ подписи (`.jks`) и пароли,
JSON сервисных аккаунтов, секретные ключи RevenueCat, `.p8`-ключи Apple.

## Модель данных Firestore

```
daily/{yyyy-MM-dd}               # карта, цитата, вопрос, гороскопы 12 знаков — только чтение
content/{type}/items/{id}        # тесты, профили знаков — только чтение

users/{uid}                      # профиль: birthDate, sign, pushIds[], birthTime?, birthPlace?,
                                 # publicName?; только сервер: premium, starCircleEnabled, createdAt
users/{uid}/diary/{entryId}      # записи дневника
users/{uid}/answers/{yyyy-MM-dd} # ответы на вопрос дня
users/{uid}/testResults/{testId}
users/{uid}/circle/{friendUid}   # Звёздный круг — пишет только сервер

phoneIndex/{sha256(E.164)}       # { uid } — только сервер, клиентам закрыто
```

## Перенос данных гостя в аккаунт

Ключи локального хранилища собраны в `PrefKeys` (`lib/core/services/preferences.dart`).
При входе (`CloudSync.onSignedIn`):
1. **дата рождения** — если в аккаунте уже есть, она главнее и подтягивается
   на устройство (вход на новом телефоне); иначе локальная уходит в аккаунт;
2. **ответы на вопрос дня** — локальные выгружаются в `users/{uid}/answers`,
   облачные, которых нет на устройстве, скачиваются;
3. локальные данные остаются как кэш — приложение работает и офлайн.
Дневник и результаты тестов подключатся к той же схеме, когда появятся (MVP).

## Локальная разработка с эмуляторами

```bash
cd functions && npm install && cd ..
firebase emulators:start
```
