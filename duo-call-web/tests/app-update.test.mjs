import assert from "node:assert/strict";
import test from "node:test";
import { compareVersions } from "./.generated/duo-app-update-test.mjs";

test("update checks follow semantic version precedence", () => {
  assert.equal(compareVersions("1.2.0", "1.1.9"), 1);
  assert.equal(compareVersions("v1.2", "1.2.0"), 0);
  assert.equal(compareVersions("1.2.0", "1.2.0-rc.1"), 1);
  assert.equal(compareVersions("1.2.0-beta.11", "1.2.0-beta.2"), 1);
});
