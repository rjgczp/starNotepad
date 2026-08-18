export const CALL_VIDEO_CONSTRAINTS: MediaTrackConstraints = {
  facingMode: { ideal: "user" },
  width: { ideal: 960, max: 1280 },
  height: { ideal: 540, max: 720 },
  frameRate: { ideal: 20, max: 24 },
};

export const CALL_VIDEO_SEND_LIMITS = {
  maxBitrate: 900_000,
  maxFramerate: 24,
} as const;

export function hasOfferCollision({
  descriptionType,
  makingOffer,
  signalingState,
  settingRemoteAnswer,
}: {
  descriptionType: RTCSdpType;
  makingOffer: boolean;
  signalingState: RTCSignalingState;
  settingRemoteAnswer: boolean;
}) {
  const readyForOffer = !makingOffer &&
    (signalingState === "stable" || settingRemoteAnswer);
  return descriptionType === "offer" && !readyForOffer;
}

export function shouldIgnoreOffer(polite: boolean, collision: boolean) {
  return !polite && collision;
}
