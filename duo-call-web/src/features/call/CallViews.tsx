import { Icon } from "@iconify/react";
import { type FormEvent, useEffect, useRef, useState } from "react";
import { callVisualMode, snapFloatingPosition } from "../../preferences";

export type CallVisualProps = {
  localMedia: MediaStream | null;
  remoteMedia: MediaStream | null;
  camera: boolean;
  mute: boolean;
  micLevel: number;
  calling: boolean;
  connectionState: RTCPeerConnectionState;
  remotePlaybackBlocked: boolean;
  onMute: () => void;
  onCamera: () => void;
  onResumeAudio: () => void;
  onPlaybackBlocked: (blocked: boolean) => void;
  registerRemoteVideo: (element: HTMLVideoElement, mounted: boolean) => void;
};

export function connectionText(state: RTCPeerConnectionState) {
  return {
    new: "尚未建立",
    connecting: "正在连接",
    connected: "连接稳定",
    disconnected: "连接中断",
    failed: "连接失败",
    closed: "连线已结束",
  }[state];
}

export function AudioDiagnostics({
  localMedia,
  remoteMedia,
  mute,
  connectionState,
  remotePlaybackBlocked,
  onResumeAudio,
}: Pick<
  CallVisualProps,
  | "localMedia"
  | "remoteMedia"
  | "mute"
  | "connectionState"
  | "remotePlaybackBlocked"
  | "onResumeAudio"
>) {
  const localTrack = localMedia?.getAudioTracks()[0];
  const remoteTrack = remoteMedia?.getAudioTracks()[0];
  const localText = !localTrack
    ? "未获取麦克风"
    : localTrack.readyState !== "live"
    ? "麦克风已结束"
    : mute || !localTrack.enabled
    ? "已静音"
    : "正在发送";
  const remoteText = !remoteTrack
    ? "等待对方声音"
    : remoteTrack.readyState === "live"
    ? remotePlaybackBlocked ? "等待点击播放" : "已收到音轨"
    : "对方音轨已结束";
  return (
    <div className="audio-diagnostics" aria-live="polite">
      <span><i className={localText === "正在发送" ? "ok" : ""} />我的声音：{localText}</span>
      <span><i className={remoteTrack?.readyState === "live" ? "ok" : ""} />对方声音：{remoteText}</span>
      <span><i className={connectionState === "connected" ? "ok" : ""} />网络：{connectionText(connectionState)}</span>
      {remotePlaybackBlocked && (
        <button type="button" onClick={onResumeAudio}>
          <Icon icon="solar:volume-loud-bold" />播放对方声音
        </button>
      )}
    </div>
  );
}

export function MicMeter({ level, muted }: { level: number; muted: boolean }) {
  return (
    <span className="mic-meter" title={`麦克风音量 ${muted ? 0 : level}%`}>
      {[18, 36, 54, 72, 90].map((threshold) => (
        <i
          key={threshold}
          className={!muted && level >= threshold ? "active" : ""}
        />
      ))}
    </span>
  );
}

export function CallControls({
  camera,
  mute,
  micLevel,
  calling,
  onMute,
  onCamera,
  onFullscreen,
  fullscreen,
}: Pick<
  CallVisualProps,
  "camera" | "mute" | "micLevel" | "calling" | "onMute" | "onCamera"
> & {
  onFullscreen: () => void;
  fullscreen?: boolean;
}) {
  return (
    <div className="call-controls">
      <button
        className={`media-control ${mute ? "is-off" : "is-on"}`}
        onClick={onMute}
        title={mute ? "开启语音" : "关闭麦克风"}
      >
        <Icon icon={mute ? "solar:microphone-3-bold" : "solar:microphone-bold"} />
        <span>{mute ? "开启语音" : "麦克风"}</span>
        <MicMeter level={micLevel} muted={mute || !calling} />
      </button>
      <button
        className={`media-control ${camera ? "is-on" : "is-off"}`}
        onClick={onCamera}
        title={camera ? "关闭摄像头" : "打开摄像头"}
      >
        <Icon icon={camera ? "solar:videocamera-bold" : "solar:videocamera-record-bold"} />
        <span>{camera ? "摄像头" : "开启视频"}</span>
      </button>
      <button className="media-control" onClick={onFullscreen}>
        <Icon icon={fullscreen ? "solar:minimize-square-3-bold" : "solar:maximize-square-3-bold"} />
        <span>{fullscreen ? "退出全屏" : "全屏"}</span>
      </button>
    </div>
  );
}

export function MobileCallMenu({
  camera,
  mute,
  micLevel,
  calling,
  onMute,
  onCamera,
  onFullscreen,
}: Pick<
  CallVisualProps,
  "camera" | "mute" | "micLevel" | "calling" | "onMute" | "onCamera"
> & {
  onFullscreen: () => void;
}) {
  const [open, setOpen] = useState(false);
  const run = (action: () => void) => {
    action();
    setOpen(false);
  };
  return (
    <div className={`mobile-call-menu ${open ? "is-open" : ""}`}>
      <button
        type="button"
        className={`mobile-call-trigger ${camera ? "is-on" : ""}`}
        aria-expanded={open}
        aria-label={open ? "收起连线控制" : "打开连线控制"}
        onClick={() => setOpen((value) => !value)}
      >
        <Icon icon={camera ? "solar:videocamera-bold" : "solar:videocamera-record-bold"} />
      </button>
      {open && (
        <div className="mobile-call-popover" aria-label="连线控制">
          <button
            type="button"
            className={mute ? "is-off" : "is-on"}
            onClick={() => run(onMute)}
            aria-label={mute ? "开启语音" : "关闭麦克风"}
          >
            <Icon icon={mute ? "solar:microphone-3-bold" : "solar:microphone-bold"} />
            <MicMeter level={micLevel} muted={mute || !calling} />
          </button>
          <button
            type="button"
            className={camera ? "is-on" : "is-off"}
            onClick={() => run(onCamera)}
            aria-label={camera ? "关闭摄像头" : "打开摄像头"}
          >
            <Icon icon={camera ? "solar:videocamera-bold" : "solar:videocamera-record-bold"} />
          </button>
          <button
            type="button"
            onClick={() => run(onFullscreen)}
            aria-label="进入全屏"
          >
            <Icon icon="solar:maximize-square-3-bold" />
          </button>
        </div>
      )}
    </div>
  );
}

export function CallStage({
  remoteConnected,
  onFullscreen,
  remoteMuted,
  ...props
}: CallVisualProps & {
  remoteConnected: boolean;
  onFullscreen: () => void;
  remoteMuted: boolean;
}) {
  const localMode = callVisualMode(props.camera, props.mute);
  return (
    <section className="call-stage">
      <VideoCard
        label="对方"
        kind="remote"
        onActivate={onFullscreen}
        stream={props.remoteMedia}
        active={remoteConnected}
        muted={remoteMuted}
        onPlaybackBlocked={props.onPlaybackBlocked}
        register={props.registerRemoteVideo}
      />
      <DraggableSurface className={`video-card local ${props.camera ? "has-video" : ""}`} onActivate={onFullscreen}>
        <MediaVideo stream={props.localMedia} muted mirrored />
        <div className="video-placeholder">
          <Icon icon={localMode === "audio" ? "solar:microphone-bold" : "solar:camera-add-bold-duotone"} />
          <span>{localMode === "audio" ? "纯语音中" : "我"}</span>
        </div>
        <p>我</p>
      </DraggableSurface>
      <AudioDiagnostics {...props} />
      <CallControls
        {...props}
        onFullscreen={onFullscreen}
      />
    </section>
  );
}

export function FullscreenCall({
  onExit,
  ...props
}: CallVisualProps & { onExit: () => void }) {
  return (
    <section className="call-fullscreen" role="dialog" aria-label="全屏视频连线">
      <MediaVideo
        stream={props.remoteMedia}
        muted={false}
        onPlaybackBlocked={props.onPlaybackBlocked}
        register={props.registerRemoteVideo}
      />
      {!props.remoteMedia && (
        <div className="fullscreen-placeholder">
          <Icon icon="solar:heart-angle-bold-duotone" />
          <strong>等待对方进入连线…</strong>
        </div>
      )}
      <DraggableSurface className={`fullscreen-local ${props.camera ? "has-video" : ""}`}>
        <MediaVideo stream={props.localMedia} muted mirrored />
        {!props.camera && <Icon icon={props.mute ? "solar:camera-add-bold-duotone" : "solar:microphone-bold"} />}
        <span>我</span>
      </DraggableSurface>
      <header>
        <div>
          <b>{props.calling ? "正在和 TA 连线" : "等待连线"}</b>
          <small>{connectionText(props.connectionState)}</small>
        </div>
      </header>
      <AudioDiagnostics {...props} />
      <CallControls
        {...props}
        fullscreen
        onFullscreen={onExit}
      />
    </section>
  );
}

export function NoteModal(
  { open, draft, busy, setDraft, close, submit }: {
    open: boolean;
    draft: string;
    busy: boolean;
    setDraft: (value: string) => void;
    close: () => void;
    submit: (event: FormEvent) => void;
  },
) {
  if (!open) return null;
  return (
    <div
      className="note-modal-backdrop"
      role="presentation"
      onMouseDown={close}
    >
      <form
        className="note-modal"
        onSubmit={submit}
        onMouseDown={(event) => event.stopPropagation()}
      >
        <button type="button" className="note-close" onClick={close}>
          <Icon icon="solar:close-circle-bold" />
        </button>
        <Icon className="note-modal-icon" icon="solar:heart-bold-duotone" />
        <p>留下一句话</p>
        <h2>今天想对 TA 说什么？</h2>
        <textarea
          value={draft}
          maxLength={500}
          autoFocus
          onChange={(event) => setDraft(event.target.value)}
          placeholder="写下此刻的小心情…"
        />
        <small>{draft.length}/500</small>
        <button
          className="note-submit"
          disabled={busy || !draft.trim()}
          type="submit"
        >
          {busy ? "正在收藏…" : "送出这句留言"}
          <Icon icon="solar:arrow-right-bold" />
        </button>
      </form>
    </div>
  );
}

export function DraggableSurface({
  className,
  children,
  fixed = false,
  onActivate,
}: {
  className: string;
  children: React.ReactNode;
  fixed?: boolean;
  onActivate?: () => void;
}) {
  const elementRef = useRef<HTMLDivElement>(null);
  const [position, setPosition] = useState<{ x: number; y: number } | null>(null);
  const drag = useRef<{
    pointerId: number;
    offsetX: number;
    offsetY: number;
    bounds: { left: number; top: number; width: number; height: number };
    itemWidth: number;
    itemHeight: number;
    startX: number;
    startY: number;
    moved: boolean;
  } | null>(null);
  const skipActivation = useRef(false);
  const onPointerDown = (event: React.PointerEvent<HTMLDivElement>) => {
    if (event.button !== 0) return;
    const element = elementRef.current;
    if (!element) return;
    const rect = element.getBoundingClientRect();
    const parentRect = fixed
      ? { left: 0, top: 0, width: window.innerWidth, height: window.innerHeight }
      : element.parentElement?.getBoundingClientRect();
    if (!parentRect) return;
    drag.current = {
      pointerId: event.pointerId,
      offsetX: event.clientX - rect.left,
      offsetY: event.clientY - rect.top,
      bounds: parentRect,
      itemWidth: rect.width,
      itemHeight: rect.height,
      startX: event.clientX,
      startY: event.clientY,
      moved: false,
    };
    element.setPointerCapture(event.pointerId);
  };
  const onPointerMove = (event: React.PointerEvent<HTMLDivElement>) => {
    const active = drag.current;
    if (!active || active.pointerId !== event.pointerId) return;
    if (Math.hypot(event.clientX - active.startX, event.clientY - active.startY) > 6) {
      active.moved = true;
    }
    if (!active.moved) return;
    const margin = 10;
    setPosition({
      x: Math.min(
        active.bounds.width - active.itemWidth - margin,
        Math.max(margin, event.clientX - active.bounds.left - active.offsetX),
      ),
      y: Math.min(
        active.bounds.height - active.itemHeight - margin,
        Math.max(margin, event.clientY - active.bounds.top - active.offsetY),
      ),
    });
  };
  const finishDrag = (event: React.PointerEvent<HTMLDivElement>) => {
    const active = drag.current;
    if (!active || active.pointerId !== event.pointerId) return;
    elementRef.current?.releasePointerCapture(event.pointerId);
    if (active.moved) {
      const current = position || {
        x: event.clientX - active.bounds.left - active.offsetX,
        y: event.clientY - active.bounds.top - active.offsetY,
      };
      setPosition(snapFloatingPosition(current, {
        width: active.bounds.width,
        height: active.bounds.height,
        itemWidth: active.itemWidth,
        itemHeight: active.itemHeight,
        margin: 10,
      }));
      skipActivation.current = true;
      window.setTimeout(() => {
        skipActivation.current = false;
      }, 0);
    }
    drag.current = null;
  };
  return (
    <div
      ref={elementRef}
      className={`${className} draggable-surface`}
      style={position
        ? { left: position.x, top: position.y, right: "auto", bottom: "auto" }
        : undefined}
      role={onActivate ? "button" : undefined}
      tabIndex={onActivate ? 0 : undefined}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={finishDrag}
      onPointerCancel={finishDrag}
      onClick={() => {
        if (!skipActivation.current) onActivate?.();
      }}
      onKeyDown={(event) => {
        if (onActivate && (event.key === "Enter" || event.key === " ")) {
          event.preventDefault();
          onActivate();
        }
      }}
    >
      {children}
    </div>
  );
}

export function VideoCard({
  label,
  kind,
  onActivate,
  stream,
  mirrored,
  active = false,
  muted,
  onPlaybackBlocked,
  register,
}: {
  label: string;
  kind: "local" | "remote";
  onActivate: () => void;
  stream?: MediaStream | null;
  mirrored?: boolean;
  active?: boolean;
  muted: boolean;
  onPlaybackBlocked?: (blocked: boolean) => void;
  register?: (element: HTMLVideoElement, mounted: boolean) => void;
}) {
  return (
    <article
      className={`video-card ${kind} ${
        active ? "has-video" : ""
      }`}
      onClick={onActivate}
    >
      <MediaVideo
        stream={stream || null}
        muted={muted}
        mirrored={mirrored}
        onPlaybackBlocked={onPlaybackBlocked}
        register={register}
      />
      <div className="video-placeholder">
        <Icon
          icon={kind === "remote"
            ? "solar:heart-angle-bold-duotone"
            : "solar:camera-add-bold-duotone"}
        />
        <span>
          {kind === "remote" ? "等待对方进入…" : "打开镜头，和 TA 打个招呼"}
        </span>
      </div>
      <p>
        {label} <Icon icon="solar:volume-loud-bold" />
      </p>
    </article>
  );
}

export function MediaVideo({
  stream,
  muted,
  mirrored = false,
  onPlaybackBlocked,
  register,
}: {
  stream: MediaStream | null;
  muted: boolean;
  mirrored?: boolean;
  onPlaybackBlocked?: (blocked: boolean) => void;
  register?: (element: HTMLVideoElement, mounted: boolean) => void;
}) {
  const elementRef = useRef<HTMLVideoElement>(null);
  useEffect(() => {
    const element = elementRef.current;
    if (!element) return;
    register?.(element, true);
    element.srcObject = stream;
    if (stream) {
      element.play().then(() => {
        if (!muted) onPlaybackBlocked?.(false);
      }).catch(() => {
        if (!muted) onPlaybackBlocked?.(true);
      });
    }
    return () => {
      register?.(element, false);
      element.srcObject = null;
    };
  }, [stream, muted, onPlaybackBlocked, register]);
  return (
    <video
      ref={elementRef}
      autoPlay
      muted={muted}
      playsInline
      className={mirrored ? "mirror" : ""}
    />
  );
}
