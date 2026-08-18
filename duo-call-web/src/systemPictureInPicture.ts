import {
  Capacitor,
  registerPlugin,
  type PluginListenerHandle,
} from "@capacitor/core";
import { isTauri } from "@tauri-apps/api/core";
import {
  preparePictureInPictureVideo,
  VIDEO_NOT_READY_MESSAGE,
} from "./pictureInPictureVideo";

type NativePictureInPictureState = {
  active: boolean;
};

type NativePictureInPicturePlugin = {
  startCall(options: { width: number; height: number }): Promise<void>;
  stopCall(): Promise<void>;
  requestNotificationPermission(): Promise<void>;
  notifyMessage(options: { id: number; title: string; body: string }): Promise<void>;
  enter(options: { width: number; height: number }): Promise<NativePictureInPictureState>;
  isActive(): Promise<NativePictureInPictureState>;
  addListener(
    eventName: "modeChanged",
    listener: (state: NativePictureInPictureState) => void,
  ): Promise<PluginListenerHandle>;
};

type PictureInPictureVideo = HTMLVideoElement & {
  requestPictureInPicture?: () => Promise<unknown>;
};

type PictureInPictureDocument = Document & {
  pictureInPictureEnabled?: boolean;
  pictureInPictureElement?: Element | null;
  exitPictureInPicture?: () => Promise<void>;
};

type TauriWindowSnapshot = {
  maximized: boolean;
  position: { x: number; y: number };
  size: { width: number; height: number };
};
type TauriFloatingExit = () => Promise<void>;

export type SystemPictureInPictureMode =
  | "android"
  | "video"
  | "tauri-window";

const nativePictureInPicture =
  registerPlugin<NativePictureInPicturePlugin>("SystemPictureInPicture");
export const ANDROID_PICTURE_IN_PICTURE_CLASS = "android-system-pip";
let tauriFloatingEntry: Promise<TauriFloatingExit> | null = null;
let tauriFloatingExit: TauriFloatingExit | null = null;

function isAndroidNative() {
  return Capacitor.isNativePlatform() && Capacitor.getPlatform() === "android";
}
export const isAndroidNativePlatform = isAndroidNative;

export function setAndroidPictureInPicturePresentation(active: boolean) {
  if (typeof document === "undefined") return;
  document.documentElement.classList.toggle(
    ANDROID_PICTURE_IN_PICTURE_CLASS,
    active,
  );
}

export async function setAndroidCallForeground(
  active: boolean,
  dimensions = { width: 16, height: 9 },
) {
  if (!isAndroidNative()) return;
  if (active) {
    await nativePictureInPicture.startCall(dimensions);
  } else {
    await nativePictureInPicture.stopCall();
  }
}

export async function requestAndroidNotificationPermission() {
  if (!isAndroidNative()) return false;
  try { await nativePictureInPicture.requestNotificationPermission(); return true; } catch { return false; }
}

export async function showAndroidMessageNotification(id: number, title: string, body: string) {
  if (!isAndroidNative()) return false;
  try { await nativePictureInPicture.notifyMessage({ id, title, body }); return true; } catch { return false; }
}

async function enterTauriFloatingWindow() {
  if (tauriFloatingExit) return tauriFloatingExit;
  if (tauriFloatingEntry) return tauriFloatingEntry;

  tauriFloatingEntry = (async () => {
    const {
      getCurrentWindow,
      LogicalSize,
      PhysicalPosition,
      PhysicalSize,
    } = await import("@tauri-apps/api/window");
    const appWindow = getCurrentWindow();
    const maximized = await appWindow.isMaximized();
    if (maximized) await appWindow.unmaximize();
    const [position, size] = await Promise.all([
      appWindow.outerPosition(),
      appWindow.innerSize(),
    ]).catch(async (error) => {
      if (maximized) await appWindow.maximize().catch(() => undefined);
      throw error;
    });
    const snapshot: TauriWindowSnapshot = {
      maximized,
      position: { x: position.x, y: position.y },
      size: { width: size.width, height: size.height },
    };
    const restore = async () => {
      const errors: unknown[] = [];
      const attempt = async (action: () => Promise<void>) => {
        try {
          await action();
        } catch (error) {
          errors.push(error);
        }
      };
      await attempt(() => appWindow.setAlwaysOnTop(false));
      await attempt(() => appWindow.setMinSize(null));
      await attempt(() => appWindow.setSize(
        new PhysicalSize(snapshot.size.width, snapshot.size.height),
      ));
      await attempt(() => appWindow.setPosition(
        new PhysicalPosition(snapshot.position.x, snapshot.position.y),
      ));
      await attempt(() => appWindow.setMinSize(new LogicalSize(390, 600)));
      if (snapshot.maximized) {
        await attempt(() => appWindow.maximize());
      }
      if (errors.length) throw errors[0];
    };

    try {
      await appWindow.setMinSize(null);
      await appWindow.setAlwaysOnTop(true);
      await appWindow.setSize(new LogicalSize(420, 280));
    } catch (error) {
      await restore().catch(() => undefined);
      throw error;
    }

    let exitPromise: Promise<void> | null = null;
    const exit = () => {
      if (exitPromise) return exitPromise;
      exitPromise = restore().then(() => {
        if (tauriFloatingExit === exit) tauriFloatingExit = null;
      }).catch((error) => {
        exitPromise = null;
        throw error;
      });
      return exitPromise;
    };
    tauriFloatingExit = exit;
    return exit;
  })();

  try {
    return await tauriFloatingEntry;
  } finally {
    tauriFloatingEntry = null;
  }
}

export async function enterSystemPictureInPicture(
  video: HTMLVideoElement,
): Promise<{
  mode: SystemPictureInPictureMode;
  exit?: () => Promise<void>;
}> {
  if (isAndroidNative()) {
    setAndroidPictureInPicturePresentation(true);
    try {
      await nativePictureInPicture.enter({
        width: video.videoWidth || 16,
        height: video.videoHeight || 9,
      });
      return { mode: "android" };
    } catch (error) {
      setAndroidPictureInPicturePresentation(false);
      throw error;
    }
  }

  if (isTauri()) {
    return {
      mode: "tauri-window",
      exit: await enterTauriFloatingWindow(),
    };
  }

  const pipDocument = document as PictureInPictureDocument;
  const pipVideo = video as PictureInPictureVideo;
  if (
    pipVideo.requestPictureInPicture &&
    pipDocument.pictureInPictureEnabled !== false
  ) {
    if (pipDocument.pictureInPictureElement === video) {
      await pipDocument.exitPictureInPicture?.();
    } else {
      await preparePictureInPictureVideo(video);
      try {
        await pipVideo.requestPictureInPicture();
      } catch (error) {
        if (error instanceof DOMException) {
          if (
            error.name === "InvalidStateError" ||
            error.name === "AbortError"
          ) {
            throw new Error(VIDEO_NOT_READY_MESSAGE);
          }
          if (error.name === "NotAllowedError") {
            throw new Error("请直接点击悬浮窗按钮后重试。");
          }
          if (
            error.name === "NotSupportedError" ||
            error.name === "SecurityError"
          ) {
            throw new Error("当前浏览器不允许视频悬浮窗。");
          }
          throw new Error("系统视频悬浮窗开启失败，请稍后再试。");
        }
        throw error;
      }
    }
    return { mode: "video" };
  }

  throw new Error("当前系统或浏览器不支持视频悬浮窗");
}

export async function listenForNativePictureInPicture(
  listener: (active: boolean) => void,
) {
  if (!isAndroidNative()) return null;
  const report = (active: boolean) => {
    setAndroidPictureInPicturePresentation(active);
    listener(active);
  };
  const handle = await nativePictureInPicture.addListener(
    "modeChanged",
    ({ active }) => report(active),
  );
  const initial = await nativePictureInPicture.isActive();
  report(initial.active);
  return {
    remove: async () => {
      setAndroidPictureInPicturePresentation(false);
      await handle.remove();
    },
  };
}
