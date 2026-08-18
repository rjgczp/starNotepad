import {
  nativeApiConfigurationError,
  normalizeApiBase,
  resolveHostedMediaUrl,
} from "./runtime";

export type Message = {
  ID: number;
  senderSlot: number;
  kind: "text" | "image";
  content: string;
  imageUrl: string;
  readAt?: string;
  CreatedAt?: string;
  updatedAt?: string;
};

export type AlbumItem = {
  ID: number;
  uploaderSlot: number;
  imageUrl: string;
  uploadedAt: string;
};

export type Anniversary = {
  ID: number;
  title: string;
  date: string;
  enabled: boolean;
  sort: number;
};

export type LoveNote = {
  ID: number;
  senderSlot: number;
  content: string;
  CreatedAt: string;
};

export type MissYouSignal = {
  ID: number;
  senderSlot: number;
  recipientSlot: number;
  message: string;
  CreatedAt: string;
  acknowledgedAt?: string;
};

export type DailyReply = {
  slot: number;
  submitted: boolean;
  content?: string;
  updatedAt?: string;
};

export type DailyState = {
  ID: number;
  questionDate: string;
  question: string;
  category: string;
  source: "ai" | "fallback";
  revealedAt?: string;
  replies: DailyReply[];
};

export type DuoStatus = {
  ID: number;
  label: string;
  emoji: string;
};

export type Identity = {
  slot: number;
  displayName: string;
  avatarUrl: string;
  statusId?: number;
  status?: DuoStatus | null;
};

export type GrowthEvent = {
  ID: number;
  eventType: "daily_reply" | "album" | "note" | "chat" | "call";
  sourceId: number;
  slot: number;
  growth: number;
  title: string;
  summary: string;
  imageUrl: string;
  occurredAt: string;
};

export type WeeklyMemory = {
  ID: number;
  weekKey: string;
  title: string;
  summary: string;
  source: "ai" | "fallback";
  generatedAt: string;
};

export type TreeState = {
  totalGrowth: number;
  togetherDays: number;
  stage: {
    id: "seed" | "sprout" | "sapling" | "bloom" | "canopy";
    name: string;
    message: string;
    minimum: number;
    next: number;
    progress: number;
  };
  events: GrowthEvent[];
  weeklyMemories: WeeklyMemory[];
};

export type CottageView = "home" | "daily" | "call" | "album" | "settings";

export const IS_NATIVE_BUILD = import.meta.env.VITE_DUO_NATIVE === "true";
export const API_BASE_URL = normalizeApiBase(
  import.meta.env.VITE_DUO_API_URL,
);
export const API_CONFIGURATION_ERROR = nativeApiConfigurationError({
  configuredApiUrl: import.meta.env.VITE_DUO_API_URL,
  currentOrigin: location.origin,
  nativeBuild: IS_NATIVE_BUILD,
});
export const mediaUrl = (value?: string) =>
  resolveHostedMediaUrl(value, API_BASE_URL, location.origin);

export const EMOJIS = [
  "😀", "😃", "😄", "😁", "😂", "🥰", "😍", "😘", "😊", "🥹",
  "😎", "🤔", "😴", "😭", "😤", "😡", "🤗", "🤭", "🫣", "🙄",
  "👍", "👎", "👏", "🙌", "🤝", "🙏", "💪", "✌️", "🤟", "🫶",
  "❤️", "🩷", "🧡", "💛", "💚", "🩵", "💙", "💜", "🤍", "💔",
  "🌹", "🌸", "🌈", "⭐", "✨", "🔥", "🎉", "🎁", "🍰", "☕",
] as const;
