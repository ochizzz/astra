/**
 * «Звёздный круг»: поиск друзей из контактов без передачи номеров на сервер.
 *
 * Схема:
 *  1. Пользователь входит по телефону и сам включает «Звёздный круг» →
 *     `setStarCircle({enabled: true})`. Сервер берёт номер из ПРОВЕРЕННОГО
 *     токена (не от клиента), считает SHA-256 и пишет `phoneIndex/{hash}`.
 *  2. Клиент нормализует номера контактов в E.164, хэширует их на устройстве
 *     и вызывает `matchContacts({hashes})`.
 *  3. Сервер сверяет хэши с `phoneIndex` в памяти и возвращает совпадения.
 *     Присланные хэши НЕ сохраняются и не логируются.
 */
import { createHash } from "node:crypto";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const MAX_HASHES = 2000;
const HASH_RE = /^[0-9a-f]{64}$/;

export function phoneHash(e164: string): string {
  return createHash("sha256").update(e164).digest("hex");
}

export const setStarCircle = onCall({ enforceAppCheck: true }, async (req) => {
  const uid = req.auth?.uid;
  const phone = req.auth?.token.phone_number;
  if (!uid) throw new HttpsError("unauthenticated", "Нужен вход в аккаунт");
  if (!phone) throw new HttpsError("failed-precondition", "Нужен вход по номеру телефона");

  const enabled = req.data?.enabled === true;
  const db = getFirestore();
  const hash = phoneHash(phone);
  const batch = db.batch();
  batch.set(
    db.doc(`users/${uid}`),
    { starCircleEnabled: enabled, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  if (enabled) {
    batch.set(db.doc(`phoneIndex/${hash}`), { uid, createdAt: FieldValue.serverTimestamp() });
  } else {
    batch.delete(db.doc(`phoneIndex/${hash}`));
  }
  await batch.commit();
  return { enabled };
});

interface Match {
  uid: string;
  name: string | null;
  sign: string | null;
}

export const matchContacts = onCall({ enforceAppCheck: true }, async (req): Promise<Match[]> => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Нужен вход в аккаунт");

  const raw: unknown = req.data?.hashes;
  if (!Array.isArray(raw) || raw.length > MAX_HASHES) {
    throw new HttpsError("invalid-argument", `Ожидается до ${MAX_HASHES} хэшей`);
  }
  const hashes = [...new Set(raw.filter((h): h is string => typeof h === "string" && HASH_RE.test(h)))];
  if (hashes.length === 0) return [];

  const db = getFirestore();
  const me = await db.doc(`users/${uid}`).get();
  if (me.get("starCircleEnabled") !== true) {
    throw new HttpsError("failed-precondition", "Сначала включите «Звёздный круг»");
  }

  const indexDocs = await db.getAll(...hashes.map((h) => db.doc(`phoneIndex/${h}`)));
  const uids = indexDocs
    .filter((d) => d.exists)
    .map((d) => d.get("uid") as string)
    .filter((u) => u !== uid);
  if (uids.length === 0) return [];

  const users = await db.getAll(...uids.map((u) => db.doc(`users/${u}`)));
  return users
    .filter((u) => u.exists && u.get("starCircleEnabled") === true)
    .map((u) => ({
      uid: u.id,
      // Только то, что человек сам разрешил показывать в круге.
      name: (u.get("publicName") as string | undefined) ?? null,
      sign: (u.get("sign") as string | undefined) ?? null,
    }));
});
