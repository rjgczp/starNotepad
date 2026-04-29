import type { Metadata } from "next";
import MinecraftWorldViewer, { type MinecraftPreview } from "@/app/components/minecraft-world-viewer";

export const metadata: Metadata = {
  title: "Minecraft World Viewer",
  description: "Interactive 3D preview page for uploaded Minecraft worlds.",
};

type MinecraftPreviewPayload = {
  code?: number;
  data?: {
    preview?: MinecraftPreview;
  };
  message?: string;
};

async function getMinecraftPreview(): Promise<{ preview: MinecraftPreview | null; loadError: string }> {
  const worldPath =
    process.env.MINECRAFT_WORLD_PATH ||
    "/Users/charles/Documents/notepad/gin-vue-admin/server/uploads/file/5dc8ac4829e99f6b5d333881a92c7f24_20260429141901/新的世界/";
  const apiBase = process.env.MINECRAFT_PREVIEW_API_BASE || "http://127.0.0.1:8888";
  const endpoint = `${apiBase}/api/ufile/minecraft/preview?worldPath=${encodeURIComponent(worldPath)}`;

  try {
    const res = await fetch(endpoint, { cache: "no-store" });
    if (!res.ok) {
      return { preview: null, loadError: `预览接口请求失败: HTTP ${res.status}` };
    }

    const payload = (await res.json()) as MinecraftPreviewPayload;
    if (payload?.data?.preview) {
      return { preview: payload.data.preview, loadError: "" };
    }
    return { preview: null, loadError: payload?.message || "预览数据为空" };
  } catch {
    return { preview: null, loadError: "无法连接后端预览接口" };
  }
}

export default async function MinecraftPage() {
  const { preview, loadError } = await getMinecraftPreview();
  return <MinecraftWorldViewer preview={preview} loadError={loadError} />;
}
