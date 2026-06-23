// Date-key helpers. A date key is the local day formatted as "YYYY-MM-DD".
//
// All arithmetic is done in UTC against the key's calendar fields so that
// adding/subtracting days never drifts across a daylight-saving boundary. The
// client decides the local day and passes it up, so we only do calendar math.

/** Parses "YYYY-MM-DD" into a UTC Date at midnight. */
export function parseKey(key: string): Date {
  const [year, month, day] = key.split("-").map((p) => Number(p));
  return new Date(Date.UTC(year, month - 1, day));
}

/** Formats a UTC Date back into a "YYYY-MM-DD" key. */
export function formatKey(date: Date): string {
  const year = date.getUTCFullYear().toString().padStart(4, "0");
  const month = (date.getUTCMonth() + 1).toString().padStart(2, "0");
  const day = date.getUTCDate().toString().padStart(2, "0");
  return `${year}-${month}-${day}`;
}

/** Returns the key `delta` days away from `key` (delta may be negative). */
export function addDays(key: string, delta: number): string {
  const date = parseKey(key);
  date.setUTCDate(date.getUTCDate() + delta);
  return formatKey(date);
}

/** Returns `count` consecutive keys ending at (and including) `endKey`,
 * ordered oldest-first. */
export function lastNDateKeys(endKey: string, count: number): string[] {
  const keys: string[] = [];
  for (let i = count - 1; i >= 0; i--) {
    keys.push(addDays(endKey, -i));
  }
  return keys;
}

/** Validates a "YYYY-MM-DD" string. */
export function isValidKey(key: unknown): key is string {
  return typeof key === "string" && /^\d{4}-\d{2}-\d{2}$/.test(key);
}

/** Today's key in UTC — a server-side fallback when the client omits one. */
export function todayKeyUtc(): string {
  return formatKey(new Date());
}
