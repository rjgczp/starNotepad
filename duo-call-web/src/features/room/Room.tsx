import { Icon } from "@iconify/react";
import {
  type FormEvent,
  Fragment,
  useCallback,
  useEffect,
  useRef,
  useState,
} from "react";
import {
  chatDeliveryRoute,
  type DuoPreferences,
  mergeProfileBySlot,
  newestAlbums,
  type Theme,
} from "../../preferences";
import {
  API_BASE_URL as api,
  EMOJIS as emojis,
  type AlbumItem,
  type Anniversary,
  type CottageView,
  type DailyState,
  type DuoStatus,
  type Identity,
  type LoveNote,
  type Message,
  type MissYouSignal,
  type TreeState,
} from "../../domain";
import {
  messageTimeLabel,
  readAPIPayload,
  shouldShowMessageTime,
  slotFromSession,
} from "../../lib/api";
import { webSocketUrl } from "../../runtime";
import {
  CALL_VIDEO_CONSTRAINTS,
  CALL_VIDEO_SEND_LIMITS,
  hasOfferCollision,
  shouldIgnoreOffer,
} from "../../callPolicy";
import {
  enterSystemPictureInPicture,
  listenForNativePictureInPicture,
  setAndroidCallForeground,
  isAndroidNativePlatform,
  requestAndroidNotificationPermission,
  showAndroidMessageNotification,
  type SystemPictureInPictureMode,
} from "../../systemPictureInPicture";
import {
  ThemeDecorations,
  ThemePicker,
} from "../../components/ThemeControls";
import {
  AppDialog,
  type AppDialogTone,
} from "../../components/AppDialog";
import {
  ChatMessage,
} from "../../components/ProfileAvatar";
import { HomePanel } from "../home/HomePanel";
import { DailyPanel } from "../daily/DailyPanel";
import { AlbumPanel } from "../album/AlbumPanel";
import { SettingsPanel } from "../settings/SettingsPanel";
import {
  CallStage,
  DraggableSurface,
  FullscreenCall,
  MediaVideo,
  MobileCallMenu,
  NoteModal,
} from "../call/CallViews";

async function constrainVideoSender(sender: RTCRtpSender) {
  const parameters = sender.getParameters();
  if (!parameters.encodings.length) return;
  for (const encoding of parameters.encodings) {
    encoding.maxBitrate = CALL_VIDEO_SEND_LIMITS.maxBitrate;
    encoding.maxFramerate = CALL_VIDEO_SEND_LIMITS.maxFramerate;
  }
  await sender.setParameters(parameters);
}

export function Room(
  { token, theme, setTheme, preferences, setPreferences, leave }: {
    token: string;
    theme: Theme;
    setTheme: (value: Theme) => void;
    preferences: DuoPreferences;
    setPreferences: React.Dispatch<React.SetStateAction<DuoPreferences>>;
    leave: () => void;
  },
) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [messagesHasMore, setMessagesHasMore] = useState(false);
  const [loadingOlderMessages, setLoadingOlderMessages] = useState(false);
  const [chatWechatEnabled, setChatWechatEnabled] = useState(false);
  const [notificationPermission, setNotificationPermission] = useState<
    NotificationPermission | "unsupported"
  >(() => "Notification" in window ? Notification.permission : "unsupported");
  const [notificationGuideOpen, setNotificationGuideOpen] = useState(false);
  const [draft, setDraft] = useState("");
  const [me, setMe] = useState(() => slotFromSession(token));
  const [emojiOpen, setEmojiOpen] = useState(false);
  const [chatHistoryVisible, setChatHistoryVisible] = useState(true);
  const [camera, setCamera] = useState(false);
  const [mute, setMute] = useState(true);
  const [unread, setUnread] = useState(0);
  const [calling, setCalling] = useState(false);
  const [remoteConnected, setRemoteConnected] = useState(false);
  const [socketConnected, setSocketConnected] = useState(false);
  const [partnerOnline, setPartnerOnline] = useState(false);
  const [callFullscreen, setCallFullscreen] = useState(false);
  const [systemPictureInPicture, setSystemPictureInPicture] =
    useState<SystemPictureInPictureMode | null>(null);
  const [localMedia, setLocalMedia] = useState<MediaStream | null>(null);
  const [remoteMedia, setRemoteMedia] = useState<MediaStream | null>(null);
  const [connectionState, setConnectionState] =
    useState<RTCPeerConnectionState>("new");
  const [remotePlaybackBlocked, setRemotePlaybackBlocked] = useState(false);
  const [micLevel, setMicLevel] = useState(0);
  const [iceServers, setIceServers] = useState<RTCIceServer[]>(() => {
    try {
      return JSON.parse(import.meta.env.VITE_DUO_ICE_SERVERS || "[]");
    } catch {
      return [];
    }
  });
  const [view, setView] = useState<CottageView>(() => {
    const pushReference = new URLSearchParams(location.search).get("push");
    return pushReference?.startsWith("daily:") ? "daily" : "home";
  });
  const [homeAlbums, setHomeAlbums] = useState<AlbumItem[]>([]);
  const [albumItems, setAlbumItems] = useState<AlbumItem[]>([]);
  const [albumTotal, setAlbumTotal] = useState(0);
  const [albumPage, setAlbumPage] = useState(1);
  const [anniversaries, setAnniversaries] = useState<Anniversary[]>([]);
  const [notes, setNotes] = useState<LoveNote[]>([]);
  const [noteOpen, setNoteOpen] = useState(false);
  const [noteDraft, setNoteDraft] = useState("");
  const [daily, setDaily] = useState<DailyState | null>(null);
  const [dailyHistory, setDailyHistory] = useState<DailyState[]>([]);
  const [dailyDraft, setDailyDraft] = useState("");
  const [dailyBusy, setDailyBusy] = useState(false);
  const [busy, setBusy] = useState(false);
  const [identities, setIdentities] = useState<Identity[]>([]);
  const [statuses, setStatuses] = useState<DuoStatus[]>([]);
  const [tree, setTree] = useState<TreeState | null>(null);
  const [dialog, setDialog] = useState<{
    title: string;
    message: string;
    confirmLabel: string;
    cancelLabel?: string;
    tone?: AppDialogTone;
  } | null>(null);
  const dialogResolver = useRef<((confirmed: boolean) => void) | null>(null);
  const socket = useRef<WebSocket | null>(null);
  const peer = useRef<RTCPeerConnection | null>(null);
  const stream = useRef<MediaStream | null>(null);
  const pendingIce = useRef<RTCIceCandidateInit[]>([]);
  const makingOffer = useRef(false);
  const ignoreOffer = useRef(false);
  const settingRemoteAnswer = useRef(false);
  const videoSender = useRef<RTCRtpSender | null>(null);
  const iceRestartTimer = useRef<number | null>(null);
  const remoteVideoRecoveryAttempts = useRef(0);
  const iceServersRef = useRef<RTCIceServer[]>(iceServers);
  const meRef = useRef(0);
  const viewRef = useRef<CottageView>("home");
  const preferencesRef = useRef(preferences);
  const partnerOnlineRef = useRef(false);
  const identitiesRef = useRef<Identity[]>([]);
  const toneContext = useRef<AudioContext | null>(null);
  const remoteVideos = useRef(new Set<HTMLVideoElement>());
  const exitSystemFloatingWindow = useRef<(() => Promise<void>) | null>(null);
  const systemPictureInPictureOpening = useRef(false);
  const shownMissYou = useRef(new Set<number>());
  const messagesEnd = useRef<HTMLDivElement>(null);
  const messagesScroller = useRef<HTMLDivElement>(null);
  const shouldStickMessagesToBottom = useRef(true);
  const chatImageInput = useRef<HTMLInputElement>(null);
  const albumInput = useRef<HTMLInputElement>(null);
  const headers = { Authorization: `Bearer ${token}` };
  const dismissDialog = useCallback((confirmed: boolean) => {
    const resolve = dialogResolver.current;
    dialogResolver.current = null;
    setDialog(null);
    resolve?.(confirmed);
  }, []);
  const showNotice = useCallback((message: string, title = "提示") => {
    dialogResolver.current?.(false);
    dialogResolver.current = null;
    setDialog({
      title,
      message,
      confirmLabel: "知道了",
    });
  }, []);
  const acknowledgeMissYou = (id: number) => {
    fetch(`${api}/duoCall/miss-you/${id}/ack`, {
      method: "POST",
      headers,
    }).catch(() => undefined);
  };
  const presentMissYou = (signal: MissYouSignal) => {
    if (!signal?.ID || shownMissYou.current.has(signal.ID)) return;
    shownMissYou.current.add(signal.ID);
    showNotice("对方刚刚在偷偷想你喔", "收到一份想念");
    acknowledgeMissYou(signal.ID);
  };
  const closeSystemFloatingWindow = useCallback(async () => {
    const exit = exitSystemFloatingWindow.current;
    if (!exit) {
      setSystemPictureInPicture(null);
      return;
    }
    try {
      await exit();
      exitSystemFloatingWindow.current = null;
      setSystemPictureInPicture(null);
    } catch (error) {
      showNotice(
        error instanceof Error ? error.message : "系统悬浮窗恢复失败",
        "退出悬浮窗失败",
      );
    }
  }, [showNotice]);
  const askConfirmation = useCallback((
    message: string,
    {
      title = "请确认",
      confirmLabel = "确认",
      cancelLabel = "取消",
      tone = "default",
    }: {
      title?: string;
      confirmLabel?: string;
      cancelLabel?: string;
      tone?: AppDialogTone;
    } = {},
  ) => new Promise<boolean>((resolve) => {
    dialogResolver.current?.(false);
    dialogResolver.current = resolve;
    setDialog({
      title,
      message,
      confirmLabel,
      cancelLabel,
      tone,
    });
  }), []);
  const sendEvent = (event: object) => {
    if (socket.current?.readyState === WebSocket.OPEN) {
      socket.current.send(JSON.stringify(event));
    }
  };
  const waitForSocket = () => new Promise<void>((resolve, reject) => {
    const ws = socket.current;
    if (ws?.readyState === WebSocket.OPEN) return resolve();
    if (!ws || ws.readyState === WebSocket.CLOSING || ws.readyState === WebSocket.CLOSED) {
      return reject(new Error("信令连接尚未建立"));
    }
    const timer = window.setTimeout(() => {
      ws.removeEventListener("open", onOpen);
      reject(new Error("信令连接超时"));
    }, 5000);
    const onOpen = () => {
      window.clearTimeout(timer);
      resolve();
    };
    ws.addEventListener("open", onOpen, { once: true });
  });
  const flushPendingIce = async (target: RTCPeerConnection) => {
    if (!target.remoteDescription) return;
    const candidates = pendingIce.current.splice(0);
    for (const candidate of candidates) {
      await target.addIceCandidate(candidate);
    }
  };
  const scrollMessagesToBottom = (behavior: ScrollBehavior = "smooth") => {
    requestAnimationFrame(() => {
      messagesEnd.current?.scrollIntoView({ behavior, block: "end" });
    });
  };
  useEffect(() => {
    if (view === "call" && shouldStickMessagesToBottom.current) {
      scrollMessagesToBottom();
    }
  }, [messages, view]);
  useEffect(() => {
    meRef.current = me;
  }, [me]);
  useEffect(() => {
    const hasLiveLocalVideo = localMedia?.getVideoTracks().some((track) =>
      track.readyState === "live" && track.enabled
    );
    const hasLiveRemoteVideo = remoteMedia?.getVideoTracks().some((track) =>
      track.readyState === "live" && !track.muted
    );
    const hasLiveVideo = Boolean(hasLiveLocalVideo || hasLiveRemoteVideo);
    void setAndroidCallForeground(calling && hasLiveVideo).catch(() => undefined);
    return () => { void setAndroidCallForeground(false).catch(() => undefined); };
  }, [calling, localMedia, remoteMedia]);
  useEffect(() => {
    if (!daily || daily.revealedAt || !me) return;
    const ownReply = daily.replies?.find((reply) => reply.slot === me);
    if (ownReply?.content) setDailyDraft(ownReply.content);
  }, [daily, me]);
  useEffect(() => {
    viewRef.current = view;
    if (view !== "call") setCallFullscreen(false);
  }, [view]);
  useEffect(() => {
    iceServersRef.current = iceServers;
  }, [iceServers]);
  useEffect(() => {
    preferencesRef.current = preferences;
  }, [preferences]);
  useEffect(() => {
    partnerOnlineRef.current = partnerOnline;
  }, [partnerOnline]);
  useEffect(() => {
    identitiesRef.current = identities;
  }, [identities]);
  const unlockToneAudio = async () => {
    const AudioContextClass = window.AudioContext ||
      (window as typeof window & { webkitAudioContext?: typeof AudioContext })
        .webkitAudioContext;
    if (!AudioContextClass) return null;
    if (!toneContext.current) toneContext.current = new AudioContextClass();
    if (toneContext.current.state === "suspended") {
      await toneContext.current.resume();
    }
    return toneContext.current;
  };
  const playPresenceTone = async () => {
    if (!preferencesRef.current.soundsEnabled) return;
    try {
      const context = await unlockToneAudio();
      if (!context) return;
      const start = context.currentTime;
      [659.25, 783.99].forEach((frequency, index) => {
        const oscillator = context.createOscillator();
        const gain = context.createGain();
        oscillator.type = "sine";
        oscillator.frequency.value = frequency;
        gain.gain.setValueAtTime(0.0001, start + index * .12);
        gain.gain.exponentialRampToValueAtTime(.075, start + index * .12 + .02);
        gain.gain.exponentialRampToValueAtTime(
          .0001,
          start + index * .12 + .19,
        );
        oscillator.connect(gain);
        gain.connect(context.destination);
        oscillator.start(start + index * .12);
        oscillator.stop(start + index * .12 + .2);
      });
    } catch { /* Browsers may require another explicit interaction. */ }
  };
  useEffect(() => {
    const unlock = () => {
      void unlockToneAudio();
    };
    window.addEventListener("pointerdown", unlock, { once: true });
    window.addEventListener("keydown", unlock, { once: true });
    return () => {
      window.removeEventListener("pointerdown", unlock);
      window.removeEventListener("keydown", unlock);
    };
  }, []);
  const markMessagesRead = () => {
    setUnread(0);
    document.title = "Love Cottage · 爱情小屋";
    fetch(`${api}/duoCall/messages/read`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
    }).catch(() => undefined);
  };
  const ensureChatWechatFallback = async () => {
    try {
      const response = await fetch(`${api}/duoCall/messages/wechat`, {
        method: "PUT",
        headers: { ...headers, "Content-Type": "application/json" },
        body: JSON.stringify({ enabled: true }),
      });
      const payload = await readAPIPayload(response, "微信消息设置失败");
      setChatWechatEnabled(Boolean(payload.data?.enabled));
    } catch {
      setChatWechatEnabled(false);
    }
  };
  const enableSystemNotifications = async () => {
    if (isAndroidNativePlatform()) {
      const granted = await requestAndroidNotificationPermission();
      setNotificationPermission(granted ? "granted" : "denied");
      setNotificationGuideOpen(!granted);
      return;
    }
    if (!("Notification" in window)) {
      setNotificationPermission("unsupported");
      setNotificationGuideOpen(true);
      return;
    }
    if (Notification.permission === "denied") {
      setNotificationPermission("denied");
      setNotificationGuideOpen(true);
      return;
    }
    const permission = await Notification.requestPermission();
    setNotificationPermission(permission);
    setNotificationGuideOpen(permission !== "granted");
  };
  const showSystemMessageNotification = (message: Message) => {
    const sender = identitiesRef.current.find((identity) =>
      identity.slot === message.senderSlot
    )?.displayName || "TA";
    if (isAndroidNativePlatform()) {
      if (message.senderSlot !== meRef.current) {
        void showAndroidMessageNotification(
          message.ID,
          `${sender} 发来新消息`,
          message.kind === "image" ? "发来了一张照片" : message.content,
        );
      }
      return;
    }
    if (
      chatDeliveryRoute(partnerOnlineRef.current) !== "browser" ||
      !("Notification" in window) ||
      Notification.permission !== "granted" ||
      message.senderSlot === meRef.current
    ) return;
    const notification = new Notification(`${sender} 发来新消息`, {
      body: message.kind === "image" ? "发来了一张照片" : message.content,
      tag: `duo-chat-${message.ID}`,
    });
    notification.onclick = () => {
      window.focus();
      setView("call");
      notification.close();
    };
    window.setTimeout(() => notification.close(), 8000);
  };
  const loadOlderMessages = async () => {
    if (loadingOlderMessages || !messagesHasMore || !messages.length) return;
    const scroller = messagesScroller.current;
    const beforeHeight = scroller?.scrollHeight || 0;
    const beforeTop = scroller?.scrollTop || 0;
    setLoadingOlderMessages(true);
    shouldStickMessagesToBottom.current = false;
    try {
      const firstID = messages[0]?.ID;
      const response = await fetch(`${api}/duoCall/messages?beforeId=${firstID}&limit=10`, { headers });
      const payload = await readAPIPayload(response, "加载更早消息失败");
      const items = Array.isArray(payload.data) ? payload.data : payload.data?.items || [];
      const older = [...items].reverse() as Message[];
      setMessages((current) => [...older, ...current]);
      setMessagesHasMore(Boolean(payload.data?.hasMore));
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          if (scroller) {
            scroller.scrollTop = beforeTop + scroller.scrollHeight - beforeHeight;
          }
        });
      });
    } finally {
      setLoadingOlderMessages(false);
    }
  };
  const onMessagesScroll = () => {
    const scroller = messagesScroller.current;
    if (!scroller) return;
    shouldStickMessagesToBottom.current =
      scroller.scrollHeight - scroller.clientHeight - scroller.scrollTop < 72;
    if (scroller.scrollTop <= 24) void loadOlderMessages();
  };
  useEffect(() => {
    const readWhenVisible = () => {
      if (
        document.visibilityState === "visible" && viewRef.current === "call"
      ) {
        markMessagesRead();
      }
    };
    if (view === "call") markMessagesRead();
    document.addEventListener("visibilitychange", readWhenVisible);
    window.addEventListener("focus", readWhenVisible);
    return () => {
      document.removeEventListener("visibilitychange", readWhenVisible);
      window.removeEventListener("focus", readWhenVisible);
    };
    // This effect follows visibility and route changes; recreating it for the
    // request helper would register duplicate listeners on every render.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [view, token]);
  const closeCall = () => {
    void closeSystemFloatingWindow();
    if (iceRestartTimer.current !== null) {
      window.clearTimeout(iceRestartTimer.current);
      iceRestartTimer.current = null;
    }
    peer.current?.close();
    peer.current = null;
    pendingIce.current = [];
    makingOffer.current = false;
    ignoreOffer.current = false;
    settingRemoteAnswer.current = false;
    videoSender.current = null;
    remoteVideoRecoveryAttempts.current = 0;
    stream.current?.getTracks().forEach((track) => track.stop());
    stream.current = null;
    remoteMedia?.getTracks().forEach((track) => track.stop());
    setLocalMedia(null);
    setRemoteMedia(null);
    setCalling(false);
    setRemoteConnected(false);
    setCamera(false);
    setMute(true);
    setMicLevel(0);
    setCallFullscreen(false);
    setConnectionState("closed");
    setRemotePlaybackBlocked(false);
  };
  const ensurePeer = () => {
    if (peer.current) return peer.current;
    const next = new RTCPeerConnection({ iceServers: iceServersRef.current });
    peer.current = next;
    setConnectionState(next.connectionState);
    next.onconnectionstatechange = () => {
      setConnectionState(next.connectionState);
      if (next.connectionState === "failed" || next.connectionState === "closed") {
        setRemoteConnected(false);
      }
      if (next.connectionState === "failed") {
        next.restartIce();
      }
      if (next.connectionState === "disconnected" && iceRestartTimer.current === null) {
        iceRestartTimer.current = window.setTimeout(() => {
          iceRestartTimer.current = null;
          if (next.connectionState === "disconnected") next.restartIce();
        }, 4000);
      } else if (
        next.connectionState === "connected" &&
        iceRestartTimer.current !== null
      ) {
        window.clearTimeout(iceRestartTimer.current);
        iceRestartTimer.current = null;
      }
    };
    next.onicecandidate = ({ candidate }) => {
      if (candidate) sendEvent({ type: "ice", candidate });
    };
    next.onnegotiationneeded = () => {
      void negotiateCall().catch(() => undefined);
    };
    next.ontrack = ({ streams }) => {
      const incoming = streams[0] ||
        new MediaStream(next.getReceivers().flatMap((receiver) =>
          receiver.track ? [receiver.track] : []
        ));
      setRemoteMedia(incoming);
      setCalling(true);
      setRemoteConnected(true);
    };
    stream.current?.getTracks().forEach((track) => {
      const sender = next.addTrack(track, stream.current!);
      if (track.kind === "video") {
        videoSender.current = sender;
        void constrainVideoSender(sender).catch(() => undefined);
      }
    });
    return next;
  };
  const negotiateCall = async () => {
    if (makingOffer.current) return;
    await waitForSocket();
    const next = ensurePeer();
    if (next.signalingState !== "stable") return;
    makingOffer.current = true;
    try {
      await next.setLocalDescription();
      if (next.localDescription?.type !== "offer") return;
      sendEvent({ type: "offer", sdp: next.localDescription });
      setCalling(true);
    } finally {
      makingOffer.current = false;
    }
  };
  const addLocalMedia = async (constraints: MediaStreamConstraints) => {
    const acquired = await navigator.mediaDevices.getUserMedia(constraints);
    const current = stream.current || new MediaStream();
    const next = ensurePeer();
    let negotiationNeeded = false;
    for (const track of acquired.getTracks()) {
      current.addTrack(track);
      if (track.kind === "video" && videoSender.current) {
        await videoSender.current.replaceTrack(track);
        await constrainVideoSender(videoSender.current).catch(() => undefined);
      } else {
        const sender = next.addTrack(track, current);
        negotiationNeeded = true;
        if (track.kind === "video") {
          videoSender.current = sender;
          await constrainVideoSender(sender).catch(() => undefined);
        }
      }
    }
    stream.current = current;
    setLocalMedia(new MediaStream(current.getTracks()));
    return negotiationNeeded;
  };
  useEffect(() => {
    const hasRemoteVideo = remoteMedia?.getVideoTracks().some((track) =>
      track.readyState === "live"
    );
    if (!calling || !camera || hasRemoteVideo) {
      remoteVideoRecoveryAttempts.current = 0;
      return;
    }
    let timer: number | null = null;
    const retry = () => {
      if (remoteVideoRecoveryAttempts.current >= 6) {
        if (timer !== null) window.clearInterval(timer);
        timer = null;
        return;
      }
      remoteVideoRecoveryAttempts.current += 1;
      sendEvent({ type: "media-refresh" });
    };
    retry();
    timer = window.setInterval(retry, 4000);
    return () => {
      if (timer !== null) window.clearInterval(timer);
    };
  }, [calling, camera, remoteMedia]);
  useEffect(() => {
    if (!localMedia || mute) {
      setMicLevel(0);
      return;
    }
    const audioTrack = localMedia.getAudioTracks()[0];
    if (!audioTrack || audioTrack.readyState !== "live" || !audioTrack.enabled) {
      setMicLevel(0);
      return;
    }
    const AudioContextClass = window.AudioContext ||
      (window as typeof window & { webkitAudioContext?: typeof AudioContext })
        .webkitAudioContext;
    if (!AudioContextClass) return;
    const context = new AudioContextClass();
    const analyser = context.createAnalyser();
    analyser.fftSize = 512;
    analyser.smoothingTimeConstant = .78;
    const source = context.createMediaStreamSource(
      new MediaStream([audioTrack]),
    );
    source.connect(analyser);
    const values = new Uint8Array(analyser.fftSize);
    let smooth = 0;
    const measure = () => {
      analyser.getByteTimeDomainData(values);
      let sum = 0;
      for (const value of values) {
        const normalized = (value - 128) / 128;
        sum += normalized * normalized;
      }
      const rms = Math.sqrt(sum / values.length);
      const target = Math.min(100, Math.max(0, rms * 320));
      smooth = smooth * .72 + target * .28;
      setMicLevel(Math.round(smooth));
    };
    const timer = window.setInterval(measure, 100);
    void context.resume().then(measure);
    return () => {
      window.clearInterval(timer);
      source.disconnect();
      analyser.disconnect();
      void context.close();
      setMicLevel(0);
    };
  }, [localMedia, mute]);
  const loadHome = async () => {
    try {
      const [albumsRes, anniversaryRes, noteRes] = await Promise.all([
        fetch(`${api}/duoCall/album?page=1&pageSize=6`, { headers }),
        fetch(`${api}/duoCall/anniversaries`, { headers }),
        fetch(`${api}/duoCall/notes?latestByMember=true`, { headers }),
      ]);
      const [albumsData, anniversaryData, noteData] = await Promise.all([
        albumsRes.json(),
        anniversaryRes.json(),
        noteRes.json(),
      ]);
      if (albumsData.code === 0) {
        setHomeAlbums(newestAlbums(albumsData.data.items || [], 6));
      }
      if (anniversaryData.code === 0) {
        setAnniversaries(anniversaryData.data || []);
      }
      if (noteData.code === 0) setNotes(noteData.data || []);
    } catch { /* Home data is optional while the API restarts. */ }
  };
  const loadTree = useCallback(async () => {
    try {
      const response = await fetch(`${api}/duoCall/tree`, { headers });
      const payload = await response.json();
      if (payload.code === 0) setTree(payload.data as TreeState);
    } catch { /* Keep the current tree while the API restarts. */ }
  // The authorization header changes only with the Room session token.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);
  const loadAlbumPage = async (page = albumPage) => {
    try {
      const res = await fetch(`${api}/duoCall/album?page=${page}&pageSize=20`, {
        headers,
      });
      const payload = await res.json();
      if (payload.code === 0) {
        setAlbumItems(payload.data.items || []);
        setAlbumTotal(payload.data.total || 0);
        setAlbumPage(page);
      }
    } catch { /* Keep current page visible. */ }
  };
  const loadDaily = async () => {
    try {
      const [todayResponse, historyResponse] = await Promise.all([
        fetch(`${api}/duoCall/daily/today`, { headers }),
        fetch(`${api}/duoCall/daily/history?page=1&pageSize=20`, { headers }),
      ]);
      const [todayPayload, historyPayload] = await Promise.all([
        todayResponse.json(),
        historyResponse.json(),
      ]);
      if (todayPayload.code === 0) {
        const state = todayPayload.data as DailyState;
        setDaily(state);
        const mine = state.replies?.find((reply) => reply.slot === meRef.current);
        if (mine?.content && !state.revealedAt) setDailyDraft(mine.content);
      }
      if (historyPayload.code === 0) {
        setDailyHistory(historyPayload.data?.items || []);
      }
    } catch { /* Keep the previous ritual state while the API restarts. */ }
  };
  useEffect(() => {
    loadHome();
    loadTree();
    loadAlbumPage(1);
    loadDaily();
    fetch(`${api}/duoCall/bootstrap`, { headers }).then((r) => r.json()).then(
      (p) => {
        if (p.code === 0) {
          setMe(p.data?.me || 0);
          setIdentities(p.data?.identities || []);
          setStatuses(p.data?.statuses || []);
          if (Array.isArray(p.data?.iceServers)) {
            iceServersRef.current = p.data.iceServers;
            setIceServers(p.data.iceServers);
          }
        }
      },
    ).catch(() => undefined);
    fetch(`${api}/duoCall/messages?limit=10`, { headers }).then((r) => r.json()).then((p) => {
      const data = p.data;
      const items = Array.isArray(data) ? data : data?.items || [];
      setMessages([...items].reverse());
      setMessagesHasMore(Boolean(data?.hasMore));
    }).catch(() => undefined);
    fetch(`${api}/duoCall/messages/wechat`, { headers }).then((r) => r.json()).then((p) => {
      if (p.code === 0) {
        const online = Boolean(p.data?.partnerOnline);
        partnerOnlineRef.current = online;
        setPartnerOnline(online);
        setChatWechatEnabled(Boolean(p.data?.enabled));
        if (!online && !p.data?.enabled) void ensureChatWechatFallback();
      }
    }).catch(() => undefined);
    fetch(`${api}/duoCall/messages/unread`, { headers }).then((r) => r.json())
      .then((p) => setUnread(p.data?.count || 0)).catch(() => undefined);
    fetch(`${api}/duoCall/miss-you/pending`, { headers }).then((r) => r.json())
      .then((p) => {
        if (p.code === 0 && Array.isArray(p.data)) {
          p.data.forEach((signal: MissYouSignal) => presentMissYou(signal));
        }
      }).catch(() => undefined);
    let disposed = false;
    let reconnectAttempt = 0;
    let reconnectTimer: number | null = null;
    const handleSocketMessage = async (event: MessageEvent) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === "presence" && Number(data.slot) !== meRef.current) {
          const online = Boolean(data.online);
          if (online && !partnerOnlineRef.current) {
            void playPresenceTone();
          }
          partnerOnlineRef.current = online;
          setPartnerOnline(online);
          if (!online) void ensureChatWechatFallback();
        }
        if (data.type === "profile" && data.data?.slot) {
          setIdentities((current) =>
            mergeProfileBySlot(current, data.data as Identity)
          );
        }
        if (data.type === "tree-growth") {
          await loadTree();
        }
        if (data.type === "miss-you" && data.data) {
          presentMissYou(data.data as MissYouSignal);
        }
        if (data.type === "media-refresh") {
          const hasLocalVideo = stream.current?.getVideoTracks().some((track) =>
            track.readyState === "live" && track.enabled
          );
          if (hasLocalVideo) await negotiateCall();
        }
        if (data.type === "chat" && data.message) {
          const isReading = document.visibilityState === "visible" && viewRef.current === "call";
          const scroller = messagesScroller.current;
          const isNearBottom = !scroller ||
            scroller.scrollHeight - scroller.clientHeight - scroller.scrollTop < 72;
          shouldStickMessagesToBottom.current = isReading && isNearBottom;
          setMessages((old) => [...old, data.message]);
          if (isReading) {
            markMessagesRead();
          } else {
            setUnread((count) => count + 1);
            document.title = "💌 新消息 · 爱情小屋";
            showSystemMessageNotification(data.message as Message);
          }
        }
        if (data.type === "note" && data.data) {
          const note = data.data as LoveNote;
          setNotes((current) => [
            note,
            ...current.filter((item) => item.senderSlot !== note.senderSlot),
          ]);
        }
        if (data.type === "album") {
          loadHome();
          loadAlbumPage();
        }
        if (
          data.type === "daily-question" ||
          data.type === "daily-question-updated" ||
          data.type === "daily-reply" ||
          data.type === "daily-reveal"
        ) {
          await loadDaily();
        }
        if (data.type === "offer") {
          if (!stream.current) {
            stream.current = await navigator.mediaDevices.getUserMedia({
              video: false,
              audio: true,
            });
            setLocalMedia(stream.current);
            setCamera(false);
            setMute(false);
          }
        }
        if (data.type === "offer" || data.type === "answer") {
          const next = data.type === "offer" ? ensurePeer() : peer.current;
          if (!next) return;
          const description = data.sdp as RTCSessionDescriptionInit;
          const collision = hasOfferCollision({
            descriptionType: description.type,
            makingOffer: makingOffer.current,
            signalingState: next.signalingState,
            settingRemoteAnswer: settingRemoteAnswer.current,
          });
          ignoreOffer.current = shouldIgnoreOffer(
            meRef.current === 2,
            collision,
          );
          if (ignoreOffer.current) return;
          settingRemoteAnswer.current = description.type === "answer";
          try {
            await next.setRemoteDescription(description);
          } finally {
            settingRemoteAnswer.current = false;
          }
          await flushPendingIce(next);
          if (description.type === "offer") {
            await next.setLocalDescription();
            if (next.localDescription?.type === "answer") {
              sendEvent({ type: "answer", sdp: next.localDescription });
            }
          }
          await Promise.allSettled(
            next.getSenders()
              .filter((sender) => sender.track?.kind === "video")
              .map(constrainVideoSender),
          );
        }
        if (data.type === "ice" && data.candidate) {
          if (ignoreOffer.current) return;
          if (peer.current?.remoteDescription) {
            await peer.current.addIceCandidate(data.candidate);
          } else {
            pendingIce.current.push(data.candidate);
          }
        }
      } catch (error) {
        console.warn("实时消息处理失败", error);
      }
    };
    const connectSocket = () => {
      if (disposed) return;
      const ws = new WebSocket(webSocketUrl(api, location.origin, token));
      socket.current = ws;
      ws.onopen = () => {
        reconnectAttempt = 0;
        setSocketConnected(true);
        if (peer.current && peer.current.connectionState !== "closed") {
          peer.current.restartIce();
          void negotiateCall().catch(() => undefined);
        }
      };
      ws.onclose = () => {
        if (socket.current === ws) socket.current = null;
        setSocketConnected(false);
        if (disposed) return;
        const delay = Math.min(10_000, 1000 * 2 ** reconnectAttempt);
        reconnectAttempt += 1;
        reconnectTimer = window.setTimeout(connectSocket, delay);
      };
      ws.onmessage = handleSocketMessage;
    };
    connectSocket();
    return () => {
      disposed = true;
      if (reconnectTimer !== null) window.clearTimeout(reconnectTimer);
      socket.current?.close();
      socket.current = null;
      setSocketConnected(false);
      setPartnerOnline(false);
      toneContext.current?.close().catch(() => undefined);
      toneContext.current = null;
      closeCall();
    };
    // The room connection is intentionally scoped to the authenticated
    // session. Reconnecting when render-local helpers change would duplicate
    // sockets, peer connections, and initial API requests.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);
  async function toggleCamera() {
    try {
      const videoTracks = stream.current?.getVideoTracks() || [];
      if (videoTracks.length && camera) {
        await videoSender.current?.replaceTrack(null);
        for (const track of videoTracks) {
          track.stop();
          stream.current?.removeTrack(track);
        }
        setLocalMedia(stream.current
          ? new MediaStream(stream.current.getTracks())
          : null);
        setCamera(false);
        return;
      }
      const negotiationNeeded = await addLocalMedia({
        video: CALL_VIDEO_CONSTRAINTS,
        audio: false,
      });
      setCamera(true);
      if (negotiationNeeded) await negotiateCall();
    } catch (error) {
      showNotice(error instanceof Error && error.message.includes("信令")
        ? `${error.message}，请刷新页面后重试`
        : "请允许摄像头权限后重试", "摄像头暂不可用");
    }
  }
  async function send(event: FormEvent) {
    event.preventDefault();
    if (!draft.trim()) return;
    const content = draft.trim();
    setDraft("");
    try {
      const response = await fetch(`${api}/duoCall/messages`, {
        method: "POST",
        headers: { ...headers, "Content-Type": "application/json" },
        body: JSON.stringify({ content }),
      });
      const payload = await response.json();
      if (!response.ok || payload.code !== 0) {
        throw new Error(payload.msg || "消息发送失败");
      }
      shouldStickMessagesToBottom.current = true;
      setMessages((old) => [...old, payload.data]);
      sendEvent({ type: "chat", message: payload.data });
    } catch (error) {
      setDraft(content);
      showNotice(
        error instanceof Error ? error.message : "消息发送失败，请稍后重试",
        "消息发送失败",
      );
    }
  }
  async function uploadChatImage(file: File) {
    const data = new FormData();
    data.append("file", file);
    try {
      const response = await fetch(`${api}/duoCall/messages/image`, {
        method: "POST",
        headers,
        body: data,
      });
      const payload = await readAPIPayload(response, "图片上传失败");
      shouldStickMessagesToBottom.current = true;
      setMessages((old) => [...old, payload.data]);
      sendEvent({ type: "chat", message: payload.data });
    } catch (error) {
      showNotice(
        error instanceof Error ? error.message : "图片上传失败",
        "图片发送失败",
      );
    }
  }
  async function uploadAlbum(file: File) {
    setBusy(true);
    const data = new FormData();
    data.append("file", file);
    try {
      const response = await fetch(`${api}/duoCall/album/upload`, {
        method: "POST",
        headers,
        body: data,
      });
      await readAPIPayload(response, "相册上传失败");
      await Promise.all([loadHome(), loadAlbumPage(1)]);
      sendEvent({ type: "album" });
    } catch (error) {
      showNotice(
        error instanceof Error ? error.message : "上传失败",
        "相册上传失败",
      );
    } finally {
      setBusy(false);
    }
  }
  async function removeAlbum(id: number) {
    const confirmed = await askConfirmation(
      "移除后这张照片将不再出现在你们的共同相册中。",
      {
        title: "移除这张照片？",
        confirmLabel: "确认移除",
        tone: "danger",
      },
    );
    if (!confirmed) return;
    try {
      const response = await fetch(`${api}/duoCall/album?ID=${id}`, {
        method: "DELETE",
        headers,
      });
      const payload = await response.json();
      if (!response.ok || payload.code !== 0) {
        throw new Error(payload.msg || "照片移除失败");
      }
      await Promise.all([loadHome(), loadAlbumPage(albumPage)]);
      sendEvent({ type: "album" });
    } catch (error) {
      showNotice(
        error instanceof Error ? error.message : "照片移除失败",
        "暂时无法移除",
      );
    }
  }
  async function sendNote(event: FormEvent) {
    event.preventDefault();
    if (!noteDraft.trim()) return;
    setBusy(true);
    try {
      const response = await fetch(`${api}/duoCall/notes`, {
        method: "POST",
        headers: { ...headers, "Content-Type": "application/json" },
        body: JSON.stringify({ content: noteDraft }),
      });
      const payload = await response.json();
      if (payload.code !== 0) throw new Error(payload.msg || "留言保存失败");
      setNotes((current) => [
        payload.data,
        ...current.filter((item) =>
          item.senderSlot !== payload.data.senderSlot
        ),
      ]);
      setNoteDraft("");
      setNoteOpen(false);
    } catch (error) {
      showNotice(
        error instanceof Error ? error.message : "留言保存失败",
        "留言保存失败",
      );
    } finally {
      setBusy(false);
    }
  }
  async function sendMissYou(): Promise<{ wechatQueued: boolean }> {
    const response = await fetch(`${api}/duoCall/miss-you`, {
      method: "POST",
      headers: { ...headers, "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });
    const payload = await response.json();
    if (!response.ok || payload.code !== 0) {
      throw new Error(payload.msg || "想念发送失败");
    }
    return { wechatQueued: Boolean(payload.data?.wechatQueued) };
  }
  async function submitDailyReply(event: FormEvent) {
    event.preventDefault();
    if (!daily || !dailyDraft.trim() || daily.revealedAt) return;
    setDailyBusy(true);
    try {
      const response = await fetch(`${api}/duoCall/daily/reply`, {
        method: "POST",
        headers: { ...headers, "Content-Type": "application/json" },
        body: JSON.stringify({
          questionId: daily.ID,
          content: dailyDraft.trim(),
        }),
      });
      const payload = await response.json();
      if (!response.ok || payload.code !== 0) {
        throw new Error(payload.msg || "回信保存失败");
      }
      setDaily(payload.data);
      if (payload.data.revealedAt) {
        setDailyDraft("");
        await loadDaily();
      }
    } catch (error) {
      showNotice(
        error instanceof Error ? error.message : "回信保存失败",
        "回信保存失败",
      );
    } finally {
      setDailyBusy(false);
    }
  }
  async function toggleMute() {
    try {
      const audioTracks = stream.current?.getAudioTracks() || [];
      if (audioTracks.length) {
        const nextMuted = !mute;
        audioTracks.forEach((track) => {
          track.enabled = !nextMuted;
        });
        setMute(nextMuted);
        return;
      }
      const negotiationNeeded = await addLocalMedia({ video: false, audio: true });
      setMute(false);
      if (negotiationNeeded) await negotiateCall();
    } catch (error) {
      showNotice(error instanceof Error && error.message.includes("信令")
        ? `${error.message}，请刷新页面后重试`
        : "请允许麦克风权限后重试", "麦克风暂不可用");
    }
  }
  const registerRemoteVideo = useCallback((
    element: HTMLVideoElement,
    mounted: boolean,
  ) => {
    if (mounted) remoteVideos.current.add(element);
    else remoteVideos.current.delete(element);
  }, []);
  const resumeRemoteAudio = useCallback(async () => {
    const results = await Promise.allSettled(
      [...remoteVideos.current].map((video) => {
        video.muted = false;
        return video.play();
      }),
    );
    setRemotePlaybackBlocked(
      results.some((result) => result.status === "rejected"),
    );
  }, []);
  const openSystemPictureInPicture = useCallback(async () => {
    if (systemPictureInPictureOpening.current) return;
    systemPictureInPictureOpening.current = true;
    try {
      if (systemPictureInPicture === "tauri-window") {
        await closeSystemFloatingWindow();
        return;
      }
      const candidates = [...remoteVideos.current].filter((candidate) => {
        const media = candidate.srcObject;
        return candidate.isConnected &&
          media instanceof MediaStream &&
          media.getVideoTracks().some((track) => track.readyState === "live");
      });
      const video = candidates.find((candidate) =>
        candidate.readyState >= HTMLMediaElement.HAVE_METADATA &&
        candidate.videoWidth > 0 &&
        candidate.videoHeight > 0
      ) || candidates[0];
      if (!video) {
        showNotice("收到对方视频后才能开启系统悬浮窗。", "暂时无法悬浮");
        return;
      }
      const session = await enterSystemPictureInPicture(video);
      exitSystemFloatingWindow.current = session.exit || null;
      if (session.mode !== "video") {
        setView("call");
        setCallFullscreen(false);
        setSystemPictureInPicture(session.mode);
      }
    } catch (error) {
      setSystemPictureInPicture(null);
      showNotice(
        error instanceof Error ? error.message : "系统视频悬浮窗开启失败",
        "悬浮窗开启失败",
      );
    } finally {
      systemPictureInPictureOpening.current = false;
    }
  }, [
    closeSystemFloatingWindow,
    showNotice,
    systemPictureInPicture,
  ]);
  useEffect(() => {
    let disposed = false;
    let listener: { remove: () => Promise<void> } | null = null;
    void listenForNativePictureInPicture((active) => {
      if (!disposed) {
        setSystemPictureInPicture(active ? "android" : null);
      }
    }).then((handle) => {
      if (disposed) {
        void handle?.remove();
      } else {
        listener = handle;
      }
    });
    return () => {
      disposed = true;
      void listener?.remove();
      void exitSystemFloatingWindow.current?.().catch(() => undefined);
      exitSystemFloatingWindow.current = null;
    };
  }, []);
  const openCallFullscreen = () => {
    setView("call");
    setCallFullscreen(true);
  };
  const toggleChatHistory = useCallback(() => {
    setChatHistoryVisible((visible) => !visible);
  }, []);
  const logout = async () => {
    const confirmed = await askConfirmation(
      "当前连线会同时结束，并清除这台设备上的登录状态。",
      {
        title: "退出爱情小屋？",
        confirmLabel: "确认退出",
        tone: "danger",
      },
    );
    if (!confirmed) return;
    closeCall();
    socket.current?.close();
    leave();
  };
  const saveProfile = async (
    displayName: string,
    statusId: number | null,
  ) => {
    const response = await fetch(`${api}/duoCall/profile`, {
      method: "PUT",
      headers: { ...headers, "Content-Type": "application/json" },
      body: JSON.stringify({ displayName, statusId }),
    });
    const payload = await response.json();
    if (payload.code !== 0) throw new Error(payload.msg || "保存资料失败");
    const identity = payload.data as Identity;
    setIdentities((current) => mergeProfileBySlot(current, identity));
    return identity;
  };
  const uploadAvatar = async (file: File) => {
    const form = new FormData();
    form.append("file", file);
    const response = await fetch(`${api}/duoCall/profile/avatar`, {
      method: "POST",
      headers,
      body: form,
    });
    const payload = await readAPIPayload(response, "上传头像失败");
    const identity = payload.data as Identity;
    setIdentities((current) => mergeProfileBySlot(current, identity));
    return identity;
  };
  const pages = Math.max(1, Math.ceil(albumTotal / 20));
  return (
    <div className={`cottage-shell ${
      view === "call" ? "is-call-view" : ""
    } ${systemPictureInPicture ? "is-system-floating" : ""}`}>
      <ThemeDecorations theme={theme} />
      <aside className="cottage-nav">
        <div className="nav-logo">
          <Icon icon="solar:heart-bold-duotone" />
          <span>
            Love Cottage<small>爱情小屋</small>
          </span>
        </div>
        <nav>
          <button
            className={view === "home" ? "active" : ""}
            onClick={() => setView("home")}
          >
            <Icon icon="solar:home-2-bold-duotone" />首页
          </button>
          <button
            className={view === "daily" ? "active" : ""}
            onClick={() => setView("daily")}
          >
            <Icon icon="solar:letter-bold-duotone" />回信
          </button>
          <button
            className={view === "call" ? "active" : ""}
            onClick={() => setView("call")}
          >
            <Icon icon="solar:phone-calling-rounded-bold-duotone" />连线
          </button>
          <button className={view === "album" ? "active" : ""} onClick={() => setView("album")}>
            <Icon icon="solar:gallery-wide-bold-duotone" />相册
          </button>
          <button className={view === "settings" ? "active" : ""} onClick={() => setView("settings")}>
            <Icon icon="solar:settings-bold-duotone" />设置
          </button>
        </nav>
        <div className="nav-bottom">
          <ThemePicker theme={theme} setTheme={setTheme} compact />
          <button className="logout-button" onClick={logout} title="离开小屋">
            <Icon icon="solar:logout-2-bold" />
            <span>离开</span>
          </button>
        </div>
      </aside>
      {view === "home"
        ? (
          <HomePanel
            albums={homeAlbums}
            anniversaries={anniversaries}
            notes={notes}
            openNote={() => setNoteOpen(true)}
            sendMissYou={sendMissYou}
            daily={daily}
            me={me}
            openDaily={() => setView("daily")}
            openView={setView}
            identities={identities}
            partnerOnline={partnerOnline}
            tree={tree}
          />
        )
        : view === "daily"
        ? (
          <DailyPanel
            state={daily}
            history={dailyHistory}
            me={me}
            draft={dailyDraft}
            busy={dailyBusy}
            setDraft={setDailyDraft}
            submit={submitDailyReply}
            refresh={loadDaily}
          />
        )
        : view === "album"
        ? (
          <AlbumPanel
            albums={albumItems}
            page={albumPage}
            pages={pages}
            total={albumTotal}
            uploading={busy}
            uploadInput={albumInput}
            onUpload={uploadAlbum}
            onDelete={removeAlbum}
            onPage={loadAlbumPage}
            identities={identities}
            me={me}
          />
        )
        : view === "settings"
        ? (
          <SettingsPanel
            theme={theme}
            preferences={preferences}
            setTheme={setTheme}
            setPreferences={setPreferences}
            identity={identities.find((identity) => identity.slot === me)}
            statuses={statuses}
            saveProfile={saveProfile}
            uploadAvatar={uploadAvatar}
            leave={logout}
            notify={showNotice}
          />
        )
        : (
          <main className="room">
            <header>
              <div className="brand">
                <Icon icon="solar:phone-calling-rounded-bold-duotone" />
                <b>今天，也要好好见面</b>
                <em>{calling ? "连线中" : partnerOnline ? "TA 已在线" : "准备好了吗"}</em>
              </div>
              {partnerOnline && notificationPermission !== "granted" && (
                <div className={`notification-permission permission-${notificationPermission}`}>
                  <button type="button" onClick={() => void enableSystemNotifications()}>
                    <Icon icon={notificationPermission === "denied"
                      ? "solar:bell-bing-bold-duotone"
                      : "solar:bell-bold-duotone"} />
                    {notificationPermission === "denied" ? "系统通知被阻止" : "开启系统通知"}
                  </button>
                  {notificationGuideOpen && (
                    <p>
                      {notificationPermission === "unsupported"
                        ? "当前浏览器不支持系统通知，请保持页面打开。"
                        : "请点击地址栏左侧的网站设置，将“通知”改为“允许”，然后刷新页面。"}
                    </p>
                  )}
                </div>
              )}
            </header>
            <div className="room-grid">
              <CallStage
                localMedia={callFullscreen ? null : localMedia}
                remoteMedia={callFullscreen ? null : remoteMedia}
                camera={camera}
                mute={mute}
                micLevel={micLevel}
                calling={calling}
                remoteConnected={remoteConnected}
                connectionState={connectionState}
                remotePlaybackBlocked={remotePlaybackBlocked}
                onMute={toggleMute}
                onCamera={toggleCamera}
                onPictureInPicture={() => void openSystemPictureInPicture()}
                onFullscreen={() => setCallFullscreen(true)}
                onBackgroundActivate={toggleChatHistory}
                systemFloating={systemPictureInPicture !== null}
                onExitSystemFloating={systemPictureInPicture === "tauri-window"
                  ? () => void closeSystemFloatingWindow()
                  : undefined}
                onResumeAudio={resumeRemoteAudio}
                onPlaybackBlocked={setRemotePlaybackBlocked}
                registerRemoteVideo={registerRemoteVideo}
                remoteMuted={callFullscreen}
              />
              <section
                className={`chat immersive-chat ${
                  chatHistoryVisible ? "" : "is-history-hidden"
                }`}
              >
                <div className="chat-title">
                  <span>
                    悄悄话 {unread ? <b className="badge">{unread}</b> : null}
                  </span>
                  <div className="chat-status">
                    <small>
                      <i className={socketConnected ? "online" : ""} />
                      {socketConnected ? "实时在线" : "正在连接"}
                    </small>
                    <small className="message-route-label">
                      <Icon icon={partnerOnline ? "solar:bell-bold" : "solar:chat-round-dots-bold"} />
                      {partnerOnline
                        ? notificationPermission === "granted" ? "系统通知" : "等待通知权限"
                        : chatWechatEnabled ? "离线微信兜底" : "正在启用微信兜底"}
                    </small>
                  </div>
                </div>
                <div
                  className="messages"
                  ref={messagesScroller}
                  onScroll={onMessagesScroll}
                  onClick={(event) => {
                    if (event.target === event.currentTarget) {
                      toggleChatHistory();
                    }
                  }}
                >
                  {loadingOlderMessages && <small className="chat-history-loading">正在加载更早消息…</small>}
                  {messages.length
                    ? messages.map((message, index) => <Fragment key={message.ID}>
                      {shouldShowMessageTime(messages[index - 1], message) && <div className="chat-time-divider">{messageTimeLabel(message)}</div>}
                      <ChatMessage
                        message={message}
                        me={me}
                        identities={identities}
                        onImageLoad={() => {
                          if (shouldStickMessagesToBottom.current) scrollMessagesToBottom("auto");
                        }}
                      />
                    </Fragment>)
                    : <p className="empty">发送第一条小消息吧 ✨</p>}
                  <div
                    ref={messagesEnd}
                    className="messages-end"
                    aria-hidden="true"
                  />
                </div>
                <form className="composer" onSubmit={send}>
                  <MobileCallMenu
                    camera={camera}
                    mute={mute}
                    micLevel={micLevel}
                    calling={calling}
                    onMute={toggleMute}
                    onCamera={toggleCamera}
                    onPictureInPicture={() => void openSystemPictureInPicture()}
                    onFullscreen={() => setCallFullscreen(true)}
                  />
                  <div className="emoji-control">
                    <button
                      type="button"
                      className={emojiOpen ? "active" : ""}
                      onClick={() => setEmojiOpen((open) => !open)}
                      aria-label="选择表情"
                    >
                      😊
                    </button>
                    {emojiOpen && (
                      <div
                        className="emoji-picker"
                        role="dialog"
                        aria-label="表情选择"
                      >
                        {emojis.map((emoji) => (
                          <button
                            key={emoji}
                            type="button"
                            onClick={() => {
                              setDraft((value) => value + emoji);
                              setEmojiOpen(false);
                            }}
                          >
                            {emoji}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                  <button
                    type="button"
                    onClick={() => chatImageInput.current?.click()}
                  >
                    <Icon icon="solar:gallery-add-bold" />
                  </button>
                  <input
                    ref={chatImageInput}
                    hidden
                    type="file"
                    accept="image/*"
                    onChange={(e) => {
                      const file = e.target.files?.[0];
                      if (file) uploadChatImage(file);
                      e.target.value = "";
                    }}
                  />
                  <input
                    value={draft}
                    onChange={(e) => setDraft(e.target.value)}
                    placeholder="说点什么…"
                  />
                  <button type="submit" className="send">
                    <Icon icon="solar:plain-2-bold" />
                  </button>
                </form>
              </section>
            </div>
          </main>
      )}
      {calling && view !== "call" && (
        <DraggableSurface
          className="floating-call"
          fixed
          onActivate={openCallFullscreen}
        >
          {remoteMedia
            ? (
              <MediaVideo
                stream={remoteMedia}
                muted={false}
                onPlaybackBlocked={setRemotePlaybackBlocked}
                register={registerRemoteVideo}
              />
            )
            : (
              <div className="floating-call-placeholder">
                <Icon icon={mute ? "solar:heart-angle-bold-duotone" : "solar:microphone-bold"} />
                <small>{mute ? "等待对方加入…" : "语音连线中"}</small>
              </div>
            )}
          <span><i className={remoteConnected ? "online" : ""} />{remoteConnected ? "连线中" : "等待连接"} · 点击返回</span>
        </DraggableSurface>
      )}
      {callFullscreen && (
        <FullscreenCall
          localMedia={localMedia}
          remoteMedia={remoteMedia}
          camera={camera}
          mute={mute}
          micLevel={micLevel}
          calling={calling}
          connectionState={connectionState}
          remotePlaybackBlocked={remotePlaybackBlocked}
          onMute={toggleMute}
          onCamera={toggleCamera}
          onPictureInPicture={() => void openSystemPictureInPicture()}
          onExit={() => setCallFullscreen(false)}
          onResumeAudio={resumeRemoteAudio}
          onPlaybackBlocked={setRemotePlaybackBlocked}
          registerRemoteVideo={registerRemoteVideo}
        />
      )}
      <NoteModal
        open={noteOpen}
        draft={noteDraft}
        busy={busy}
        setDraft={setNoteDraft}
        close={() => setNoteOpen(false)}
        submit={sendNote}
      />
      {dialog && (
        <AppDialog
          {...dialog}
          onConfirm={() => dismissDialog(true)}
          onCancel={() => dismissDialog(false)}
        />
      )}
    </div>
  );
}
