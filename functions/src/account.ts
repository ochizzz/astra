/**
 * Удаление аккаунта. Клиент вызывает `FirebaseAuth.currentUser.delete()`
 * (из профиля или со страницы удаления по ссылке), а этот триггер стирает
 * все данные пользователя: профиль, дневник, ответы, результаты тестов,
 * запись в индексе телефонов «Звёздного круга».
 */
import { getFirestore } from "firebase-admin/firestore";
import * as functionsV1 from "firebase-functions/v1";
import { phoneHash } from "./star_circle.js";

export const cleanupDeletedUser = functionsV1
  .region("europe-west1")
  .auth.user()
  .onDelete(async (user) => {
    const db = getFirestore();
    await db.recursiveDelete(db.doc(`users/${user.uid}`));
    if (user.phoneNumber) {
      const ref = db.doc(`phoneIndex/${phoneHash(user.phoneNumber)}`);
      const snap = await ref.get();
      if (snap.exists && snap.get("uid") === user.uid) await ref.delete();
    }
  });
