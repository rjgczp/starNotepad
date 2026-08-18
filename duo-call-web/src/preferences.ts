export type Theme = "blue" | "pink" | "dark";
export type LightTheme = Exclude<Theme, "dark">;

export type DuoPreferences = {
  version: 1;
  theme: Theme;
  defaultLightTheme: LightTheme;
  followSystem: boolean;
  soundsEnabled: boolean;
  notificationsEnabled: boolean;
};

export const PREFERENCES_KEY = "duo-preferences-v1";

const isTheme = (value: unknown): value is Theme =>
  value === "blue" || value === "pink" || value === "dark";

const isLightTheme = (value: unknown): value is LightTheme =>
  value === "blue" || value === "pink";

export function defaultPreferences(storage?: Pick<Storage, "getItem">): DuoPreferences {
  const legacyTheme = storage?.getItem("duo-theme");
  const theme: Theme = isTheme(legacyTheme) ? legacyTheme : "blue";
  return {
    version: 1,
    theme,
    defaultLightTheme: theme === "pink" ? "pink" : "blue",
    followSystem: false,
    soundsEnabled: true,
    notificationsEnabled:
      storage?.getItem("duo-notifications") === "enabled",
  };
}

export function loadPreferences(
  storage: Pick<Storage, "getItem">,
): DuoPreferences {
  const fallback = defaultPreferences(storage);
  try {
    const parsed = JSON.parse(storage.getItem(PREFERENCES_KEY) || "{}") as
      Partial<DuoPreferences>;
    if (parsed.version !== 1) return fallback;
    return {
      version: 1,
      theme: isTheme(parsed.theme) ? parsed.theme : fallback.theme,
      defaultLightTheme: isLightTheme(parsed.defaultLightTheme)
        ? parsed.defaultLightTheme
        : fallback.defaultLightTheme,
      followSystem: typeof parsed.followSystem === "boolean"
        ? parsed.followSystem
        : fallback.followSystem,
      soundsEnabled: typeof parsed.soundsEnabled === "boolean"
        ? parsed.soundsEnabled
        : fallback.soundsEnabled,
      notificationsEnabled: typeof parsed.notificationsEnabled === "boolean"
        ? parsed.notificationsEnabled
        : fallback.notificationsEnabled,
    };
  } catch {
    return fallback;
  }
}

export function resolveTheme(
  preferences: DuoPreferences,
  systemDark: boolean,
): Theme {
  if (!preferences.followSystem) return preferences.theme;
  return systemDark ? "dark" : preferences.defaultLightTheme;
}

export function newestAlbums<T>(items: T[], limit = 6): T[] {
  return items.slice(0, Math.max(0, limit));
}

export function displayNameForSlot(
  identities: { slot: number; displayName: string }[],
  slot: number,
  me: number,
): string {
  const configured = identities.find((identity) => identity.slot === slot)
    ?.displayName?.trim();
  if (configured) return configured;
  return slot === me ? "我" : "TA";
}

export function profileInitial(displayName: string): string {
  return Array.from(displayName.trim())[0]?.toUpperCase() || "♡";
}

export function resolveProfileAvatar(
  previewUrl?: string,
  savedUrl?: string,
): string {
  return previewUrl?.trim() || savedUrl?.trim() || "";
}

export function mergeProfileBySlot<T extends { slot: number }>(
  profiles: T[],
  next: T,
): T[] {
  const index = profiles.findIndex((profile) => profile.slot === next.slot);
  if (index < 0) return [...profiles, next].sort((a, b) => a.slot - b.slot);
  return profiles.map((profile) => profile.slot === next.slot ? next : profile);
}

export function profileStatusText(
  status?: { emoji?: string; label?: string } | null,
): string {
  const label = status?.label?.trim();
  if (!label) return "等你写下此刻";
  return [status?.emoji?.trim(), label].filter(Boolean).join(" ");
}

export function treeLeafIcon(eventType: string): string {
  return {
    daily_reply: "solar:letter-bold",
    album: "solar:gallery-wide-bold",
    note: "solar:pen-new-square-bold",
    chat: "solar:chat-round-dots-bold",
    call: "solar:videocamera-record-bold",
  }[eventType] || "solar:leaf-bold";
}

export function treeEventLabel(eventType: string): string {
  return {
    daily_reply: "一封回信",
    album: "一张照片",
    note: "一句心里话",
    chat: "今天的聊天",
    call: "一次见面",
  }[eventType] || "共同的小事";
}

export type FloatingPosition = { x: number; y: number };
export type FloatingBounds = {
  width: number;
  height: number;
  itemWidth: number;
  itemHeight: number;
  margin?: number;
};

export function snapFloatingPosition(
  position: FloatingPosition,
  bounds: FloatingBounds,
): FloatingPosition {
  const margin = Math.max(0, bounds.margin ?? 12);
  const maxX = Math.max(margin, bounds.width - bounds.itemWidth - margin);
  const maxY = Math.max(margin, bounds.height - bounds.itemHeight - margin);
  const x = Math.min(maxX, Math.max(margin, position.x));
  const y = Math.min(maxY, Math.max(margin, position.y));
  return {
    x: x + bounds.itemWidth / 2 < bounds.width / 2 ? margin : maxX,
    y,
  };
}

export function messageSide(senderSlot: number, me: number): "mine" | "theirs" {
  return senderSlot === me ? "mine" : "theirs";
}

export function chatDeliveryRoute(
  partnerOnline: boolean,
): "browser" | "wechat" {
  return partnerOnline ? "browser" : "wechat";
}

export function orderTreeMembers<T extends { slot: number }>(members: T[], me: number): T[] {
  return [...members].sort((left, right) => {
    if (left.slot === me) return -1;
    if (right.slot === me) return 1;
    return left.slot - right.slot;
  });
}

export function treeNodeRegion(index: number): "upper" | "middle" | "lower" {
  return ["lower", "upper", "middle", "middle", "lower"][index % 5] as "upper" | "middle" | "lower";
}

export function loopRecentItems<T>(items: T[], minimum = 3): T[] {
  if (!items.length) return [];
  return Array.from({ length: Math.max(minimum, items.length) }, (_, index) => items[index % items.length]);
}

export function callVisualMode(camera: boolean, muted: boolean): "video" | "audio" | "idle" {
  if (camera) return "video";
  return muted ? "idle" : "audio";
}
