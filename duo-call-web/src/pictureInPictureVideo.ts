const VIDEO_READY_TIMEOUT_MS = 1500;

export const VIDEO_NOT_READY_MESSAGE = "对方视频仍在加载，请稍后再试。";

function hasLiveVideoTrack(video: HTMLVideoElement) {
  const stream = video.srcObject;
  return stream instanceof MediaStream &&
    stream.getVideoTracks().some((track) => track.readyState === "live");
}

export function isPictureInPictureVideoReady(video: HTMLVideoElement) {
  return video.isConnected &&
    !video.disablePictureInPicture &&
    hasLiveVideoTrack(video) &&
    video.readyState >= HTMLMediaElement.HAVE_METADATA &&
    video.videoWidth > 0 &&
    video.videoHeight > 0;
}

export function waitForPictureInPictureVideo(
  video: HTMLVideoElement,
  timeoutMs = VIDEO_READY_TIMEOUT_MS,
) {
  if (isPictureInPictureVideoReady(video)) return Promise.resolve();
  if (
    !video.isConnected ||
    video.disablePictureInPicture ||
    !hasLiveVideoTrack(video)
  ) {
    return Promise.reject(new Error(VIDEO_NOT_READY_MESSAGE));
  }

  return new Promise<void>((resolve, reject) => {
    const readyEvents = ["loadedmetadata", "loadeddata", "canplay", "playing", "resize"];
    const terminalEvents = ["abort", "emptied", "error"];
    let timer = 0;

    const cleanup = () => {
      window.clearTimeout(timer);
      readyEvents.forEach((eventName) => {
        video.removeEventListener(eventName, check);
      });
      terminalEvents.forEach((eventName) => {
        video.removeEventListener(eventName, fail);
      });
    };
    const finish = (callback: () => void) => {
      cleanup();
      callback();
    };
    const check = () => {
      if (isPictureInPictureVideoReady(video)) {
        finish(resolve);
      } else if (
        !video.isConnected ||
        video.disablePictureInPicture ||
        !hasLiveVideoTrack(video)
      ) {
        finish(() => reject(new Error(VIDEO_NOT_READY_MESSAGE)));
      }
    };
    const fail = () => {
      finish(() => reject(new Error(VIDEO_NOT_READY_MESSAGE)));
    };

    readyEvents.forEach((eventName) => {
      video.addEventListener(eventName, check);
    });
    terminalEvents.forEach((eventName) => {
      video.addEventListener(eventName, fail);
    });
    timer = window.setTimeout(fail, timeoutMs);
    check();
  });
}

export async function preparePictureInPictureVideo(video: HTMLVideoElement) {
  await waitForPictureInPictureVideo(video);
  try {
    await video.play();
  } catch {
    throw new Error("无法播放对方视频，请点击画面后再试。");
  }
  if (!isPictureInPictureVideoReady(video)) {
    throw new Error(VIDEO_NOT_READY_MESSAGE);
  }
}
