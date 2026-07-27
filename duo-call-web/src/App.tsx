import { Icon } from "@iconify/react";
import { FormEvent, useEffect, useRef, useState } from "react";

type Theme = "blue" | "pink" | "dark";
type Message = {
  ID: number;
  senderSlot: number;
  kind: "text" | "image";
  content: string;
  imageUrl: string;
  readAt?: string;
};
type AlbumItem = {
  ID: number;
  uploaderSlot: number;
  imageUrl: string;
  uploadedAt: string;
};
type Anniversary = {
  ID: number;
  title: string;
  date: string;
  enabled: boolean;
  sort: number;
};
type LoveNote = {
  ID: number;
  senderSlot: number;
  content: string;
  CreatedAt: string;
};

const themes: { id: Theme; label: string; icon: string }[] = [
  { id: "blue", label: "晴空蓝", icon: "solar:cloud-sun-2-bold-duotone" },
  { id: "pink", label: "心动粉", icon: "solar:heart-bold-duotone" },
  { id: "dark", label: "晚安黑", icon: "solar:moon-stars-bold-duotone" },
];
const themeDecorations: Record<Theme, string[]> = {
  blue: [
    "solar:gamepad-bold-duotone",
    "solar:headphones-round-sound-bold-duotone",
    "solar:cup-star-bold-duotone",
    "solar:rocket-2-bold-duotone",
    "solar:monitor-smartphone-bold-duotone",
    "solar:ghost-smile-bold-duotone",
  ],
  pink: [
    "ph:heart-fill",
    "ph:unicorn-fill",
    "ph:cat-fill",
    "ph:flower-lotus-fill",
    "ph:star-four-fill",
    "ph:butterfly-fill",
  ],
  dark: [
    "solar:moon-stars-bold-duotone",
    "solar:cloud-moon-bold-duotone",
    "solar:stars-bold-duotone",
    "solar:lamp-bold-duotone",
    "solar:planet-3-bold-duotone",
    "solar:fire-bold-duotone",
  ],
};
const api = import.meta.env.VITE_DUO_API_URL || "/api";
const emojis = [
  "😀",
  "😃",
  "😄",
  "😁",
  "😂",
  "🥰",
  "😍",
  "😘",
  "😊",
  "🥹",
  "😎",
  "🤔",
  "😴",
  "😭",
  "😤",
  "😡",
  "🤗",
  "🤭",
  "🫣",
  "🙄",
  "👍",
  "👎",
  "👏",
  "🙌",
  "🤝",
  "🙏",
  "💪",
  "✌️",
  "🤟",
  "🫶",
  "❤️",
  "🩷",
  "🧡",
  "💛",
  "💚",
  "🩵",
  "💙",
  "💜",
  "🤍",
  "💔",
  "🌹",
  "🌸",
  "🌈",
  "⭐",
  "✨",
  "🔥",
  "🎉",
  "🎁",
  "🍰",
  "☕",
];

export function App() {
  const [theme, setTheme] = useState<Theme>(() =>
    (localStorage.getItem("duo-theme") as Theme) || "blue"
  );
  const [token, setToken] = useState(() =>
    localStorage.getItem("duo-session") || ""
  );
  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem("duo-theme", theme);
  }, [theme]);
  return token
    ? (
      <Room
        theme={theme}
        setTheme={setTheme}
        token={token}
        leave={() => {
          localStorage.removeItem("duo-session");
          setToken("");
        }}
      />
    )
    : <Login theme={theme} setTheme={setTheme} onLogin={setToken} />;
}

function Login(
  { theme, setTheme, onLogin }: {
    theme: Theme;
    setTheme: (value: Theme) => void;
    onLogin: (token: string) => void;
  },
) {
  const [key, setKey] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!key.trim()) return setError("请输入只属于你的小秘钥");
    setLoading(true);
    setError("");
    try {
      const response = await fetch(`${api}/duoCall/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ key: key.trim() }),
      });
      const payload = await response.json();
      if (!response.ok || payload.code !== 0) {
        throw new Error(payload.msg || "秘钥不正确");
      }
      localStorage.setItem("duo-session", payload.data.token);
      onLogin(payload.data.token);
    } catch (reason) {
      setError(
        reason instanceof Error ? reason.message : "暂时无法连接，请稍后再试",
      );
    } finally {
      setLoading(false);
    }
  }
  return (
    <main className="login-shell">
      <ThemeDecorations theme={theme} />
      <div className="login-layout">
        <section className="login-story" aria-label="Love Cottage introduction">
          <div className="story-brand">
            <Icon icon="solar:heart-bold-duotone" />Love Cottage
          </div>
          <p className="story-kicker">ONLY FOR TWO</p>
          <h2>
            把平常的日子，<br />慢慢写成我们的故事。
          </h2>
          <p>在游戏、晚安和每一次想念之间，留一盏只为彼此亮着的灯。</p>
          <div className="story-tags">
            <span>
              <Icon icon="solar:lock-keyhole-minimalistic-bold" />只属于两个人
            </span>
            <span>
              <Icon icon="solar:heart-bold" />每一次心动都被记得
            </span>
          </div>
          <div className="story-meadow" aria-hidden="true">
            <i className="meadow-sun" />
            <i className="meadow-hill hill-one" />
            <i className="meadow-hill hill-two" />
            <Icon className="meadow-heart" icon="solar:heart-bold-duotone" />
          </div>
        </section>
        <section className="login-card" aria-labelledby="title">
          <p className="eyebrow">WELCOME BACK</p>
          <h1 id="title">回到我们的空间</h1>
          <h2>Love Cottage · 爱情小屋</h2>
          <p className="subtitle">输入秘钥，继续属于我们的小小日常。</p>
          <form onSubmit={submit}>
            <label htmlFor="pair-key">进入小屋的秘钥</label>
            <div className="key-input">
              <Icon icon="solar:key-minimalistic-bold" />
              <input
                id="pair-key"
                value={key}
                onChange={(e) => setKey(e.target.value)}
                placeholder="输入只属于你的秘钥"
                autoComplete="current-password"
              />
            </div>
            {error && (
              <p className="error">
                <Icon icon="solar:danger-triangle-bold" />
                {error}
              </p>
            )}
            <button className="enter" disabled={loading} type="submit">
              {loading ? "正在推开小门…" : (
                <>
                  <span>进入爱情小屋</span>
                  <Icon icon="solar:arrow-right-bold" />
                </>
              )}
            </button>
          </form>
          <ThemePicker theme={theme} setTheme={setTheme} />
        </section>
      </div>
    </main>
  );
}

function ThemeDecorations({ theme }: { theme: Theme }) {
  return (
    <div
      className={`theme-decoration theme-decoration-${theme}`}
      aria-hidden="true"
    >
      <div className="theme-decoration-sparkles">
        {themeDecorations[theme].map((icon, index) => (
          <Icon
            icon={icon}
            key={icon}
            className={`theme-decoration-icon icon-${index + 1}`}
          />
        ))}
      </div>
    </div>
  );
}
function ThemePicker(
  { theme, setTheme, compact = false }: {
    theme: Theme;
    setTheme: (value: Theme) => void;
    compact?: boolean;
  },
) {
  return (
    <div
      className={`theme-picker${compact ? " theme-picker-compact" : ""}`}
      aria-label="选择主题色"
    >
      {themes.map((item) => (
        <button
          key={item.id}
          className={theme === item.id ? "active" : ""}
          type="button"
          onClick={() => setTheme(item.id)}
          title={item.label}
        >
          <Icon icon={item.icon} />
        </button>
      ))}
    </div>
  );
}

function Room(
  { token, theme, setTheme, leave }: {
    token: string;
    theme: Theme;
    setTheme: (value: Theme) => void;
    leave: () => void;
  },
) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [draft, setDraft] = useState("");
  const [me, setMe] = useState(0);
  const [emojiOpen, setEmojiOpen] = useState(false);
  const [primary, setPrimary] = useState<"local" | "remote">("remote");
  const [camera, setCamera] = useState(false);
  const [mute, setMute] = useState(false);
  const [unread, setUnread] = useState(0);
  const [notificationsEnabled, setNotificationsEnabled] = useState(() =>
    typeof Notification !== "undefined" &&
    Notification.permission === "granted" &&
    localStorage.getItem("duo-notifications") === "enabled"
  );
  const [calling, setCalling] = useState(false);
  const [iceServers, setIceServers] = useState<RTCIceServer[]>(() => {
    try {
      return JSON.parse(import.meta.env.VITE_DUO_ICE_SERVERS || "[]");
    } catch {
      return [];
    }
  });
  const [view, setView] = useState<"home" | "call" | "album">("home");
  const [homeAlbums, setHomeAlbums] = useState<AlbumItem[]>([]);
  const [albumItems, setAlbumItems] = useState<AlbumItem[]>([]);
  const [albumTotal, setAlbumTotal] = useState(0);
  const [albumPage, setAlbumPage] = useState(1);
  const [anniversaries, setAnniversaries] = useState<Anniversary[]>([]);
  const [notes, setNotes] = useState<LoveNote[]>([]);
  const [noteOpen, setNoteOpen] = useState(false);
  const [noteDraft, setNoteDraft] = useState("");
  const [busy, setBusy] = useState(false);
  const local = useRef<HTMLVideoElement>(null);
  const remote = useRef<HTMLVideoElement>(null);
  const socket = useRef<WebSocket | null>(null);
  const peer = useRef<RTCPeerConnection | null>(null);
  const stream = useRef<MediaStream | null>(null);
  const pendingIce = useRef<RTCIceCandidateInit[]>([]);
  const iceServersRef = useRef<RTCIceServer[]>(iceServers);
  const meRef = useRef(0);
  const viewRef = useRef<"home" | "call" | "album">("home");
  const messagesEnd = useRef<HTMLDivElement>(null);
  const chatImageInput = useRef<HTMLInputElement>(null);
  const albumInput = useRef<HTMLInputElement>(null);
  const headers = { Authorization: `Bearer ${token}` };
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
    if (view === "call") scrollMessagesToBottom();
  }, [messages, view]);
  useEffect(() => {
    meRef.current = me;
  }, [me]);
  useEffect(() => {
    viewRef.current = view;
  }, [view]);
  useEffect(() => {
    iceServersRef.current = iceServers;
  }, [iceServers]);
  const markMessagesRead = () => {
    setUnread(0);
    document.title = "Love Cottage · 爱情小屋";
    fetch(`${api}/duoCall/messages/read`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
    }).catch(() => undefined);
  };
  const enableNotifications = async () => {
    if (typeof Notification === "undefined") {
      alert(
        "当前浏览器不支持系统通知，请使用支持通知的浏览器或将网页添加到主屏幕。",
      );
      return;
    }
    const permission = await Notification.requestPermission();
    const enabled = permission === "granted";
    setNotificationsEnabled(enabled);
    if (enabled) {
      localStorage.setItem("duo-notifications", "enabled");
      new Notification("爱情小屋", { body: "消息通知已开启 💌" });
    } else {
      localStorage.removeItem("duo-notifications");
      alert("通知权限未开启，请在浏览器或系统设置中允许本站发送通知。");
    }
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
  }, [view, token]);
  const closeCall = () => {
    peer.current?.close();
    peer.current = null;
    pendingIce.current = [];
    stream.current?.getTracks().forEach((track) => track.stop());
    stream.current = null;
    if (local.current) local.current.srcObject = null;
    if (remote.current) remote.current.srcObject = null;
    setCalling(false);
    setCamera(false);
  };
  const ensurePeer = () => {
    if (peer.current) return peer.current;
    const next = new RTCPeerConnection({ iceServers: iceServersRef.current });
    peer.current = next;
    next.onicecandidate = ({ candidate }) => {
      if (candidate) sendEvent({ type: "ice", candidate });
    };
    next.ontrack = ({ streams }) => {
      if (remote.current) remote.current.srcObject = streams[0];
      setCalling(true);
    };
    stream.current?.getTracks().forEach((track) =>
      next.addTrack(track, stream.current!)
    );
    return next;
  };
  const loadHome = async () => {
    try {
      const [albumsRes, anniversaryRes, noteRes] = await Promise.all([
        fetch(`${api}/duoCall/album?page=1&pageSize=10`, { headers }),
        fetch(`${api}/duoCall/anniversaries`, { headers }),
        fetch(`${api}/duoCall/notes?limit=1`, { headers }),
      ]);
      const [albumsData, anniversaryData, noteData] = await Promise.all([
        albumsRes.json(),
        anniversaryRes.json(),
        noteRes.json(),
      ]);
      if (albumsData.code === 0) setHomeAlbums(albumsData.data.items || []);
      if (anniversaryData.code === 0) {
        setAnniversaries(anniversaryData.data || []);
      }
      if (noteData.code === 0) setNotes(noteData.data || []);
    } catch { /* Home data is optional while the API restarts. */ }
  };
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
  useEffect(() => {
    loadHome();
    loadAlbumPage(1);
    fetch(`${api}/duoCall/bootstrap`, { headers }).then((r) => r.json()).then(
      (p) => {
        if (p.code === 0) {
          setMe(p.data?.me || 0);
          if (Array.isArray(p.data?.iceServers)) {
            iceServersRef.current = p.data.iceServers;
            setIceServers(p.data.iceServers);
          }
        }
      },
    ).catch(() => undefined);
    fetch(`${api}/duoCall/messages`, { headers }).then((r) => r.json()).then((
      p,
    ) => setMessages((p.data || []).reverse())).catch(() => undefined);
    fetch(`${api}/duoCall/messages/unread`, { headers }).then((r) => r.json())
      .then((p) => setUnread(p.data?.count || 0)).catch(() => undefined);
    const wsURL = `${
      location.protocol === "https:" ? "wss" : "ws"
    }://${location.host}${
      api.replace(/^https?:\/\/[^/]+/, "")
    }/duoCall/ws?token=${encodeURIComponent(token)}`;
    const ws = new WebSocket(wsURL);
    socket.current = ws;
    ws.onmessage = async (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === "chat" && data.message) {
          setMessages((old) => [...old, data.message]);
          const isReading = document.visibilityState === "visible" &&
            viewRef.current === "call";
          if (isReading) {
            markMessagesRead();
          } else {
            setUnread((count) => count + 1);
            document.title = "💌 新消息 · 爱情小屋";
            if (
              typeof Notification !== "undefined" &&
              Notification.permission === "granted" &&
              localStorage.getItem("duo-notifications") === "enabled"
            ) {
              new Notification("爱情小屋的新消息", {
                body: data.message.kind === "image"
                  ? "TA 发来了一张图片"
                  : data.message.content,
                tag: "duo-call-message",
              });
            }
          }
        }
        if (data.type === "note" && data.note) setNotes([data.note]);
        if (data.type === "album") {
          loadHome();
          loadAlbumPage();
        }
        if (data.type === "offer") {
          if (!stream.current) {
            stream.current = await navigator.mediaDevices.getUserMedia({
              video: true,
              audio: true,
            });
            if (local.current) local.current.srcObject = stream.current;
            setCamera(true);
          }
          const next = ensurePeer();
          await next.setRemoteDescription(data.sdp);
          await flushPendingIce(next);
          const answer = await next.createAnswer();
          await next.setLocalDescription(answer);
          sendEvent({ type: "answer", sdp: answer });
        }
        if (data.type === "answer" && peer.current) {
          await peer.current.setRemoteDescription(data.sdp);
          await flushPendingIce(peer.current);
        }
        if (data.type === "ice" && data.candidate) {
          if (peer.current?.remoteDescription) {
            await peer.current.addIceCandidate(data.candidate);
          } else {
            pendingIce.current.push(data.candidate);
          }
        }
      } catch { /* Ignore malformed peer messages. */ }
    };
    return () => {
      ws.close();
      closeCall();
    };
  }, [token]);
  async function toggleCamera() {
    if (camera) {
      closeCall();
      return;
    }
    try {
      const nextStream = await navigator.mediaDevices.getUserMedia({
        video: true,
        audio: true,
      });
      stream.current = nextStream;
      if (local.current) local.current.srcObject = nextStream;
      setCamera(true);
      await waitForSocket();
      const next = ensurePeer();
      const offer = await next.createOffer();
      await next.setLocalDescription(offer);
      sendEvent({ type: "offer", sdp: offer });
      setCalling(true);
    } catch (error) {
      closeCall();
      alert(error instanceof Error && error.message.includes("信令")
        ? `${error.message}，请刷新页面后重试`
        : "请允许摄像头和麦克风权限后重试");
    }
  }
  async function send(event: FormEvent) {
    event.preventDefault();
    if (!draft.trim()) return;
    const response = await fetch(`${api}/duoCall/messages`, {
      method: "POST",
      headers: { ...headers, "Content-Type": "application/json" },
      body: JSON.stringify({ content: draft }),
    });
    const payload = await response.json();
    if (payload.code === 0) {
      setMessages((old) => [...old, payload.data]);
      sendEvent({ type: "chat", message: payload.data });
      setDraft("");
    }
  }
  async function uploadChatImage(file: File) {
    const data = new FormData();
    data.append("file", file);
    const response = await fetch(`${api}/duoCall/messages/image`, {
      method: "POST",
      headers,
      body: data,
    });
    const payload = await response.json();
    if (payload.code === 0) {
      setMessages((old) => [...old, payload.data]);
      sendEvent({ type: "chat", message: payload.data });
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
      const payload = await response.json();
      if (payload.code !== 0) throw new Error(payload.msg || "上传失败");
      await Promise.all([loadHome(), loadAlbumPage(1)]);
      sendEvent({ type: "album" });
    } catch (error) {
      alert(error instanceof Error ? error.message : "上传失败");
    } finally {
      setBusy(false);
    }
  }
  async function removeAlbum(id: number) {
    if (!confirm("要从我们的相册里移除这张照片吗？")) return;
    const response = await fetch(`${api}/duoCall/album?ID=${id}`, {
      method: "DELETE",
      headers,
    });
    const payload = await response.json();
    if (payload.code === 0) {
      await Promise.all([loadHome(), loadAlbumPage(albumPage)]);
      sendEvent({ type: "album" });
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
      setNotes([payload.data]);
      sendEvent({ type: "note", note: payload.data });
      setNoteDraft("");
      setNoteOpen(false);
    } catch (error) {
      alert(error instanceof Error ? error.message : "留言保存失败");
    } finally {
      setBusy(false);
    }
  }
  function toggleMute() {
    stream.current?.getAudioTracks().forEach((track) => {
      track.enabled = mute;
    });
    setMute(!mute);
  }
  const selectVideo = (kind: "local" | "remote") => {
    setPrimary((current) =>
      current === kind ? (kind === "local" ? "remote" : "local") : kind
    );
  };
  const pages = Math.max(1, Math.ceil(albumTotal / 20));
  return (
    <div className="cottage-shell">
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
            className={view === "call" ? "active" : ""}
            onClick={() => setView("call")}
          >
            <Icon icon="solar:videocamera-record-bold-duotone" />连线
          </button>
          <button
            className={view === "album" ? "active" : ""}
            onClick={() => setView("album")}
          >
            <Icon icon="solar:gallery-wide-bold-duotone" />相册
          </button>
        </nav>
        <div className="nav-bottom">
          <ThemePicker theme={theme} setTheme={setTheme} compact />
          <button className="logout-button" onClick={leave} title="离开小屋">
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
            note={notes[0]}
            goCall={() => setView("call")}
            goAlbum={() => setView("album")}
            openNote={() => setNoteOpen(true)}
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
          />
        )
        : (
          <main className="room">
            <header>
              <div className="brand">
                <b>今晚，也要好好见面</b>
                <em>{calling ? "连线中" : "准备好了吗"}</em>
              </div>
            </header>
            <div className="room-grid">
              <section className={`call-stage primary-${primary}`}>
                <VideoCard
                  label="对方"
                  kind="remote"
                  primary={primary}
                  onSelect={selectVideo}
                  videoRef={remote}
                />
                <VideoCard
                  label="我"
                  kind="local"
                  primary={primary}
                  onSelect={selectVideo}
                  videoRef={local}
                  mirrored
                />
                <div className="call-controls">
                  <button
                    className={`media-control ${mute ? "is-off" : "is-on"}`}
                    onClick={toggleMute}
                    title={mute ? "麦克风已关闭" : "麦克风已开启"}
                    aria-label={mute ? "打开麦克风" : "关闭麦克风"}
                    aria-pressed={mute}
                  >
                    <Icon
                      icon={mute
                        ? "solar:microphone-3-bold"
                        : "solar:microphone-bold"}
                    />
                    <span>{mute ? "已静音" : "麦克风"}</span>
                  </button>
                  <button
                    className={`media-control ${camera ? "is-on" : "is-off"}`}
                    onClick={toggleCamera}
                    title={camera ? "摄像头已开启" : "摄像头已关闭"}
                  >
                    <Icon
                      icon={camera
                        ? "solar:videocamera-bold"
                        : "solar:videocamera-record-bold"}
                    />
                    <span>{camera ? "摄像头" : "已关闭"}</span>
                  </button>
                </div>
              </section>
              <section className="chat">
                <div className="chat-title">
                  <span>
                    悄悄话 {unread ? <b className="badge">{unread}</b> : null}
                  </span>
                  <div className="chat-status">
                    <small>
                      <i />实时在线
                    </small>
                    <button
                      type="button"
                      className={notificationsEnabled ? "enabled" : ""}
                      onClick={enableNotifications}
                      title={notificationsEnabled
                        ? "系统通知已开启"
                        : "开启系统通知"}
                      aria-label={notificationsEnabled
                        ? "系统通知已开启"
                        : "开启系统通知"}
                    >
                      <Icon
                        icon={notificationsEnabled
                          ? "solar:bell-bold"
                          : "solar:bell-off-bold"}
                      />
                    </button>
                  </div>
                </div>
                <div className="messages">
                  {messages.length
                    ? messages.map((message) => (
                      <div
                        className={`message ${
                          message.senderSlot === me ? "mine" : "theirs"
                        }`}
                        key={message.ID}
                      >
                        {message.kind === "image"
                          ? (
                            <img
                              src={message.imageUrl}
                              alt="聊天图片"
                              onLoad={() => scrollMessagesToBottom("auto")}
                            />
                          )
                          : message.content}
                      </div>
                    ))
                    : <p className="empty">发送第一条小消息吧 ✨</p>}
                  <div
                    ref={messagesEnd}
                    className="messages-end"
                    aria-hidden="true"
                  />
                </div>
                <form className="composer" onSubmit={send}>
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
                    onChange={(e) =>
                      e.target.files?.[0] && uploadChatImage(e.target.files[0])}
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
      <NoteModal
        open={noteOpen}
        draft={noteDraft}
        busy={busy}
        setDraft={setNoteDraft}
        close={() => setNoteOpen(false)}
        submit={sendNote}
      />
    </div>
  );
}

function HomePanel({
  albums,
  anniversaries,
  note,
  goCall,
  goAlbum,
  openNote,
}: {
  albums: AlbumItem[];
  anniversaries: Anniversary[];
  note?: LoveNote;
  goCall: () => void;
  goAlbum: () => void;
  openNote: () => void;
}) {
  const [slide, setSlide] = useState(0);
  const anniversary = anniversaries[0];
  useEffect(() => {
    if (albums.length < 2) return;
    const timer = window.setInterval(
      () => setSlide((value) => (value + 1) % albums.length),
      3000,
    );
    return () => window.clearInterval(timer);
  }, [albums.length]);
  const days = anniversary
    ? Math.max(
      0,
      Math.floor(
        (Date.now() - new Date(anniversary.date).getTime()) / 86400000,
      ),
    )
    : 0;
  return (
    <main className="home-panel">
      <header className="home-greeting">
        <p>WELCOME HOME · LOVE COTTAGE</p>
        <h1>
          晚上好，欢迎回到<br />我们的小屋。
        </h1>
      </header>
      <section className="home-dashboard">
        <article className="home-countdown">
          <p>
            <Icon icon="solar:heart-bold" />{" "}
            {anniversary?.title || "我们的纪念日"}
          </p>
          <strong>{days || "—"}</strong>
          <em>天</em>
          <small>
            {anniversary
              ? `从 ${
                new Date(anniversary.date).toLocaleDateString("zh-CN")
              } 开始，每一天都有了共同的名字。`
              : "在后台添加一条纪念日，开始记录属于你们的时间。"}
          </small>
          <button className="soft-button" onClick={goCall}>
            现在去见 TA <Icon icon="solar:videocamera-record-bold" />
          </button>
        </article>
        <article className="home-moment" onClick={goAlbum}>
          <div className="moment-art">
            {albums.length
              ? <img src={albums[slide].imageUrl} alt="我们的相册照片" />
              : (
                <>
                  <Icon icon="solar:gallery-wide-bold-duotone" />
                  <i />
                  <b>
                    我们的<br />小瞬间
                  </b>
                </>
              )}
          </div>
          <span>
            打开相册 <Icon icon="solar:arrow-right-up-bold" />
          </span>
          {albums.length > 1 && (
            <div className="carousel-dots">
              {albums.map((album, index) => (
                <i key={album.ID} className={index === slide ? "active" : ""} />
              ))}
            </div>
          )}
        </article>
      </section>
      <section className="love-note">
        <div>
          <Icon icon="solar:heart-bold-duotone" />
          <p>今日留言</p>
        </div>
        <strong>
          {note?.content || "写下一句只给 TA 的小小纪念，让温柔被好好收藏。"}
        </strong>
        <button onClick={openNote}>
          写下小小纪念 <Icon icon="solar:pen-new-square-bold" />
        </button>
      </section>
    </main>
  );
}

function AlbumPanel({
  albums,
  page,
  pages,
  total,
  uploading,
  uploadInput,
  onUpload,
  onDelete,
  onPage,
}: {
  albums: AlbumItem[];
  page: number;
  pages: number;
  total: number;
  uploading: boolean;
  uploadInput: React.RefObject<HTMLInputElement | null>;
  onUpload: (file: File) => void;
  onDelete: (id: number) => void;
  onPage: (page: number) => void;
}) {
  return (
    <main className="album-page">
      <header className="album-page-heading">
        <div>
          <p>OUR LITTLE MEMORIES</p>
          <h1>我们的相册</h1>
          <small>共 {total} 张照片，每页 20 张。</small>
        </div>
        <div>
          <input
            ref={uploadInput}
            hidden
            type="file"
            accept="image/*"
            onChange={(e) => e.target.files?.[0] && onUpload(e.target.files[0])}
          />
          <button
            className="upload-album"
            disabled={uploading}
            onClick={() => uploadInput.current?.click()}
          >
            <Icon icon="solar:gallery-add-bold" />
            {uploading ? "正在上传…" : "添加照片"}
          </button>
        </div>
      </header>
      <section className="album-grid">
        {albums.length
          ? albums.map((album) => (
            <article className="album-photo" key={album.ID}>
              <img src={album.imageUrl} alt={`相册照片 ${album.ID}`} />
              <div>
                <span>
                  身份 {album.uploaderSlot} ·{" "}
                  {new Date(album.uploadedAt).toLocaleDateString("zh-CN")}
                </span>
                <button
                  onClick={() =>
                    onDelete(album.ID)}
                  title="删除照片"
                >
                  <Icon icon="solar:trash-bin-trash-bold" />
                </button>
              </div>
            </article>
          ))
          : (
            <div className="album-empty">
              <Icon icon="solar:gallery-add-bold-duotone" />
              <strong>第一张照片，等你们一起放进来。</strong>
              <span>支持 JPG、PNG、GIF、WebP，单张不超过 10MB。</span>
            </div>
          )}
      </section>
      {pages > 1 && (
        <nav className="album-pagination" aria-label="相册分页">
          <button disabled={page === 1} onClick={() => onPage(page - 1)}>
            <Icon icon="solar:arrow-left-bold" />
          </button>
          <span>第 {page} / {pages} 页</span>
          <button disabled={page === pages} onClick={() => onPage(page + 1)}>
            <Icon icon="solar:arrow-right-bold" />
          </button>
        </nav>
      )}
    </main>
  );
}

function NoteModal(
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

function VideoCard({
  label,
  kind,
  primary,
  onSelect,
  videoRef,
  mirrored,
}: {
  label: string;
  kind: "local" | "remote";
  primary: string;
  onSelect: (kind: "local" | "remote") => void;
  videoRef?: React.RefObject<HTMLVideoElement | null>;
  mirrored?: boolean;
}) {
  return (
    <article
      className={`video-card ${kind} ${primary === kind ? "selected" : ""}`}
      onClick={() => onSelect(kind)}
    >
      <video
        ref={videoRef}
        autoPlay
        muted={kind === "local"}
        playsInline
        className={mirrored ? "mirror" : ""}
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
