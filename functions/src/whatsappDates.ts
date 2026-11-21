/** Dates in the WhatsApp bot consistently use IST, matching its daily summary. */
export function istDateKey(date = new Date()): string {
  return new Date(date.getTime() + 330 * 60000).toISOString().slice(0, 10);
}

export function yesterdayIST(now = new Date()): string {
  return istDateKey(new Date(now.getTime() - 86400000));
}

export function parseMealDate(input: string, now = new Date()): string | undefined {
  const text = input.trim().toLowerCase();
  if (text === "today") return istDateKey(now);
  if (text === "yesterday") return yesterdayIST(now);
  let year: number, month: number, day: number;
  const iso = text.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  const named = text.match(/^(\d{1,2})\s+([a-z]+)\s+(\d{4})$/);
  if (iso) {
    [, year, month, day] = iso.map(Number);
  } else if (named) {
    const months = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"];
    month = months.findIndex(m => named[2] === m || named[2] === m.slice(0, 3)) + 1;
    day = Number(named[1]); year = Number(named[3]);
  } else return undefined;
  if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) return undefined;
  const key = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
  const parsed = new Date(`${key}T12:00:00+05:30`);
  if (!Number.isFinite(parsed.getTime()) || istDateKey(parsed) !== key || key > istDateKey(now)) return undefined;
  return key;
}

export function mealDateLabel(key: string): string {
  return new Date(`${key}T12:00:00+05:30`).toLocaleDateString("en-GB", {
    timeZone: "Asia/Kolkata", day: "numeric", month: "long", year: "numeric",
  });
}

export function timestampDate(timestamp: { toDate(): Date } | Date): Date {
  return timestamp instanceof Date ? timestamp : timestamp.toDate();
}

/** Move a meal's IST calendar date while keeping its original local time. */
export function moveMealDate(key: string, original: Date): Date {
  const time = new Date(original.getTime() + 330 * 60000).toISOString().slice(11, 23);
  return new Date(`${key}T${time}+05:30`);
}

export interface LogDateSelection { date: string; requestId: string; token: string }
