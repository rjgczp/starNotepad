export type AppRelease = {
  ID: number;
  platform: "web" | "android" | "desktop";
  version: string;
  downloadUrl: string;
  releaseNotes: string;
  forceUpdate: boolean;
  publishedAt?: string;
};

export const APP_VERSION = __DUO_APP_VERSION__;

export function clientPlatform(nativeBuild: boolean): AppRelease["platform"] {
  const configured = import.meta.env.VITE_DUO_PLATFORM?.trim().toLowerCase();
  if (configured === "web" || configured === "android" || configured === "desktop") {
    return configured;
  }
  if (!nativeBuild) return "web";
  const runtime = window as Window & {
    __TAURI_INTERNALS__?: unknown;
  };
  return runtime.__TAURI_INTERNALS__ ? "desktop" : "android";
}

export function compareVersions(left: string, right: string): number {
  const parse = (value: string) => {
    const normalized = value.trim().replace(/^v/i, "").split("+", 1)[0];
    const [core, prerelease = ""] = normalized.split("-", 2);
    const coreParts = core.split(".");
    if (coreParts.length > 3 || coreParts.some((part) => !/^\d+$/.test(part))) {
      return null;
    }
    const parts = coreParts.map(Number);
    while (parts.length < 3) parts.push(0);
    return { parts, prerelease };
  };
  const a = parse(left);
  const b = parse(right);
  if (!a || !b) return 0;
  for (let index = 0; index < 3; index += 1) {
    if (a.parts[index] !== b.parts[index]) return a.parts[index] > b.parts[index] ? 1 : -1;
  }
  if (!a.prerelease || !b.prerelease) {
    if (a.prerelease === b.prerelease) return 0;
    return a.prerelease ? -1 : 1;
  }
  const aParts = a.prerelease.split(".");
  const bParts = b.prerelease.split(".");
  for (let index = 0; index < Math.min(aParts.length, bParts.length); index += 1) {
    if (aParts[index] === bParts[index]) continue;
    const aNumber = /^\d+$/.test(aParts[index]) ? Number(aParts[index]) : null;
    const bNumber = /^\d+$/.test(bParts[index]) ? Number(bParts[index]) : null;
    if (aNumber !== null && bNumber !== null) return aNumber > bNumber ? 1 : -1;
    if (aNumber !== null) return -1;
    if (bNumber !== null) return 1;
    return aParts[index].localeCompare(bParts[index], "en");
  }
  return aParts.length === bParts.length ? 0 : aParts.length > bParts.length ? 1 : -1;
}

export async function checkForAppUpdate(
  apiBaseUrl: string,
  platform: AppRelease["platform"],
  version = APP_VERSION,
  signal?: AbortSignal,
): Promise<AppRelease | null> {
  const query = new URLSearchParams({ platform, version });
  const response = await fetch(`${apiBaseUrl}/duoCall/update?${query}`, { signal });
  const payload = await response.json();
  if (!response.ok || payload.code !== 0 || !payload.data?.updateAvailable) return null;
  const release = payload.data.release as AppRelease | undefined;
  if (!release?.downloadUrl || compareVersions(release.version, version) <= 0) return null;
  return release;
}
