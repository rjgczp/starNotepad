import assert from "node:assert/strict";
import test from "node:test";
import {
  nativeApiConfigurationError,
  normalizeApiBase,
  resolveHostedMediaUrl,
  webSocketUrl,
} from "./.generated/duo-runtime-test.mjs";

test("hosted web keeps the same-origin API prefix", () => {
  assert.equal(normalizeApiBase(undefined), "/api");
  assert.equal(normalizeApiBase("/api/"), "/api");
});

test("native builds require an absolute HTTPS API endpoint", () => {
  assert.match(
    nativeApiConfigurationError({
      configuredApiUrl: "/api",
      currentOrigin: "http://localhost",
      nativeBuild: true,
    }),
    /绝对 HTTPS/,
  );
  assert.equal(
    nativeApiConfigurationError({
      configuredApiUrl: "https://ai.xiaoyu.ski/api",
      currentOrigin: "http://localhost",
      nativeBuild: true,
    }),
    "",
  );
});

test("secure API endpoints produce authenticated WSS URLs", () => {
  assert.equal(
    webSocketUrl(
      "https://ai.xiaoyu.ski/api",
      "http://localhost",
      "a token",
    ),
    "wss://ai.xiaoyu.ski/api/duoCall/ws?token=a+token",
  );
});

test("root-relative media is resolved against the hosted API origin", () => {
  assert.equal(
    resolveHostedMediaUrl(
      "/uploads/file/duo-call/photo.webp",
      "https://ai.xiaoyu.ski/api",
      "http://localhost",
    ),
    "https://ai.xiaoyu.ski/uploads/file/duo-call/photo.webp",
  );
  assert.equal(
    resolveHostedMediaUrl(
      "blob:https://ai.xiaoyu.ski/example",
      "https://ai.xiaoyu.ski/api",
      "http://localhost",
    ),
    "blob:https://ai.xiaoyu.ski/example",
  );
});
