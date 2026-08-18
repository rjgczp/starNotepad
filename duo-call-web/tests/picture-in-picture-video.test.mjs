import assert from "node:assert/strict";
import test from "node:test";

class FakeMediaStream {
  constructor(track = { readyState: "live" }) {
    this.track = track;
  }

  getVideoTracks() {
    return [this.track];
  }
}

class FakeVideo extends EventTarget {
  constructor() {
    super();
    this.isConnected = true;
    this.srcObject = new FakeMediaStream();
    this.readyState = 0;
    this.videoWidth = 0;
    this.videoHeight = 0;
    this.playCalls = 0;
  }

  async play() {
    this.playCalls += 1;
  }
}

globalThis.MediaStream = FakeMediaStream;
globalThis.HTMLMediaElement = { HAVE_METADATA: 1 };
globalThis.window = {
  clearTimeout,
  setTimeout,
};

const {
  isPictureInPictureVideoReady,
  preparePictureInPictureVideo,
  waitForPictureInPictureVideo,
} = await import("./.generated/duo-picture-in-picture-video-test.mjs");

test("picture-in-picture waits until live video metadata has dimensions", async () => {
  const video = new FakeVideo();
  const prepared = preparePictureInPictureVideo(video);

  video.readyState = 1;
  video.videoWidth = 1280;
  video.videoHeight = 720;
  video.dispatchEvent(new Event("loadedmetadata"));

  await prepared;
  assert.equal(video.playCalls, 1);
  assert.equal(isPictureInPictureVideoReady(video), true);
});

test("detached video elements fail instead of reaching picture-in-picture", async () => {
  const video = new FakeVideo();
  video.isConnected = false;

  await assert.rejects(
    waitForPictureInPictureVideo(video, 10),
    /对方视频仍在加载/,
  );
  assert.equal(video.playCalls, 0);
});

test("ended remote video tracks fail instead of reaching picture-in-picture", async () => {
  const video = new FakeVideo();
  video.srcObject.track.readyState = "ended";

  await assert.rejects(
    waitForPictureInPictureVideo(video, 10),
    /对方视频仍在加载/,
  );
});

test("videos that explicitly disable picture-in-picture fail immediately", async () => {
  const video = new FakeVideo();
  video.disablePictureInPicture = true;

  await assert.rejects(
    waitForPictureInPictureVideo(video, 1000),
    /对方视频仍在加载/,
  );
});
