import test from "node:test";
import assert from "node:assert/strict";
import {
  dismissQixiInvitationForToday,
  qixiInvitationDismissKey,
  qixiInvitationIsActive,
  qixiShanghaiDateKey,
  shouldShowQixiInvitation,
} from "./.generated/qixi-invitation-policy-test.mjs";

const shanghaiTime = (iso) => new Date(iso);

test("qixi invitation uses the three requested Shanghai calendar days", () => {
  assert.equal(qixiShanghaiDateKey(shanghaiTime("2026-08-17T16:00:00Z")), "2026-08-18");
  assert.equal(qixiInvitationIsActive(shanghaiTime("2026-08-17T15:59:59Z")), false);
  assert.equal(qixiInvitationIsActive(shanghaiTime("2026-08-17T16:00:00Z")), true);
  assert.equal(qixiInvitationIsActive(shanghaiTime("2026-08-20T15:59:59Z")), true);
  assert.equal(qixiInvitationIsActive(shanghaiTime("2026-08-20T16:00:00Z")), false);
});

test("today-only dismissal does not suppress the following day", () => {
  const values = new Map();
  const storage = {
    getItem: (key) => values.get(key) ?? null,
    setItem: (key, value) => values.set(key, value),
  };
  const today = shanghaiTime("2026-08-18T04:00:00Z");
  const tomorrow = shanghaiTime("2026-08-19T04:00:00Z");

  assert.equal(shouldShowQixiInvitation(storage, today), true);
  dismissQixiInvitationForToday(storage, today);
  assert.equal(values.get(qixiInvitationDismissKey(today)), "true");
  assert.equal(shouldShowQixiInvitation(storage, today), false);
  assert.equal(shouldShowQixiInvitation(storage, tomorrow), true);
});
