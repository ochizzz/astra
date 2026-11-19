#!/usr/bin/env bash
# Собирает release APK и рассылает группе тестеров через Firebase App Distribution.
# Тестеры получают уведомление и ставят обновление из приложения «App Tester».
#
#   tool/release.sh "Что нового"        # версия берётся из pubspec.yaml
#
# Нужно: firebase login (или GOOGLE_APPLICATION_CREDENTIALS), Android SDK.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_ID="1:414498966999:android:8038ce56d7a0c72466cf92"
PROJECT="astra-app-9a449"
NOTES="${1:-Обновление}"

flutter analyze
flutter test
flutter build apk --release --split-per-abi --target-platform android-arm64
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  --app "$APP_ID" --groups dev --release-notes "$NOTES" --project "$PROJECT"
