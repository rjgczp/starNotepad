import type { Message } from "../domain";

export async function readAPIPayload(response: Response, fallback: string) {
  try {
    const payload = await response.json();
    if (!response.ok || payload.code !== 0) {
      throw new Error(payload.msg || `${fallback}（HTTP ${response.status}）`);
    }
    return payload;
  } catch (error) {
    if (
      error instanceof Error &&
      error.message !== "Unexpected end of JSON input" &&
      !error.message.includes("JSON")
    ) {
      throw error;
    }
    throw new Error(
      response.status === 404
        ? `${fallback}：服务器接口或媒体路由尚未同步`
        : `${fallback}（HTTP ${response.status}）`,
    );
  }
}

export function slotFromSession(token: string): number {
  try {
    const encoded = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    return Number(JSON.parse(atob(encoded)).slot) || 0;
  } catch {
    return 0;
  }
}

export function shouldShowMessageTime(
  previous: Message | undefined,
  message: Message,
) {
  if (!previous) return true;
  const current = new Date(
    message.CreatedAt || message.updatedAt || 0,
  ).getTime();
  const before = new Date(
    previous.CreatedAt || previous.updatedAt || 0,
  ).getTime();
  return !Number.isFinite(current) || !Number.isFinite(before) ||
    Math.abs(current - before) >= 5 * 60 * 1000 ||
    new Date(current).toDateString() !== new Date(before).toDateString();
}

export function messageTimeLabel(message: Message) {
  const value = new Date(message.CreatedAt || message.updatedAt || 0);
  if (Number.isNaN(value.getTime())) return "";
  return value.toLocaleString("zh-CN", {
    month: "numeric",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
