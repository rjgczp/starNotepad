export type ClientRuntimeOptions = {
  configuredApiUrl?: string;
  currentOrigin: string;
  nativeBuild?: boolean;
};

const ABSOLUTE_HTTP_URL = /^https?:\/\//i;
const EXTERNAL_MEDIA_URL = /^(?:https?:|blob:|data:)/i;

export function normalizeApiBase(
  configuredApiUrl: string | undefined,
): string {
  const configured = configuredApiUrl?.trim() || "/api";
  if (ABSOLUTE_HTTP_URL.test(configured)) {
    const url = new URL(configured);
    url.pathname = url.pathname.replace(/\/+$/, "") || "/";
    return url.toString().replace(/\/$/, "");
  }
  const path = configured.startsWith("/") ? configured : `/${configured}`;
  return path.replace(/\/+$/, "") || "/";
}

export function nativeApiConfigurationError({
  configuredApiUrl,
  nativeBuild = false,
}: ClientRuntimeOptions): string {
  if (!nativeBuild) return "";
  const configured = configuredApiUrl?.trim() || "";
  if (!ABSOLUTE_HTTP_URL.test(configured)) {
    return "原生应用需要配置绝对 HTTPS 接口地址，例如 https://ai.xiaoyu.ski/api。";
  }
  if (!configured.toLowerCase().startsWith("https://")) {
    return "原生应用的接口地址必须使用 HTTPS。";
  }
  return "";
}

export function webSocketUrl(
  apiBase: string,
  currentOrigin: string,
  token: string,
): string {
  const url = new URL(
    `${apiBase.replace(/\/+$/, "")}/duoCall/ws`,
    currentOrigin,
  );
  url.protocol = url.protocol === "https:" ? "wss:" : "ws:";
  url.searchParams.set("token", token);
  return url.toString();
}

export function resolveHostedMediaUrl(
  value: string | undefined,
  apiBase: string,
  currentOrigin: string,
): string {
  const mediaUrl = value?.trim() || "";
  if (!mediaUrl || EXTERNAL_MEDIA_URL.test(mediaUrl)) return mediaUrl;

  const apiUrl = new URL(apiBase, currentOrigin);
  if (mediaUrl.startsWith("/")) {
    return new URL(mediaUrl, apiUrl.origin).toString();
  }
  return new URL(mediaUrl, `${apiUrl.toString().replace(/\/+$/, "")}/`)
    .toString();
}
