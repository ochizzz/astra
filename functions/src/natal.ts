/**
 * Натальная карта: положения Солнца, Луны и планет в тропическом зодиаке
 * и асцендент. Расчёт — Astronomy Engine (MIT), без Swiss Ephemeris (AGPL).
 * Точность ~1′ — для астрологических задач с запасом.
 */
import * as Astronomy from "astronomy-engine";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const SIGNS = [
  "aries", "taurus", "gemini", "cancer", "leo", "virgo",
  "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces",
] as const;

const BODIES = [
  Astronomy.Body.Sun, Astronomy.Body.Moon, Astronomy.Body.Mercury, Astronomy.Body.Venus,
  Astronomy.Body.Mars, Astronomy.Body.Jupiter, Astronomy.Body.Saturn, Astronomy.Body.Uranus,
  Astronomy.Body.Neptune, Astronomy.Body.Pluto,
];

const norm = (deg: number) => ((deg % 360) + 360) % 360;
const rad = (deg: number) => (deg * Math.PI) / 180;
const deg = (r: number) => (r * 180) / Math.PI;

export interface Placement {
  longitude: number;
  sign: (typeof SIGNS)[number];
  degreeInSign: number;
}

const placement = (lon: number): Placement => ({
  longitude: lon,
  sign: SIGNS[Math.floor(norm(lon) / 30)],
  degreeInSign: norm(lon) % 30,
});

/** Геоцентрическая эклиптическая долгота на истинное равноденствие даты. */
export function geocentricLongitude(body: Astronomy.Body, time: Astronomy.AstroTime): number {
  const eqj = Astronomy.GeoVector(body, time, true);
  const ect = Astronomy.RotateVector(Astronomy.Rotation_EQJ_ECT(time), eqj);
  return norm(Astronomy.SphereFromVector(ect).lon);
}

/** Асцендент: точка эклиптики, восходящая на востоке. */
export function ascendant(time: Astronomy.AstroTime, latitude: number, longitude: number): number {
  const lst = norm(Astronomy.SiderealTime(time) * 15 + longitude); // RAMC, градусы
  const eps = rad(Astronomy.e_tilt(time).tobl);
  const ramc = rad(lst);
  const asc = Math.atan2(
    Math.cos(ramc),
    -(Math.sin(ramc) * Math.cos(eps) + Math.tan(rad(latitude)) * Math.sin(eps)),
  );
  return norm(deg(asc));
}

export function computeChart(utc: Date, latitude?: number, longitude?: number) {
  const time = Astronomy.MakeTime(utc);
  const planets = Object.fromEntries(
    BODIES.map((b) => [b.toLowerCase(), placement(geocentricLongitude(b, time))]),
  );
  const asc =
    latitude !== undefined && longitude !== undefined
      ? placement(ascendant(time, latitude, longitude))
      : null;
  return { planets, ascendant: asc };
}

/**
 * Вход: `{ utc: ISO-строка момента рождения, lat?, lon? }`. Перевод местного
 * времени в UTC делает клиент по часовому поясу места рождения.
 * Требует аккаунта; полная карта с разбором — для Премиума (проверка позже).
 */
export const natalChart = onCall({ enforceAppCheck: true }, (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Нужен вход в аккаунт");
  const { utc, lat, lon } = (req.data ?? {}) as { utc?: string; lat?: number; lon?: number };
  const date = utc ? new Date(utc) : null;
  if (!date || Number.isNaN(date.getTime())) {
    throw new HttpsError("invalid-argument", "Нужна дата рождения в формате ISO");
  }
  const hasPlace = typeof lat === "number" && typeof lon === "number";
  if (hasPlace && (Math.abs(lat) > 90 || Math.abs(lon) > 180)) {
    throw new HttpsError("invalid-argument", "Некорректные координаты");
  }
  return computeChart(date, hasPlace ? lat : undefined, hasPlace ? lon : undefined);
});
