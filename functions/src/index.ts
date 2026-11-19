import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();

// Европейский регион ближе к основной аудитории; поменяйте при необходимости.
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

export { setStarCircle, matchContacts } from "./star_circle.js";
export { cleanupDeletedUser } from "./account.js";
export { natalChart } from "./natal.js";
