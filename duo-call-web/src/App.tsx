import { Icon } from "@iconify/react";
import { type FormEvent, useEffect, useState } from "react";
import {
  type DuoPreferences,
  loadPreferences,
  PREFERENCES_KEY,
  resolveTheme,
  type Theme,
} from "./preferences";
import { Room } from "./features/room/Room";
import { ProfileAvatar } from "./components/ProfileAvatar";
import { HomePanel } from "./features/home/HomePanel";
import { DailyPanel } from "./features/daily/DailyPanel";
import { SettingsPanel } from "./features/settings/SettingsPanel";
import {
  CallStage,
  type CallVisualProps,
  FullscreenCall,
  MobileCallMenu,
} from "./features/call/CallViews";
import {
  type DailyState,
  type DuoStatus,
  type GrowthEvent,
  type Identity,
} from "./domain";
import {
  API_BASE_URL as api,
  API_CONFIGURATION_ERROR,
} from "./domain";
import {
  ThemeDecorations,
  ThemePicker,
} from "./components/ThemeControls";

export function App() {
  const [preferences, setPreferences] = useState<DuoPreferences>(() =>
    loadPreferences(localStorage)
  );
  const [systemDark, setSystemDark] = useState(() =>
    window.matchMedia?.("(prefers-color-scheme: dark)").matches || false
  );
  const theme = resolveTheme(preferences, systemDark);
  const [token, setToken] = useState(() =>
    localStorage.getItem("duo-session") || ""
  );
  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem("duo-theme", theme);
  }, [theme]);
  useEffect(() => {
    localStorage.setItem(PREFERENCES_KEY, JSON.stringify(preferences));
  }, [preferences]);
  useEffect(() => {
    const media = window.matchMedia?.("(prefers-color-scheme: dark)");
    if (!media) return;
    const update = (event: MediaQueryListEvent | MediaQueryList) =>
      setSystemDark(event.matches);
    update(media);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  const selectTheme = (value: Theme) => {
    setPreferences((current) => ({
      ...current,
      theme: value,
      defaultLightTheme: value === "dark"
        ? current.defaultLightTheme
        : value,
      followSystem: false,
    }));
  };
  const preview = import.meta.env.DEV
    ? new URLSearchParams(location.search).get("preview")
    : null;
  if (preview?.startsWith("daily")) {
    return <DailyPreview theme={theme} setTheme={selectTheme} revealed={preview === "daily-revealed"} />;
  }
  if (preview === "home" || preview === "settings" || preview === "call" || preview === "fullscreen") {
    return (
      <ExperiencePreview
        mode={preview}
        theme={theme}
        preferences={preferences}
        setTheme={selectTheme}
        setPreferences={setPreferences}
      />
    );
  }
  if (API_CONFIGURATION_ERROR) {
    return (
      <main className="login-shell">
        <section className="login-card" role="alert">
          <p className="eyebrow">APP CONFIGURATION</p>
          <h1>应用连接尚未配置</h1>
          <p className="error">
            <Icon icon="solar:danger-triangle-bold" />
            {API_CONFIGURATION_ERROR}
          </p>
        </section>
      </main>
    );
  }
  return token
    ? (
      <Room
        theme={theme}
        setTheme={selectTheme}
        preferences={preferences}
        setPreferences={setPreferences}
        token={token}
        leave={() => {
          localStorage.removeItem("duo-session");
          setToken("");
        }}
      />
    )
    : <Login theme={theme} setTheme={selectTheme} onLogin={setToken} />;
}

function ExperiencePreview({
  mode,
  theme,
  preferences,
  setTheme,
  setPreferences,
}: {
  mode: "home" | "settings" | "call" | "fullscreen";
  theme: Theme;
  preferences: DuoPreferences;
  setTheme: (value: Theme) => void;
  setPreferences: React.Dispatch<React.SetStateAction<DuoPreferences>>;
}) {
  const noop = () => {};
  const register = () => {};
  const previewIdentity: Identity = {
    slot: 1,
    displayName: "小海",
    avatarUrl: "",
    statusId: 1,
    status: { ID: 1, label: "正在想你", emoji: "💭" },
  };
  const previewStatuses: DuoStatus[] = [
    { ID: 1, label: "正在想你", emoji: "💭" },
    { ID: 2, label: "今天很开心", emoji: "☀️" },
    { ID: 3, label: "有一点忙", emoji: "🌿" },
  ];
  if (mode === "settings") {
    return (
      <div className="cottage-shell preview-shell">
        <SettingsPanel
          theme={theme}
          preferences={preferences}
          setTheme={setTheme}
          setPreferences={setPreferences}
          identity={previewIdentity}
          statuses={previewStatuses}
          saveProfile={async () => previewIdentity}
          uploadAvatar={async () => previewIdentity}
          leave={noop}
        />
      </div>
    );
  }
  if (mode === "home") {
    const image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='900' height='700'%3E%3Cdefs%3E%3ClinearGradient id='g' x2='1' y2='1'%3E%3Cstop stop-color='%23e8d4cd'/%3E%3Cstop offset='1' stop-color='%2393b1ac'/%3E%3C/linearGradient%3E%3C/defs%3E%3Crect width='900' height='700' fill='url(%23g)'/%3E%3Ccircle cx='450' cy='310' r='110' fill='%23fff' fill-opacity='.35'/%3E%3Ctext x='450' y='340' text-anchor='middle' font-size='76' fill='%23fff'%3E%E2%99%A5%3C/text%3E%3C/svg%3E";
    const stageId = new URLSearchParams(location.search).get("treeStage");
    const previewStage = {
      seed: { id: "seed" as const, name: "一颗种子", message: "故事已经被轻轻种下", minimum: 0, next: 40, progress: 18 },
      sprout: { id: "sprout" as const, name: "刚刚萌芽", message: "想念冒出了第一片叶子", minimum: 40, next: 120, progress: 46 },
      sapling: { id: "sapling" as const, name: "慢慢长高", message: "普通日子正在长成枝桠", minimum: 120, next: 260, progress: 68 },
      bloom: { id: "bloom" as const, name: "悄悄开花", message: "被好好记住的瞬间，开成了花", minimum: 260, next: 480, progress: 12 },
      canopy: { id: "canopy" as const, name: "枝叶相拥", message: "共同的故事已经长成树荫", minimum: 480, next: 480, progress: 100 },
    }[stageId || "bloom"] || {
      id: "bloom" as const,
      name: "悄悄开花",
      message: "被好好记住的瞬间，开成了花",
      minimum: 260,
      next: 480,
      progress: 12,
    };
    return (
      <div className="cottage-shell preview-shell">
        <HomePanel
          albums={Array.from({ length: 6 }, (_, index) => ({
            ID: index + 1,
            uploaderSlot: index % 2 + 1,
            imageUrl: image,
            uploadedAt: new Date(Date.now() - index * 86400000).toISOString(),
          }))}
          anniversaries={[{
            ID: 1,
            title: "我们在一起",
            date: "2024-02-14",
            enabled: true,
            sort: 1,
          }]}
          notes={[
            { ID: 4, senderSlot: 2, content: "刚刚路过一家小店，第一反应是你会喜欢。", CreatedAt: new Date().toISOString() },
            { ID: 3, senderSlot: 1, content: "今天也有认真想你。", CreatedAt: new Date(Date.now() - 3600000).toISOString() },
            { ID: 2, senderSlot: 2, content: "记得忙完以后好好吃饭。", CreatedAt: new Date(Date.now() - 7200000).toISOString() },
            { ID: 1, senderSlot: 1, content: "想和你一起收藏更多普通又闪亮的日子。", CreatedAt: new Date(Date.now() - 10800000).toISOString() },
          ]}
          openNote={noop}
          daily={null}
          me={1}
          openDaily={noop}
          identities={[
            { slot: 1, displayName: "小海", avatarUrl: "", statusId: 1, status: { ID: 1, label: "正在想你", emoji: "💭" } },
            { slot: 2, displayName: "小月", avatarUrl: "", statusId: 2, status: { ID: 2, label: "今天很开心", emoji: "☀️" } },
          ]}
          partnerOnline
          tree={{
            totalGrowth: 286,
            togetherDays: 895,
            stage: previewStage,
            events: Array.from({ length: 6 }, (_, index) => ({
              ID: index + 1,
              eventType: (["album", "daily_reply", "note", "chat", "call", "album"] as GrowthEvent["eventType"][])[index],
              sourceId: index + 1,
              slot: index % 2 + 1,
              growth: index === 0 ? 12 : 4,
              title: ["收藏了一张照片", "写下了一封回信", "留下了一句心里话", "今天也说了说话", "今天见了一面", "收藏了一张照片"][index],
              summary: "一个普通又值得记住的小瞬间，被好好收进了共同年轮。",
              imageUrl: index === 0 ? image : "",
              occurredAt: new Date(Date.now() - index * 86400000).toISOString(),
            })),
            weeklyMemories: [{ ID: 1, weekKey: "2026-W31", title: "本周的我们", summary: "这一周，你们认真回信、收藏照片，也在忙碌里记得和对方说说话。普通的小事，正悄悄长成共同的年轮。", source: "ai", generatedAt: new Date().toISOString() }],
          }}
        />
      </div>
    );
  }
  const visualProps: CallVisualProps = {
    localMedia: null,
    remoteMedia: null,
    camera: false,
    mute: false,
    micLevel: 58,
    calling: true,
    connectionState: "connected",
    remotePlaybackBlocked: false,
    onMute: noop,
    onCamera: noop,
    onResumeAudio: noop,
    onPlaybackBlocked: noop,
    registerRemoteVideo: register,
  };
  if (mode === "fullscreen") {
    return <FullscreenCall {...visualProps} onExit={noop} />;
  }
  return (
    <div className="cottage-shell is-call-view preview-shell">
      <aside className="cottage-nav" aria-label="预览导航">
        <nav>
          <button type="button"><Icon icon="solar:home-2-bold-duotone" />首页</button>
          <button type="button"><Icon icon="solar:letter-bold-duotone" />回信</button>
          <button type="button" className="active"><Icon icon="solar:phone-calling-rounded-bold-duotone" />连线</button>
          <button type="button"><Icon icon="solar:gallery-wide-bold-duotone" />相册</button>
          <button type="button"><Icon icon="solar:settings-bold-duotone" />设置</button>
        </nav>
      </aside>
      <main className="room preview-room">
        <header>
          <div className="brand">
            <Icon icon="solar:phone-calling-rounded-bold-duotone" />
            <b>今天，也要好好见面</b>
            <em>连线中</em>
          </div>
        </header>
        <div className="room-grid">
          <CallStage
            {...visualProps}
            remoteConnected={false}
            onFullscreen={noop}
            remoteMuted={false}
          />
          <section className="chat immersive-chat">
            <div className="chat-title"><span>悄悄话</span><small>界面预览</small></div>
            <div className="messages">
              <article className="message-row theirs">
                <ProfileAvatar identity={{ displayName: "小月", avatarUrl: "" }} />
                <div className="message">等你上线，一起说说今天。</div>
              </article>
              <article className="message-row mine">
                <ProfileAvatar identity={{ displayName: "小海", avatarUrl: "" }} />
                <div className="message">我来啦，今天有点想你。</div>
              </article>
            </div>
            <form className="composer" onSubmit={(event) => event.preventDefault()}>
              <MobileCallMenu
                {...visualProps}
                onFullscreen={noop}
              />
              <div className="emoji-control">
                <button type="button" aria-label="选择表情">😊</button>
              </div>
              <input placeholder="说点什么…" />
              <button type="submit" className="send" aria-label="发送">
                <Icon icon="solar:plain-2-bold" />
              </button>
            </form>
          </section>
        </div>
      </main>
    </div>
  );
}

function DailyPreview({
  theme,
  setTheme,
  revealed,
}: {
  theme: Theme;
  setTheme: (value: Theme) => void;
  revealed: boolean;
}) {
  const previewState: DailyState = {
    ID: 1,
    questionDate: new Date().toISOString(),
    question: "最近我做过哪件小事，让你觉得被好好放在心上？",
    category: "gratitude",
    source: "ai",
    revealedAt: revealed ? new Date().toISOString() : undefined,
    replies: [
      { slot: 1, submitted: revealed, content: revealed ? "你总会记得我随口说过的小事，这让我觉得自己被认真听见。" : undefined },
      { slot: 2, submitted: true, content: revealed ? "你忙完以后还是会问我今天过得怎么样，这件小事一直很温柔。" : undefined },
    ],
  };
  const previewHistory = revealed ? [previewState] : [];
  return (
    <div className="cottage-shell">
      <ThemeDecorations theme={theme} />
      <aside className="cottage-nav">
        <div className="nav-logo"><Icon icon="solar:heart-bold-duotone" /><span>Love Cottage<small>爱情小屋</small></span></div>
        <nav><button className="active"><Icon icon="solar:letter-bold-duotone" />回信</button></nav>
        <div className="nav-bottom"><ThemePicker theme={theme} setTheme={setTheme} compact /></div>
      </aside>
      <DailyPanel
        state={previewState}
        history={previewHistory}
        me={1}
        draft=""
        busy={false}
        setDraft={() => undefined}
        submit={(event) => event.preventDefault()}
        refresh={() => undefined}
      />
    </div>
  );
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
