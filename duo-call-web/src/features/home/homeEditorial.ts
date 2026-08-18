import type {
  AlbumItem,
  GrowthEvent,
  Identity,
  WeeklyMemory,
} from "../../domain";

const DISPLAYABLE_EVENT_TYPES = new Set<GrowthEvent["eventType"]>([
  "daily_reply",
  "album",
  "note",
  "chat",
  "call",
]);

export function editorialWeekLabel(value = new Date()): string {
  const date = new Date(Date.UTC(
    value.getFullYear(),
    value.getMonth(),
    value.getDate(),
  ));
  const weekday = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - weekday);
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((date.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
  return `${date.getUTCFullYear()} · WEEK ${String(week).padStart(2, "0")}`;
}

export function weeklyMemoryLabel(weekKey: string): string {
  const match = /^(\d{4})-W(\d{2})$/.exec(weekKey);
  return match ? `${match[1]} · 第 ${Number(match[2])} 周` : weekKey;
}

export function selectEditorialCover(albums: AlbumItem[]): AlbumItem | null {
  return [...albums].sort((left, right) => {
    const byDate = new Date(right.uploadedAt).getTime() - new Date(left.uploadedAt).getTime();
    return byDate || right.ID - left.ID;
  })[0] || null;
}

export function selectLatestWeeklyMemory(
  memories: WeeklyMemory[],
): WeeklyMemory | null {
  return [...memories].sort((left, right) =>
    right.weekKey.localeCompare(left.weekKey) || right.ID - left.ID)[0] || null;
}

export function selectEditorialMoments(
  events: GrowthEvent[],
  limit = 8,
): GrowthEvent[] {
  return events
    .filter((event) => DISPLAYABLE_EVENT_TYPES.has(event.eventType))
    .sort((left, right) => {
      const byDate = new Date(right.occurredAt).getTime() - new Date(left.occurredAt).getTime();
      return byDate || right.ID - left.ID;
    })
    .slice(0, Math.max(0, limit));
}

export function selectRewindMoment(
  events: GrowthEvent[],
  now = new Date(),
): GrowthEvent | null {
  const ordered = selectEditorialMoments(events, events.length);
  const sameDay = ordered.find((event) => {
    const date = new Date(event.occurredAt);
    return date.getFullYear() < now.getFullYear()
      && date.getMonth() === now.getMonth()
      && date.getDate() === now.getDate();
  });
  return sameDay || ordered.at(-1) || null;
}

export function editorialMember(
  identities: Identity[],
  slot: number,
): Identity | null {
  return identities.find((identity) => identity.slot === slot) || null;
}

export function editorialFallbackCopy(eventCount: number): string {
  return eventCount > 0
    ? "最近的照片、回信和见面，都被收进了这一期。"
    : "这一期还留着空白，等你们从今天写下第一行。";
}
