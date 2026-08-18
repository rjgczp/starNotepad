import { Capacitor, registerPlugin } from "@capacitor/core";
import { invoke, isTauri } from "@tauri-apps/api/core";
import { IS_NATIVE_BUILD } from "./domain";

export const QIXI_PUBLIC_URL = "https://ai.xiaoyu.ski/qx";
export const QIXI_WEB_PATH = "/qx";

type ExternalBrowserPlugin = {
  open(options: { url: string }): Promise<void>;
};

const externalBrowser = registerPlugin<ExternalBrowserPlugin>("ExternalBrowser");

function openFallbackBrowser() {
  const opened = window.open(QIXI_PUBLIC_URL, "_blank", "noopener,noreferrer");
  if (!opened) window.location.assign(QIXI_PUBLIC_URL);
}

export async function openQixiInvitation() {
  if (!IS_NATIVE_BUILD) {
    window.location.assign(QIXI_WEB_PATH);
    return;
  }

  if (Capacitor.isNativePlatform() && Capacitor.getPlatform() === "android") {
    try {
      await externalBrowser.open({ url: QIXI_PUBLIC_URL });
      return;
    } catch {
      openFallbackBrowser();
      return;
    }
  }

  if (isTauri()) {
    try {
      await invoke("open_external_url", { url: QIXI_PUBLIC_URL });
      return;
    } catch {
      openFallbackBrowser();
      return;
    }
  }

  openFallbackBrowser();
}
