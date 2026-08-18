import assert from "node:assert/strict";
import test from "node:test";
import {
  CALL_VIDEO_CONSTRAINTS,
  CALL_VIDEO_SEND_LIMITS,
  hasOfferCollision,
  shouldIgnoreOffer,
} from "./.generated/duo-call-policy-test.mjs";

test("perfect negotiation detects glare and assigns one ignoring peer", () => {
  const collision = hasOfferCollision({
    descriptionType: "offer",
    makingOffer: true,
    signalingState: "have-local-offer",
    settingRemoteAnswer: false,
  });
  assert.equal(collision, true);
  assert.equal(shouldIgnoreOffer(false, collision), true);
  assert.equal(shouldIgnoreOffer(true, collision), false);
  assert.equal(hasOfferCollision({
    descriptionType: "answer",
    makingOffer: true,
    signalingState: "have-local-offer",
    settingRemoteAnswer: true,
  }), false);
});

test("mobile video policy bounds capture and sender cost", () => {
  assert.equal(CALL_VIDEO_CONSTRAINTS.width.max, 1280);
  assert.equal(CALL_VIDEO_CONSTRAINTS.height.max, 720);
  assert.equal(CALL_VIDEO_CONSTRAINTS.frameRate.max, 24);
  assert.equal(CALL_VIDEO_SEND_LIMITS.maxFramerate, 24);
  assert.ok(CALL_VIDEO_SEND_LIMITS.maxBitrate <= 900_000);
});
