import {
  Capacitor,
  registerPlugin,
  type PluginListenerHandle,
} from "@capacitor/core";
import { isTauri } from "@tauri-apps/api/core";

type NativePictureInPictureState = {
  active: boolean;
};

type NativePictureInPicturePlugin = {
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

export type SystemPictureInPictureMode =
  | "android"
  | "video"
  | "tauri-window";

const nativePictureInPicture =
  registerPlugin<NativePictureInPicturePlugin>("SystemPictureInPicture");
let tauriSnapshot: TauriWindowSnapshot | null = null;

function isAndroidNative() {
  return Capacitor.isNativePlatform() && Capacitor.getPlatform() === "android";
}

async function enterTauriFloatingWindow() {
  const {
    getCurrentWindow,
    LogicalSize,
    PhysicalPosition,
    PhysicalSize,
  } = await import("@tauri-apps/api/window");
  const appWindow = getCurrentWindow();
  const [position, size, maximized] = await Promise.all([
    appWindow.outerPosition(),
    appWindow.outerSize(),
    appWindow.isMaximized(),
  ]);
  tauriSnapshot = {
    maximized,
    position: { x: position.x, y: position.y },
    size: { width: size.width, height: size.height },
  };
  if (maximized) await appWindow.unmaximize();
  await appWindow.setAlwaysOnTop(true);
  await appWindow.setSize(new LogicalSize(420, 280));

  return async () => {
    const snapshot = tauriSnapshot;
    tauriSnapshot = null;
    await appWindow.setAlwaysOnTop(false);
    if (!snapshot) return;
    await appWindow.setSize(
      new PhysicalSize(snapshot.size.width, snapshot.size.height),
    );
    await appWindow.setPosition(
      new PhysicalPosition(snapshot.position.x, snapshot.position.y),
    );
    if (snapshot.maximized) await appWindow.maximize();
  };
}

export async function enterSystemPictureInPicture(
  video: HTMLVideoElement,
): Promise<{
  mode: SystemPictureInPictureMode;
  exit?: () => Promise<void>;
}> {
  if (isAndroidNative()) {
    await nativePictureInPicture.enter({
      width: video.videoWidth || 16,
      height: video.videoHeight || 9,
    });
    return { mode: "android" };
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
      await video.play();
      await pipVideo.requestPictureInPicture();
    }
    return { mode: "video" };
  }

  if (isTauri()) {
    return {
      mode: "tauri-window",
      exit: await enterTauriFloatingWindow(),
    };
  }

  throw new Error("当前系统或浏览器不支持视频悬浮窗");
}

export async function listenForNativePictureInPicture(
  listener: (active: boolean) => void,
) {
  if (!isAndroidNative()) return null;
  const handle = await nativePictureInPicture.addListener(
    "modeChanged",
    ({ active }) => listener(active),
  );
  const initial = await nativePictureInPicture.isActive();
  listener(initial.active);
  return handle;
}
