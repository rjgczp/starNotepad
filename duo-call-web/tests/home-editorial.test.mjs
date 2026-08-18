import assert from "node:assert/strict";
import test from "node:test";

import {
  editorialFallbackCopy,
  editorialMember,
  editorialWeekLabel,
  selectEditorialCover,
  selectEditorialMoments,
  selectLatestWeeklyMemory,
  selectRewindMoment,
  weeklyMemoryLabel,
} from "./.generated/home-editorial-test.mjs";

const event = (ID, eventType, occurredAt, slot = 1) => ({
  ID,
  eventType,
  occurredAt,
  slot,
  sourceId: ID,
  growth: 4,
  title: `event-${ID}`,
  summary: "",
  imageUrl: "",
});

test("editorial moments are displayable, stable and newest first", () => {
  const moments = selectEditorialMoments([
    event(2, "album", "2026-08-12T10:00:00Z"),
    event(3, "chat", "2026-08-13T10:00:00Z"),
    event(1, "note", "2026-08-12T10:00:00Z"),
    event(9, "unsupported", "2026-08-14T10:00:00Z"),
  ], 3);
  assert.deepEqual(moments.map(({ ID }) => ID), [3, 2, 1]);
});

test("cover and weekly story selection do not depend on input order", () => {
  assert.equal(selectEditorialCover([
    { ID: 1, uploadedAt: "2026-08-01T00:00:00Z" },
    { ID: 2, uploadedAt: "2026-08-10T00:00:00Z" },
  ])?.ID, 2);
  assert.equal(selectLatestWeeklyMemory([
    { ID: 1, weekKey: "2026-W30" },
    { ID: 2, weekKey: "2026-W32" },
  ])?.ID, 2);
  assert.equal(selectEditorialCover([]), null);
  assert.equal(selectLatestWeeklyMemory([]), null);
});

test("rewind favors this day in a previous year and otherwise uses the oldest moment", () => {
  const events = [
    event(3, "chat", "2026-08-13T10:00:00Z"),
    event(2, "album", "2025-08-14T10:00:00Z"),
    event(1, "note", "2024-07-01T10:00:00Z"),
  ];
  assert.equal(selectRewindMoment(events, new Date("2026-08-14T12:00:00Z"))?.ID, 2);
  assert.equal(selectRewindMoment(events, new Date("2026-01-01T12:00:00Z"))?.ID, 1);
  assert.equal(selectRewindMoment([], new Date()) , null);
});

test("editorial labels and empty copy are predictable", () => {
  assert.equal(editorialWeekLabel(new Date("2026-08-14T00:00:00Z")), "2026 · WEEK 33");
  assert.equal(weeklyMemoryLabel("2026-W03"), "2026 · 第 3 周");
  assert.equal(editorialMember([{ slot: 2, displayName: "小月" }], 2)?.displayName, "小月");
  assert.match(editorialFallbackCopy(0), /第一行/);
  assert.match(editorialFallbackCopy(3), /这一期/);
});
