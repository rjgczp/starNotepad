const QIXI_TIME_ZONE = "Asia/Shanghai";
const QIXI_ACTIVE_DATES = new Set([
  "2026-08-18",
  "2026-08-19",
  "2026-08-20",
]);
const QIXI_DISMISS_PREFIX = "duo-qixi-invitation-dismissed:";

type StorageReader = Pick<Storage, "getItem">;
type StorageWriter = Pick<Storage, "setItem">;

export function qixiShanghaiDateKey(date = new Date()): string {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: QIXI_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);
  const read = (type: "year" | "month" | "day") =>
    parts.find((part) => part.type === type)?.value || "";
  return `${read("year")}-${read("month")}-${read("day")}`;
}

export function qixiInvitationIsActive(date = new Date()): boolean {
  return QIXI_ACTIVE_DATES.has(qixiShanghaiDateKey(date));
}

export function qixiInvitationDismissKey(date = new Date()): string {
  return `${QIXI_DISMISS_PREFIX}${qixiShanghaiDateKey(date)}`;
}

export function shouldShowQixiInvitation(
  storage: StorageReader,
  date = new Date(),
): boolean {
  return qixiInvitationIsActive(date) &&
    storage.getItem(qixiInvitationDismissKey(date)) !== "true";
}

export function dismissQixiInvitationForToday(
  storage: StorageWriter,
  date = new Date(),
) {
  storage.setItem(qixiInvitationDismissKey(date), "true");
}
