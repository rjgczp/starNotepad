import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import test from "node:test";

const roomSource = readFileSync(
  new URL("../src/features/room/Room.tsx", import.meta.url),
  "utf8",
);
const homeSource = readFileSync(
  new URL("../src/features/home/HomePanel.tsx", import.meta.url),
  "utf8",
);
const settingsSource = readFileSync(
  new URL("../src/features/settings/SettingsPanel.tsx", import.meta.url),
  "utf8",
);
const dialogSource = readFileSync(
  new URL("../src/components/AppDialog.tsx", import.meta.url),
  "utf8",
);
const imageViewerSource = readFileSync(
  new URL("../src/components/ImageViewer.tsx", import.meta.url),
  "utf8",
);
const callSource = readFileSync(
  new URL("../src/features/call/CallViews.tsx", import.meta.url),
  "utf8",
);
const polishStyles = readFileSync(
  new URL("../src/styles/polish.css", import.meta.url),
  "utf8",
);
const foundationStyles = readFileSync(
  new URL("../src/styles/foundation.css", import.meta.url),
  "utf8",
);
const callStyles = readFileSync(
  new URL("../src/styles/call.css", import.meta.url),
  "utf8",
);
const editorialStyles = readFileSync(
  new URL("../src/styles/editorial-home.css", import.meta.url),
  "utf8",
);
const pictureInPictureSource = readFileSync(
  new URL("../src/systemPictureInPicture.ts", import.meta.url),
  "utf8",
);
const androidManifest = readFileSync(
  new URL("../android/app/src/main/AndroidManifest.xml", import.meta.url),
  "utf8",
);
const androidPictureInPicturePlugin = readFileSync(
  new URL(
    "../android/app/src/main/java/ski/xiaoyu/duo/SystemPictureInPicturePlugin.java",
    import.meta.url,
  ),
  "utf8",
);
const androidMainActivity = readFileSync(
  new URL(
    "../android/app/src/main/java/ski/xiaoyu/duo/MainActivity.java",
    import.meta.url,
  ),
  "utf8",
);
const appSource = readFileSync(new URL("../src/App.tsx", import.meta.url), "utf8");
const indexSource = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const tauriCapabilities = readFileSync(
  new URL("../src-tauri/capabilities/default.json", import.meta.url),
  "utf8",
);

test("mobile call video stops above the composer and avoids an opaque message veil", () => {
  assert.match(
    polishStyles,
    /inset:\s*0 0 calc\(var\(--mobile-nav-offset\) \+ 68px\)/,
  );
  assert.match(
    polishStyles,
    /background:\s*linear-gradient\(to bottom, transparent 0, rgba\(20, 17, 19, \.1\) 100%\)/,
  );
});

test("touch devices suppress the blue tap rectangle but keep keyboard focus visible", () => {
  assert.match(foundationStyles, /-webkit-tap-highlight-color:\s*transparent/);
  assert.match(
    foundationStyles,
    /:focus:not\(:focus-visible\)[\s\S]*?outline:\s*none/,
  );
  assert.match(
    foundationStyles,
    /@media \(hover: none\) and \(pointer: coarse\)[\s\S]*?:active:not\(:disabled\)[\s\S]*?opacity:\s*\.82/,
  );
  assert.match(foundationStyles, /button:focus-visible[\s\S]*?outline:\s*3px/);
});

test("call labels stay on one line and collapse at the call-surface boundary", () => {
  assert.match(callStyles, /container-name:\s*call-surface/);
  assert.match(callStyles, /\.control-label[\s\S]*?white-space:\s*nowrap/);
  assert.match(
    polishStyles,
    /@container call-surface \(max-width: 440px\)[\s\S]*?\.control-label[\s\S]*?display:\s*none/,
  );
  assert.match(callSource, /className="control-label"/);
  assert.match(callSource, /aria-label=\{mute \? "开启语音" : "关闭麦克风"\}/);
});

test("destructive confirmations and notices use the in-app dialog", () => {
  const interactiveSource = `${roomSource}\n${settingsSource}`;
  assert.doesNotMatch(
    interactiveSource,
    /\b(?:window\.)?(?:alert|confirm|prompt)\s*\(/,
  );
  assert.match(dialogSource, /role=\{requiresConfirmation \? "alertdialog" : "dialog"\}/);
  assert.match(dialogSource, /aria-modal="true"/);
  assert.match(roomSource, /title: "移除这张照片？"/);
  assert.match(roomSource, /title: "退出爱情小屋？"/);
});

test("video background toggles chat history without hiding the composer", () => {
  assert.match(callSource, /onActivate=\{onBackgroundActivate \|\| onFullscreen\}/);
  assert.match(roomSource, /is-history-hidden/);
  assert.match(roomSource, /toggleChatHistory/);
  assert.match(
    polishStyles,
    /\.immersive-chat\.is-history-hidden \.messages/,
  );
  assert.doesNotMatch(
    polishStyles,
    /\.immersive-chat\.is-history-hidden \.composer/,
  );
});

test("content images share an in-app preview and local save action", () => {
  assert.match(imageViewerSource, /aria-label="图片预览"/);
  assert.match(imageViewerSource, /保存到本地/);
  assert.match(imageViewerSource, /URL\.createObjectURL\(await response\.blob\(\)\)/);
  assert.match(imageViewerSource, /anchor\.download = downloadName\(image\.src\)/);
});

test("system picture-in-picture has web, Android, and desktop fallbacks", () => {
  assert.match(pictureInPictureSource, /requestPictureInPicture/);
  assert.match(pictureInPictureSource, /enterTauriFloatingWindow/);
  assert.match(pictureInPictureSource, /SystemPictureInPicture/);
  assert.ok(
    pictureInPictureSource.indexOf("if (isTauri())") <
      pictureInPictureSource.indexOf("pipVideo.requestPictureInPicture"),
    "desktop clients should use the stable Tauri floating window before WebView PiP",
  );
  assert.doesNotMatch(
    roomSource,
    /setCallFullscreen\(false\);\s+const session = await enterSystemPictureInPicture/,
  );
  assert.match(androidManifest, /android:supportsPictureInPicture="true"/);
  assert.match(androidManifest, /FOREGROUND_SERVICE_CAMERA/);
  assert.match(androidManifest, /POST_NOTIFICATIONS/);
  assert.match(androidPictureInPicturePlugin, /enterOnBackground/);
  assert.match(androidPictureInPicturePlugin, /requestNotificationPermission/);
  assert.match(
    androidPictureInPicturePlugin,
    /enterPictureInPictureMode\(builder\.build\(\)\)/,
  );
  assert.match(pictureInPictureSource, /ANDROID_PICTURE_IN_PICTURE_CLASS/);
  assert.match(
    pictureInPictureSource,
    /setAndroidPictureInPicturePresentation\(true\)[\s\S]*?nativePictureInPicture\.enter/,
  );
  assert.match(
    polishStyles,
    /html\.android-system-pip \.call-stage > :not\(\.video-card\.remote\)[\s\S]*?display:\s*none !important/,
  );
  assert.match(
    androidPictureInPicturePlugin,
    /notifyModeChanged\(true\);\s+boolean active = activity\.enterPictureInPictureMode/,
  );
  assert.match(tauriCapabilities, /core:window:allow-set-always-on-top/);
  assert.match(tauriCapabilities, /core:window:allow-inner-size/);
  assert.match(tauriCapabilities, /core:window:allow-set-min-size/);
  assert.match(pictureInPictureSource, /setMinSize\(null\)/);
  assert.match(
    callSource,
    /element\.srcObject = stream;[\s\S]*?\}, \[stream, register\]\);/,
  );
});

test("late video recovery and native notification paths are wired", () => {
  assert.match(roomSource, /type: "media-refresh"/);
  assert.match(roomSource, /remoteVideoRecoveryAttempts\.current >= 6/);
  assert.match(roomSource, /isAndroidNativePlatform\(\)/);
  assert.match(roomSource, /showAndroidMessageNotification/);
  assert.match(roomSource, /messages\?limit=10/);
  assert.match(roomSource, /shouldIgnoreOffer/);
  assert.match(roomSource, /restartIce\(\)/);
  assert.match(roomSource, /replaceTrack\(null\)/);
});

test("Android edge-to-edge and foreground update checks are wired", () => {
  assert.match(androidMainActivity, /WindowCompat\.enableEdgeToEdge\(getWindow\(\)\)/);
  assert.match(indexSource, /viewport-fit=cover/);
  assert.match(appSource, /visibilitychange/);
  assert.match(appSource, /release\.forceUpdate \|\| !dismissed/);
});

test("editorial home replaces the rendered tree and keeps pair actions wired", () => {
  assert.match(homeSource, /US, LATELY\./);
  assert.match(homeSource, /最近的我们/);
  assert.match(homeSource, /editorial-cover/);
  assert.match(homeSource, /editorial-moment-grid/);
  assert.match(homeSource, /editorial-weekly-stories/);
  assert.match(homeSource, /state-\$\{missYouState\}/);
  assert.match(homeSource, /onClick=\{\(\) => void triggerMissYou\(\)\}/);
  assert.match(homeSource, /openView\?\.\("call"\)/);
  assert.match(homeSource, /openView\?\.\("album"\)/);
  assert.match(homeSource, /openView\?\.\("settings"\)/);
  assert.doesNotMatch(homeSource, /<SvgMemoryTree/);
  assert.doesNotMatch(homeSource, /className="memory-tree/);
  assert.doesNotMatch(homeSource, /tree-heart-button/);
  assert.doesNotMatch(homeSource, /totalGrowth/);
  assert.match(editorialStyles, /@media \(max-width: 760px\)/);
  assert.match(editorialStyles, /@media \(max-width: 360px\)/);
  assert.match(editorialStyles, /prefers-reduced-motion: reduce/);
  assert.match(roomSource, /duoCall\/miss-you\/pending/);
  assert.match(roomSource, /data\.type === "miss-you"/);
  assert.match(roomSource, /duoCall\/miss-you`/);
});

test("packaged clients and web use the shared branded logo", () => {
  for (const path of [
    "../assets/brand/logo-master.png",
    "../public/app-icon.png",
    "../src-tauri/icons/icon.ico",
    "../src-tauri/icons/icon.icns",
    "../android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
    "../android/app/src/main/res/drawable-port-xhdpi/splash.png",
  ]) {
    assert.equal(existsSync(new URL(path, import.meta.url)), true, path);
  }
});
