// Загружает контент дня в Firestore: daily/{yyyy-MM-dd}.
// Работает на бесплатном тарифе Spark (пишет напрямую через Admin SDK).
//
//   dart run tool/build_daily.dart --days 120          # из корня репозитория
//   gcloud auth application-default login              # один раз
//   npm --prefix functions run seed -- --project <PROJECT_ID> [--file ../build/daily.json]
import { readFileSync } from "node:fs";
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const arg = (name, fallback) => {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 ? process.argv[i + 1] : fallback;
};

const projectId = arg("project");
if (!projectId) {
  console.error("Укажите --project <PROJECT_ID>");
  process.exit(1);
}
const file = arg("file", "../build/daily.json");
const docs = JSON.parse(readFileSync(new URL(file, `file://${process.cwd()}/`)));

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();
const writer = db.bulkWriter();
for (const doc of docs) writer.set(db.doc(`daily/${doc.day}`), doc);
await writer.close();
console.log(`✦ Загружено ${docs.length} дней в проект ${projectId}`);
