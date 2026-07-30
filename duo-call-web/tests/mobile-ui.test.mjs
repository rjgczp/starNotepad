import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import test from "node:test";

const roomSource = readFileSync(
  new URL("../src/features/room/Room.tsx", import.meta.url),
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
  assert.match(androidManifest, /android:supportsPictureInPicture="true"/);
  assert.match(
    androidPictureInPicturePlugin,
    /enterPictureInPictureMode\(builder\.build\(\)\)/,
  );
  assert.match(tauriCapabilities, /core:window:allow-set-always-on-top/);
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
