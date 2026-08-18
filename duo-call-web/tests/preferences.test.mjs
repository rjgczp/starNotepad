import test from "node:test";
import assert from "node:assert/strict";
import {
  PREFERENCES_KEY,
  displayNameForSlot,
  loadPreferences,
  mergeProfileBySlot,
  newestAlbums,
  profileInitial,
  resolveProfileAvatar,
  profileStatusText,
  resolveTheme,
  snapFloatingPosition,
  messageSide,
  callVisualMode,
  chatDeliveryRoute,
  loopRecentItems,
  orderTreeMembers,
  treeNodeRegion,
  treeEventLabel,
  treeLeafIcon,
} from "./.generated/duo-preferences-test.mjs";

function storage(values = {}) {
  return {
    getItem(key) {
      return Object.hasOwn(values, key) ? values[key] : null;
    },
  };
}

test("migrates legacy theme and notification preferences", () => {
  const preferences = loadPreferences(storage({
    "duo-theme": "pink",
    "duo-notifications": "enabled",
  }));
  assert.equal(preferences.theme, "pink");
  assert.equal(preferences.defaultLightTheme, "pink");
  assert.equal(preferences.notificationsEnabled, true);
});

test("repairs invalid versioned preference fields", () => {
  const preferences = loadPreferences(storage({
    "duo-theme": "blue",
    [PREFERENCES_KEY]: JSON.stringify({
      version: 1,
      theme: "invalid",
      defaultLightTheme: "pink",
      followSystem: true,
      soundsEnabled: false,
    }),
  }));
  assert.equal(preferences.theme, "blue");
  assert.equal(preferences.defaultLightTheme, "pink");
  assert.equal(preferences.followSystem, true);
  assert.equal(preferences.soundsEnabled, false);
});

test("system following uses dark or the chosen light default", () => {
  const preferences = loadPreferences(storage({
    [PREFERENCES_KEY]: JSON.stringify({
      version: 1,
      theme: "blue",
      defaultLightTheme: "pink",
      followSystem: true,
      soundsEnabled: true,
      notificationsEnabled: false,
    }),
  }));
  assert.equal(resolveTheme(preferences, true), "dark");
  assert.equal(resolveTheme(preferences, false), "pink");
});

test("nickname fallback and six-item album window are stable", () => {
  const identities = [
    { slot: 1, displayName: "小海" },
    { slot: 2, displayName: "小月" },
  ];
  assert.equal(displayNameForSlot(identities, 2, 1), "小月");
  assert.equal(displayNameForSlot([], 1, 1), "我");
  assert.equal(displayNameForSlot([], 2, 1), "TA");
  assert.deepEqual(newestAlbums([1, 2, 3, 4, 5, 6, 7]), [1, 2, 3, 4, 5, 6]);
});

test("profile initials, status fallback and slot merging are stable", () => {
  assert.equal(profileInitial("  小海"), "小");
  assert.equal(profileInitial(""), "♡");
  assert.equal(resolveProfileAvatar("", "/uploads/new-avatar.jpg"), "/uploads/new-avatar.jpg");
  assert.equal(resolveProfileAvatar(" blob:preview ", "/uploads/avatar.jpg"), "blob:preview");
  assert.equal(resolveProfileAvatar(undefined, undefined), "");
  assert.equal(profileStatusText({ emoji: "☀️", label: " 今天很开心 " }), "☀️ 今天很开心");
  assert.equal(profileStatusText(null), "等你写下此刻");

  const profiles = [
    { slot: 1, displayName: "旧名字" },
    { slot: 2, displayName: "小月" },
  ];
  assert.deepEqual(
    mergeProfileBySlot(profiles, { slot: 1, displayName: "小海" }),
    [
      { slot: 1, displayName: "小海" },
      { slot: 2, displayName: "小月" },
    ],
  );
});

test("tree event helpers keep memory language human", () => {
  assert.equal(treeEventLabel("daily_reply"), "一封回信");
  assert.equal(treeEventLabel("album"), "一张照片");
  assert.equal(treeEventLabel("unknown"), "共同的小事");
  assert.match(treeLeafIcon("call"), /videocamera/);
});

test("floating previews stay bounded and snap to the nearest edge", () => {
  assert.deepEqual(
    snapFloatingPosition(
      { x: 180, y: -40 },
      { width: 400, height: 700, itemWidth: 100, itemHeight: 150, margin: 12 },
    ),
    { x: 288, y: 12 },
  );
  assert.deepEqual(
    snapFloatingPosition(
      { x: 20, y: 800 },
      { width: 400, height: 700, itemWidth: 100, itemHeight: 150, margin: 12 },
    ),
    { x: 12, y: 538 },
  );
});

test("message and call visual helpers keep identity stable", () => {
  assert.equal(messageSide(1, 1), "mine");
  assert.equal(messageSide(2, 1), "theirs");
  assert.equal(chatDeliveryRoute(true), "browser");
  assert.equal(chatDeliveryRoute(false), "wechat");
  assert.equal(callVisualMode(true, false), "video");
  assert.equal(callVisualMode(false, false), "audio");
  assert.equal(callVisualMode(false, true), "idle");
});

test("home tree keeps the signed-in member left and distributes visible nodes", () => {
  assert.deepEqual(orderTreeMembers([{ slot: 1 }, { slot: 2 }], 2).map((item) => item.slot), [2, 1]);
  assert.deepEqual([0, 1, 2, 3, 4].map(treeNodeRegion), ["lower", "upper", "middle", "middle", "lower"]);
  assert.deepEqual(loopRecentItems(["留言"]), ["留言", "留言", "留言"]);
});
