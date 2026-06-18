"use client";

import { useEffect, useMemo, useRef, useState, useCallback } from "react";
import Image from "next/image";

/* ── 工具函数 ────────────────────────────────── */

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v));
const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

const normalizeExternalHref = (raw: string): string => {
  const value = (raw || "").trim();
  if (!value) return "#";
  if (/^[a-zA-Z][a-zA-Z\d+\-.]*:/.test(value)) return value;
  if (value.includes("@") && !value.includes("/")) return `mailto:${value}`;
  return `https://${value}`;
};

const isHereLink = (raw: string): boolean => (raw || "").trim().toLowerCase() === "here";

/* ── 类型 ───────────────────────────────────── */

type Project = { name: string; description: string; link: string };
type PlayItem = { name: string; description: string; link: string };
type ProfileData = {
  siteLabel: string;
  name: string;
  title: string;
  bio: string;
  hint?: string;
  hobby: string[];
  tags: string[];
  projects: Project[];
  play: PlayItem[];
  contact: Record<string, string>;
};
type AnimatedProfileProps = { profile: ProfileData };
type ChatMessage = { role: "assistant" | "user"; content: string };
type FireworkImage = {
  id: number;
  src: string;
  angle: number;       // 发射方向 (弧度)
  distance: number;     // 飞多远 (vw)
  delay: number;        // 延迟 (s)
  dur: number;          // 飞行时间 (s)
  scale: number;        // 最终缩放
  rotation: number;     // 自转角度 (deg)
};

/* ── 场景定义 ────────────────────────────────── */

type Scene = {
  id: string;
  kicker: string;
  title: string;
  subtitle: string;
  body: string;
  accents?: string[];
  link?: string;
  mode?: "default" | "play" | "contact";
};

/* ── 水印系统 ────────────────────────────────── */

type ContactWatermark = {
  key: string; left: number; top: number; size: number;
  driftX: number; driftY: number; opacity: number;
};

const WATERMARK_ANCHORS = [
  { left: 14, top: 16 }, { left: 74, top: 14 },
  { left: 8, top: 44 },  { left: 80, top: 46 },
  { left: 18, top: 74 }, { left: 70, top: 76 },
];

const hashString = (input: string): number => {
  let hash = 0;
  for (let i = 0; i < input.length; i += 1) hash = (hash * 31 + input.charCodeAt(i)) >>> 0;
  return hash;
};

const buildDeterministicWatermarks = (entries: Array<[string, string]>): ContactWatermark[] =>
  entries.map(([key], idx) => {
    const h = hashString(`${key}-${idx}`);
    const b = WATERMARK_ANCHORS[idx % WATERMARK_ANCHORS.length];
    return {
      key,
      left: clamp(b.left + ((h % 9) - 4), 5, 86),
      top: clamp(b.top + ((Math.floor(h / 17) % 9) - 4), 6, 84),
      size: 42 + (h % 30),
      driftX: (h % 28) - 14,
      driftY: (Math.floor(h / 13) % 24) - 12,
      opacity: 0.1 + (h % 10) * 0.008,
    };
  });

const buildRandomWatermarks = (entries: Array<[string, string]>): ContactWatermark[] => {
  const shuffled = [...WATERMARK_ANCHORS].sort(() => Math.random() - 0.5);
  return entries.map(([key], idx) => {
    const b = shuffled[idx % shuffled.length];
    return {
      key,
      left: clamp(b.left + (Math.random() * 12 - 6), 5, 86),
      top: clamp(b.top + (Math.random() * 12 - 6), 6, 84),
      size: 40 + Math.random() * 34,
      driftX: Math.random() * 34 - 17,
      driftY: Math.random() * 30 - 15,
      opacity: 0.1 + Math.random() * 0.1,
    };
  });
};

/* ── Intersection Observer Hook ─────────────── */

function useInView(threshold = 0.15) {
  const ref = useRef<HTMLElement | null>(null);
  const [isInView, setIsInView] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) { setIsInView(true); obs.disconnect(); } },
      { threshold }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [threshold]);
  return { ref, isInView };
}

/* ── 渐变色配置 ──────────────────────────────── */

const ACCENT_COLORS = [
  "from-blue-500/20 via-indigo-500/10 to-violet-500/20",
  "from-pink-500/15 via-rose-500/10 to-orange-500/15",
  "from-teal-500/15 via-cyan-500/10 to-sky-500/15",
  "from-violet-500/15 via-purple-500/10 to-fuchsia-500/15",
];

/* ── 主组件 ──────────────────────────────────── */

export default function AnimatedProfile({ profile }: AnimatedProfileProps) {
  const [activeIndex, setActiveIndex] = useState(0);
  const [scrollY, setScrollY] = useState(0);
  const [viewportHeight, setViewportHeight] = useState(1);
  const [sectionOffsets, setSectionOffsets] = useState<number[]>([]);
  const [sectionHeights, setSectionHeights] = useState<number[]>([]);
  const [watermarkRandomTick, setWatermarkRandomTick] = useState(0);
  const [introReveal, setIntroReveal] = useState(0);
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [chatInput, setChatInput] = useState("");
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([]);
  const [chatInitialized, setChatInitialized] = useState(false);
  const [isChatLoading, setIsChatLoading] = useState(false);
  const [fireworks, setFireworks] = useState<FireworkImage[]>([]);
  const [eggActive, setEggActive] = useState(false);
  const [orbitAngle, setOrbitAngle] = useState(0);
  const [mousePos, setMousePos] = useState<{ x: number; y: number } | null>(null);
  const chatBottomRef = useRef<HTMLDivElement>(null);

  /* 持久化聊天记录 — localStorage 保存最近 10 条 */
  const CHAT_STORAGE_KEY = "personal-home-chat-history";
  const MAX_CHAT_HISTORY = 10;

  /* 初始化：从 localStorage 加载聊天记录 */
  useEffect(() => {
    if (typeof window === "undefined") return;
    try {
      const raw = localStorage.getItem(CHAT_STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as ChatMessage[];
        if (Array.isArray(parsed) && parsed.length > 0) {
          setChatMessages(parsed.slice(-MAX_CHAT_HISTORY));
          setChatInitialized(true);
          return;
        }
      }
    } catch { /* ignore */ }
    setChatMessages([
      { role: "assistant", content: "你好！我是这个主页的 AI 小助手 ✨ 你可以问我关于站主的任何信息~" },
    ]);
    setChatInitialized(true);
  }, []);

  /* 保存聊天记录到 localStorage */
  useEffect(() => {
    if (!chatInitialized || typeof window === "undefined") return;
    try {
      localStorage.setItem(
        CHAT_STORAGE_KEY,
        JSON.stringify(chatMessages.slice(-MAX_CHAT_HISTORY))
      );
    } catch { /* ignore */ }
  }, [chatMessages, chatInitialized]);

  /* 彩蛋相关 */
  const _cp = (...codes: number[]) => String.fromCodePoint(...codes);
  const _T = [26143, 27827, 22823, 29579, 54, 54, 54] as const;
  const _L1 = [26143, 27827, 22823, 29579] as const;
  const _L2 = [54, 54, 54] as const;

  useEffect(() => {
    chatBottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [chatMessages]);

  /* 烟花彩蛋触发 — 图片从中心向四周爆发 */
  const triggerEgg = useCallback(() => {
    const imgCount = 12;
    const fws: FireworkImage[] = [];

    // 分 3 波发射，每波 12 张
    for (let wave = 0; wave < 3; wave += 1) {
      for (let i = 0; i < imgCount; i += 1) {
        const angle = (Math.PI * 2 / imgCount) * i + Math.random() * 0.3 - 0.15;
        fws.push({
          id: wave * imgCount + i,
          src: `/api/profile-img/t${i + 1}.jpg`,
          angle,
          distance: 30 + Math.random() * 50,
          delay: wave * 0.6 + Math.random() * 0.4,
          dur: 4.0 + Math.random() * 2.0,
          scale: 0.6 + Math.random() * 0.6,
          rotation: (Math.random() - 0.5) * 360,
        });
      }
    }

    setFireworks(fws);
    setEggActive(true);

    setTimeout(() => {
      setFireworks([]);
      setEggActive(false);
    }, 8000);
  }, []);

  /* 联系方式 */
  const contactEntries = useMemo(
    () => Object.entries(profile.contact || {}).filter(([, v]) => Boolean(v)),
    [profile.contact]
  );
  const deterministicWatermarks = useMemo(() => buildDeterministicWatermarks(contactEntries), [contactEntries]);
  const contactWatermarks = useMemo(
    () => (watermarkRandomTick > 0 ? buildRandomWatermarks(contactEntries) : deterministicWatermarks),
    [contactEntries, deterministicWatermarks, watermarkRandomTick]
  );

  /* 兴趣词 */
  const hobbyWords = useMemo(() => {
    const clean = (profile.hobby || []).filter(Boolean);
    if (clean.length === 0) return ["Hobby", "Life", "Focus", "Play"];
    return Array.from({ length: 4 }, (_, idx) => clean[idx % clean.length]);
  }, [profile.hobby]);

  /* Play 轮播 */
  const playItems = useMemo(() => profile.play || [], [profile.play]);
  const [activePlayIndex, setActivePlayIndex] = useState(0);
  const playTouchStartX = useRef<number | null>(null);
  const playPointerStartX = useRef<number | null>(null);
  const playWheelLockedUntil = useRef(0);
  const safeActivePlayIndex = playItems.length > 0 ? Math.min(activePlayIndex, playItems.length - 1) : 0;

  useEffect(() => {
    if (playItems.length <= 1) return;
    const timer = setInterval(() => setActivePlayIndex((c) => (c + 1) % playItems.length), 8000);
    return () => clearInterval(timer);
  }, [playItems.length]);

  const goToPlay = useCallback(
    (delta: number) => {
      if (playItems.length === 0) return;
      setActivePlayIndex((c) => (c + delta + playItems.length) % playItems.length);
    },
    [playItems.length]
  );

  const handlePlayTouchStart = (e: React.TouchEvent) => { playTouchStartX.current = e.touches[0]?.clientX ?? null; };
  const handlePlayTouchEnd = (e: React.TouchEvent) => {
    const start = playTouchStartX.current; playTouchStartX.current = null;
    if (start == null) return;
    const dx = (e.changedTouches[0]?.clientX ?? start) - start;
    if (Math.abs(dx) >= 40) goToPlay(dx > 0 ? -1 : 1);
  };
  const handlePlayPointerDown = (e: React.PointerEvent) => { if (e.pointerType !== "touch") playPointerStartX.current = e.clientX; };
  const handlePlayPointerUp = (e: React.PointerEvent) => {
    if (e.pointerType === "touch") return;
    const start = playPointerStartX.current; playPointerStartX.current = null;
    if (start == null) return;
    const dx = e.clientX - start;
    if (Math.abs(dx) >= 40) goToPlay(dx > 0 ? -1 : 1);
  };
  const handlePlayWheel = (e: React.WheelEvent) => {
    if (playItems.length <= 1 || Math.abs(e.deltaY) < 18) return;
    e.preventDefault();
    const now = Date.now();
    if (now < playWheelLockedUntil.current) return;
    playWheelLockedUntil.current = now + 700;
    goToPlay(e.deltaY > 0 ? 1 : -1);
  };

  /* Chat — 流式 SSE */
  const handleChatSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const text = chatInput.trim();
    if (!text || isChatLoading) return;
    if (text.includes(_cp(..._T))) triggerEgg();
    const userMsg: ChatMessage = { role: "user", content: text };
    setChatInput("");
    setChatMessages((c) => [...c, userMsg]);
    setIsChatLoading(true);

    try {
      const history = chatMessages.map((m) => ({ role: m.role, content: m.content }));

      // 先插入一个空的 assistant 占位
      setChatMessages((c) => [...c, { role: "assistant", content: "" }]);

      const res = await fetch("/api/bc/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: [...history, { role: userMsg.role, content: userMsg.content }],
          profile_json: JSON.stringify(profile),
        }),
      });

      if (!res.ok || !res.body) {
        throw new Error("Stream not available");
      }

      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n");
        buffer = lines.pop() || "";

        for (const line of lines) {
          if (!line.startsWith("data: ")) continue;
          try {
            const parsed = JSON.parse(line.slice(6));
            const token = parsed?.token;
            if (!token) continue;

            if (token === "[DONE]") {
              // 流结束
            } else if (token === "[ERROR]") {
              setChatMessages((c) =>
                c.map((m, i) => (i === c.length - 1 ? { ...m, content: m.content + (parsed?.error || "错误") } : m))
              );
            } else {
              setChatMessages((c) =>
                c.map((m, i) => (i === c.length - 1 ? { ...m, content: m.content + token } : m))
              );
            }
          } catch { /* ignore malformed lines */ }
        }
      }
    } catch {
      setChatMessages((c) =>
        c.map((m, i) => (i === c.length - 1 && m.role === "assistant" && !m.content ? { ...m, content: "网络错误，请稍后再试。" } : m))
      );
    } finally {
      setIsChatLoading(false);
    }
  };

  /* 轨道动画 */
  useEffect(() => {
    let rafId = 0;
    const start = performance.now();
    const tick = (now: number) => {
      setOrbitAngle(((now - start) * 0.00015) % (Math.PI * 2));
      rafId = requestAnimationFrame(tick);
    };
    rafId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafId);
  }, []);

  /* 鼠标跟踪 */
  useEffect(() => {
    let rafId = 0;
    const onMove = (e: MouseEvent) => {
      cancelAnimationFrame(rafId);
      rafId = requestAnimationFrame(() => setMousePos({ x: e.clientX, y: e.clientY }));
    };
    window.addEventListener("mousemove", onMove, { passive: true });
    return () => { cancelAnimationFrame(rafId); window.removeEventListener("mousemove", onMove); };
  }, []);

  useEffect(() => {
    const frame = requestAnimationFrame(() => setWatermarkRandomTick((v) => v + 1));
    return () => cancelAnimationFrame(frame);
  }, [contactEntries]);

  /* 入场动画 */
  useEffect(() => {
    let frameId = 0;
    const duration = 2000;
    const delay = 100;
    const start = performance.now();
    const tick = (now: number) => {
      const elapsed = Math.max(0, now - start - delay);
      const progress = clamp(elapsed / duration, 0, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      setIntroReveal(eased);
      if (progress < 1) frameId = requestAnimationFrame(tick);
    };
    frameId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frameId);
  }, []);

  /* 场景列表 */
  const scenes = useMemo<Scene[]>(
    () => [
      {
        id: "intro",
        kicker: profile.siteLabel,
        title: profile.name,
        subtitle: profile.title,
        body: profile.bio,
        accents: hobbyWords,
      },
      {
        id: "tags",
        kicker: "EXPERTISE",
        title: "我专注的方向",
        subtitle: profile.tags.slice(0, 5).join(" · "),
        body: "每一项关键词都对应我持续投入的实践方向与深度积累。",
        accents: profile.tags.slice(0, 4),
      },
      ...profile.projects.map((project, idx) => ({
        id: `project-${idx}`,
        kicker: `PROJECT ${String(idx + 1).padStart(2, "0")}`,
        title: project.name,
        subtitle: project.description,
        body: "点击左下角按钮可直达项目链接。",
        accents: ["Project", project.name, "Ship", "Build"],
        link: project.link,
      })),
      {
        id: "play",
        kicker: "PLAYGROUND",
        title: "最近在玩什么",
        subtitle: "我还是一名重度游戏爱好者，游戏是生活中的调味剂。",
        body: "像轮播图一样切换条目，探索我生活中的趣味角落。",
        accents: ["Play", "Deck", "Flip", "Fun"],
        mode: "play",
      },
      {
        id: "contact",
        kicker: "CONNECT",
        title: "一起做点有趣的事",
        subtitle: "您可以通过这些方式联系我",
        body: "点击任意图标即可跳转到对应平台",
        accents: hobbyWords,
        mode: "contact",
      },
    ],
    [profile, hobbyWords]
  );

  /* 滚动追踪 */
  useEffect(() => {
    let rafId = 0;
    const onScroll = () => {
      cancelAnimationFrame(rafId);
      rafId = requestAnimationFrame(() => setScrollY(window.scrollY || 0));
    };
    const updateLayout = () => {
      setViewportHeight(window.innerHeight || 1);
      const els = Array.from(document.querySelectorAll<HTMLElement>("[data-scene-index]"))
        .sort((a, b) => Number(a.dataset.sceneIndex || 0) - Number(b.dataset.sceneIndex || 0));
      setSectionOffsets(els.map((el) => el.offsetTop));
      setSectionHeights(els.map((el) => el.offsetHeight));
    };
    updateLayout(); onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", updateLayout);
    return () => { cancelAnimationFrame(rafId); window.removeEventListener("scroll", onScroll); window.removeEventListener("resize", updateLayout); };
  }, [scenes.length, playItems.length]);

  useEffect(() => {
    if (sectionOffsets.length === 0) return;
    const anchor = scrollY + viewportHeight * 0.5;
    let next = 0;
    for (let i = 0; i < sectionOffsets.length; i += 1) {
      const top = sectionOffsets[i] ?? 0;
      const height = sectionHeights[i] ?? viewportHeight;
      if (anchor >= top && anchor < top + height) { next = i; break; }
      if (anchor >= top + height) next = i;
    }
    if (next !== activeIndex) setActiveIndex(next);
  }, [scrollY, viewportHeight, sectionOffsets, sectionHeights, activeIndex]);

  const parallaxSlowY = scrollY * 0.06;
  const parallaxMidY = scrollY * 0.12;
  const parallaxFastY = scrollY * 0.18;
  const activePlayItem = playItems[safeActivePlayIndex];

  const scrollToScene = useCallback(
    (idx: number) => {
      const top = sectionOffsets[idx];
      if (typeof top === "number") window.scrollTo({ top, behavior: "smooth" });
      else document.querySelector<HTMLElement>(`[data-scene-index='${idx}']`)?.scrollIntoView({ behavior: "smooth" });
    },
    [sectionOffsets]
  );

  /* 鼠标光晕位置 (转换为百分比) */
  const mouseGlowX = typeof window !== "undefined" && mousePos ? (mousePos.x / (window.innerWidth || 1)) * 100 : 50;
  const mouseGlowY = typeof window !== "undefined" && mousePos ? ((mousePos.y + scrollY) / (document.documentElement.scrollHeight || 1)) * 100 : 50;

  return (
    <main className="noise-overlay relative overflow-x-clip bg-[#f5f5f7] text-slate-900">
      {/* ── 背景层 ─────────────────────────────── */}
      <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
        {/* 鼠标追踪光晕 */}
        <div
          className="absolute h-[30rem] w-[30rem] rounded-full blur-[10rem] transition-all duration-1000 ease-out"
          style={{
            background: "radial-gradient(circle, rgba(59,130,246,0.08) 0%, transparent 70%)",
            left: `${mouseGlowX}%`,
            top: `${mouseGlowY}%`,
            transform: "translate(-50%, -50%)",
          }}
        />
        {/* 轨道光晕 */}
        {[
          { size: 42, color: "rgba(236,72,153,0.07)", speed: 0.38, phase: 0, xBase: 32, yBase: 10, xAmp: 6, yAmp: 8 },
          { size: 36, color: "rgba(56,189,248,0.06)", speed: 0.51, phase: 1.7, xBase: 74, yBase: 18, xAmp: 7, yAmp: 6 },
          { size: 38, color: "rgba(139,92,246,0.06)", speed: 0.44, phase: 2.8, xBase: 12, yBase: 62, xAmp: 5, yAmp: 7 },
          { size: 30, color: "rgba(251,146,60,0.05)", speed: 0.29, phase: 1.3, xBase: 78, yBase: 68, xAmp: 6, yAmp: 5 },
          { size: 28, color: "rgba(45,212,191,0.05)", speed: 0.35, phase: 3.5, xBase: 48, yBase: 42, xAmp: 5, yAmp: 4 },
          { size: 24, color: "rgba(253,224,71,0.04)", speed: 0.42, phase: 0.4, xBase: 58, yBase: 76, xAmp: 4, yAmp: 5 },
        ].map((g, i) => (
          <div
            key={i}
            className="absolute rounded-full"
            style={{
              height: `${g.size}rem`, width: `${g.size}rem`,
              background: g.color,
              filter: `blur(${g.size * 0.2}rem)`,
              left: `${g.xBase + Math.cos(orbitAngle * g.speed + g.phase) * g.xAmp}%`,
              top: `${g.yBase + Math.sin(orbitAngle * (g.speed * 1.8) + g.phase) * g.yAmp}%`,
              transform: "translate(-50%, -50%)",
            }}
          />
        ))}
        {/* 网格点阵 */}
        <div
          className="absolute inset-0 opacity-[0.08]"
          style={{
            backgroundImage: "radial-gradient(circle, rgba(15,23,42,0.25) 1px, transparent 1px)",
            backgroundSize: "36px 36px",
          }}
        />
      </div>

      {/* ── 侧边导航点 ─────────────────────────── */}
      <nav className="fixed left-5 top-1/2 z-20 hidden -translate-y-1/2 gap-3 md:flex md:flex-col" aria-label="页面导航">
        {scenes.map((scene, idx) => (
          <button
            key={scene.id}
            aria-label={`跳转到: ${scene.kicker}`}
            onClick={() => scrollToScene(idx)}
            className={`nav-dot h-2.5 w-2.5 rounded-full transition-all duration-300 ${
              idx === activeIndex
                ? "active w-8"
                : "bg-slate-300/70 hover:bg-slate-400/60"
            }`}
          />
        ))}
      </nav>

      {/* ── AI 聊天助手 ─────────────────────────── */}
      <div className="fixed right-5 top-5 z-50 md:right-8 md:top-8">
        {isChatOpen ? (
          <div className="glass-strong w-[min(calc(100vw-2.5rem),380px)] overflow-hidden rounded-[1.8rem] shadow-[0_24px_80px_rgba(15,23,42,0.18)] animate-in-scale">
            <div className="flex items-center justify-between border-b border-slate-200/60 px-5 py-4">
              <div>
                <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-blue-500">Cloud AI</p>
                <h2 className="mt-1 text-base font-bold text-slate-900">个人助手</h2>
              </div>
              <button
                type="button" aria-label="关闭"
                onClick={() => setIsChatOpen(false)}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-100 text-slate-500 transition-all hover:bg-slate-200 hover:text-slate-900"
              >
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M1 1l12 12M13 1L1 13" /></svg>
              </button>
            </div>
            <div className="max-h-[360px] space-y-3 overflow-y-auto px-5 py-4">
              {chatMessages.map((msg, i) => (
                <div key={`${msg.role}-${i}`} className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}>
                  <div
                    className={`max-w-[82%] rounded-2xl px-4 py-2.5 text-sm leading-6 ${
                      msg.role === "user"
                        ? "bg-gradient-to-br from-slate-800 to-slate-900 text-white shadow-lg"
                        : "bg-slate-50 text-slate-700 border border-slate-100"
                    }`}
                  >
                    {msg.content}
                  </div>
                </div>
              ))}
              <div ref={chatBottomRef} />
            </div>
            <div className="border-t border-slate-200/60 p-4">
              <form onSubmit={handleChatSubmit} className="flex items-center gap-2">
                <input
                  value={chatInput} onChange={(e) => setChatInput(e.target.value)}
                  placeholder="问问我的信息、项目或兴趣..."
                  disabled={isChatLoading}
                  className="min-w-0 flex-1 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-800 outline-none transition focus:border-blue-300 focus:ring-2 focus:ring-blue-100 disabled:opacity-50"
                />
                <button
                  type="submit" disabled={isChatLoading}
                  className="btn-glow rounded-xl bg-gradient-to-r from-blue-600 to-violet-600 px-4 py-2.5 text-sm font-semibold text-white shadow-lg transition hover:shadow-xl disabled:opacity-50"
                >
                  {isChatLoading ? (
                    <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                  ) : "发送"}
                </button>
              </form>
            </div>
          </div>
        ) : (
          <button
            type="button" aria-label="打开 AI 聊天"
            onClick={() => setIsChatOpen(true)}
            className="group relative h-20 w-20 md:h-24 md:w-24 animate-[chat-float_8s_ease-in-out_infinite]"
          >
            <span className="absolute inset-0 rounded-full bg-blue-400/30 blur-2xl transition duration-700 group-hover:scale-125 group-hover:bg-blue-400/40" />
            <span className="absolute inset-1 rounded-full border border-white/80 bg-gradient-to-br from-blue-50/90 to-violet-50/70 shadow-[0_16px_48px_rgba(59,130,246,0.18)] backdrop-blur-3xl transition duration-500 group-hover:scale-[1.03]" />
            <span className="absolute inset-3 rounded-full bg-gradient-to-br from-white via-blue-50 to-violet-100/60 shadow-[inset_0_2px_12px_rgba(59,130,246,0.08)]" />
            <span className="absolute left-1/2 top-1/2 h-14 w-14 -translate-x-1/2 -translate-y-1/2 rounded-full bg-gradient-to-br from-blue-100 via-white to-violet-100/80 shadow-[0_8px_32px_rgba(59,130,246,0.15),inset_0_1px_0_rgba(255,255,255,0.9)] transition duration-500 group-hover:rotate-6 md:h-16 md:w-16" />
            <span className="absolute left-1/2 top-1/2 h-[4.5rem] w-[4.5rem] -translate-x-1/2 -translate-y-1/2 rounded-full border border-blue-300/40 animate-[spin_18s_linear_infinite] md:h-[5.5rem] md:w-[5.5rem]" />
            <span className="absolute left-1/2 top-1/2 h-[5rem] w-[5rem] -translate-x-1/2 -translate-y-1/2 rounded-full border border-dashed border-violet-200/50 animate-[spin_28s_linear_infinite_reverse] md:h-[6rem] md:w-[6rem]" />
            <span className="absolute right-2.5 top-3 h-2 w-2 rounded-full bg-white shadow-[0_0_10px_rgba(255,255,255,1),0_0_20px_rgba(59,130,246,0.4)]" />
            <span className="absolute bottom-3.5 left-3 h-1.5 w-1.5 rounded-full bg-blue-100 shadow-[0_0_8px_rgba(59,130,246,0.35)]" />
            <span className="absolute inset-x-0 bottom-[42%] text-center text-[11px] font-bold tracking-wider text-blue-400/70 md:text-xs">
              Chat
            </span>
          </button>
        )}
      </div>

      {/* ── 烟花彩蛋 ──────────────────────────── */}
      {eggActive && (
        <div className="pointer-events-none fixed inset-0 z-[9998] overflow-hidden bg-black/80">
          {/* 中央大字 */}
          <div
            className="absolute inset-0 flex items-center justify-center animate-in-scale"
            style={{ animationDelay: "0.2s" }}
          >
            <div className="text-center">
              <p className="text-4xl font-black tracking-[0.3em] md:text-7xl" style={{ textShadow: "0 0 80px rgba(236,72,153,0.8), 0 0 160px rgba(251,146,60,0.6)" }}>
                <span className="bg-gradient-to-r from-yellow-200 via-pink-300 to-rose-200 bg-clip-text text-transparent">
                  {_cp(..._L1)}
                </span>
              </p>
              <p className="mt-2 text-lg font-light tracking-[0.5em] text-pink-200/70 md:text-2xl" style={{ textShadow: "0 0 30px rgba(236,72,153,0.4)" }}>
                {_cp(..._L2)}
              </p>
            </div>
          </div>

          {/* 烟花图片 */}
          {fireworks.map((fw) => {
            const dx = Math.cos(fw.angle) * fw.distance;
            const dy = Math.sin(fw.angle) * fw.distance;
            return (
              <div
                key={fw.id}
                className="absolute left-1/2 top-1/2"
                style={{
                  width: "180px",
                  height: "180px",
                  marginLeft: "-90px",
                  marginTop: "-90px",
                  opacity: 0,
                  animationName: "firework-burst",
                  animationDuration: `${fw.dur}s`,
                  animationDelay: `${fw.delay}s`,
                  animationTimingFunction: "cubic-bezier(0.12, 0.82, 0.36, 1)",
                  animationFillMode: "both",
                  ["--fw-dx" as string]: `${dx}vw`,
                  ["--fw-dy" as string]: `${dy}vh`,
                  ["--fw-dx-final" as string]: `${dx * 1.2}vw`,
                  ["--fw-dy-final" as string]: `${dy * 1.2}vh`,
                  ["--fw-scale" as string]: `${fw.scale}`,
                  ["--fw-rot" as string]: `${fw.rotation}deg`,
                }}
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={fw.src}
                  alt=""
                  className="h-full w-full rounded-xl object-cover shadow-[0_0_40px_rgba(255,255,255,0.3)]"
                  loading="lazy"
                />
              </div>
            );
          })}
        </div>
      )}

      {/* ── 场景渲染 ──────────────────────────── */}
      {scenes.map((scene, idx) => {
        const isIntro = idx === 0;
        const titleReveal = isIntro ? clamp((introReveal - 0.14) / 0.86, 0, 1) : 1;
        const subtitleReveal = isIntro ? clamp((introReveal - 0.28) / 0.72, 0, 1) : 1;
        const bodyReveal = isIntro ? clamp((introReveal - 0.4) / 0.6, 0, 1) : 1;
        const accentReveal = (d: number) => (isIntro ? clamp((introReveal - d) / (1 - d), 0, 1) : 1);
        const sectionTop = sectionOffsets[idx] ?? idx * viewportHeight;
        const normalizedOffset = (scrollY - sectionTop) / viewportHeight;
        const absOffset = Math.abs(normalizedOffset);
        const isActive = idx === activeIndex;
        const gradientClass = ACCENT_COLORS[idx % ACCENT_COLORS.length];

        return (
          <SceneSection
            key={scene.id}
            scene={scene}
            idx={idx}
            isActive={isActive}
            absOffset={absOffset}
            normalizedOffset={normalizedOffset}
            parallaxSlowY={parallaxSlowY}
            parallaxMidY={parallaxMidY}
            parallaxFastY={parallaxFastY}
            titleReveal={titleReveal}
            subtitleReveal={subtitleReveal}
            bodyReveal={bodyReveal}
            accentReveal={accentReveal}
            gradientClass={gradientClass}
            viewportHeight={viewportHeight}
            contactEntries={contactEntries}
            contactWatermarks={contactWatermarks}
            playItems={playItems}
            safeActivePlayIndex={safeActivePlayIndex}
            activePlayItem={activePlayItem}
            goToPlay={goToPlay}
            handlePlayTouchStart={handlePlayTouchStart}
            handlePlayTouchEnd={handlePlayTouchEnd}
            handlePlayPointerDown={handlePlayPointerDown}
            handlePlayPointerUp={handlePlayPointerUp}
            handlePlayWheel={handlePlayWheel}
            setActivePlayIndex={setActivePlayIndex}
            tags={profile.tags}
          />
        );
      })}
    </main>
  );
}

/* ── 场景片段组件 ────────────────────────────── */

type SceneSectionProps = {
  scene: Scene;
  idx: number;
  isActive: boolean;
  absOffset: number;
  normalizedOffset: number;
  parallaxSlowY: number;
  parallaxMidY: number;
  parallaxFastY: number;
  titleReveal: number;
  subtitleReveal: number;
  bodyReveal: number;
  accentReveal: (d: number) => number;
  gradientClass: string;
  viewportHeight: number;
  contactEntries: Array<[string, string]>;
  contactWatermarks: ContactWatermark[];
  playItems: PlayItem[];
  safeActivePlayIndex: number;
  activePlayItem: PlayItem | undefined;
  goToPlay: (delta: number) => void;
  handlePlayTouchStart: (e: React.TouchEvent) => void;
  handlePlayTouchEnd: (e: React.TouchEvent) => void;
  handlePlayPointerDown: (e: React.PointerEvent) => void;
  handlePlayPointerUp: (e: React.PointerEvent) => void;
  handlePlayWheel: (e: React.WheelEvent) => void;
  setActivePlayIndex: (fn: (c: number) => number) => void;
  tags: string[];
};

function SceneSection(props: SceneSectionProps) {
  const {
    scene, idx, isActive, absOffset, normalizedOffset,
    parallaxSlowY, parallaxMidY, parallaxFastY,
    titleReveal, subtitleReveal, bodyReveal, accentReveal,
    gradientClass, viewportHeight,
    contactEntries, contactWatermarks,
    playItems, safeActivePlayIndex, activePlayItem,
    goToPlay, handlePlayTouchStart, handlePlayTouchEnd,
    handlePlayPointerDown, handlePlayPointerUp, handlePlayWheel,
    setActivePlayIndex,
    tags,
  } = props;

  const { ref: sectionRef, isInView } = useInView(0.1);

  const titleY = normalizedOffset * -56;
  const subtitleY = normalizedOffset * -28;
  const bodyY = normalizedOffset * -16;

  return (
    <section
      ref={sectionRef as React.RefObject<HTMLElement>}
      data-scene-index={idx}
      className="relative flex min-h-screen items-center justify-center px-6 py-20"
    >
      {/* 背景渐变装饰 */}
      <div className={`pointer-events-none absolute inset-0 bg-gradient-to-br ${gradientClass} opacity-30`} />

      {/* 浮动装饰文字 */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        {scene.accents?.slice(0, 4).map((accent, accentIdx) => {
          const positions = [
            { left: "8%", top: "14%", cls: "text-4xl md:text-7xl text-pink-400/60" },
            { right: "10%", top: "28%", cls: "text-5xl md:text-8xl text-blue-400/55" },
            { left: "16%", bottom: "22%", cls: "text-3xl md:text-6xl text-violet-400/50" },
            { right: "14%", bottom: "14%", cls: "text-2xl md:text-5xl text-teal-400/45" },
          ];
          const pos = positions[accentIdx] || positions[0];
          const parallax = [parallaxSlowY, parallaxMidY, parallaxFastY, parallaxSlowY][accentIdx];
          const reveal = accentReveal(0.06 + accentIdx * 0.06);
          const { left, right, top, bottom, cls } = pos as typeof pos & { left?: string; right?: string; top?: string; bottom?: string; cls: string };

          return (
            <span
              key={`${scene.id}-accent-${accentIdx}`}
              className={`absolute font-extrabold tracking-tight ${cls}`}
              style={{
                left, right, top, bottom,
                opacity: clamp(0.85 - absOffset * 0.5, 0.12, 0.85) * reveal,
                transform: `translate3d(${(parallax * 0.3 + normalizedOffset * (accentIdx % 2 === 0 ? -18 : 18)).toFixed(1)}px, ${(-parallax * 0.35 + normalizedOffset * (accentIdx % 2 === 0 ? -24 : 20) + (1 - reveal) * 48).toFixed(1)}px, 0) scale(${(0.8 + reveal * 0.2).toFixed(3)})`,
                filter: `blur(${((1 - reveal) * 2).toFixed(1)}px)`,
              }}
            >
              {accent}
            </span>
          );
        })}
      </div>

      {/* 主卡片 */}
      <article
        className={`glass relative z-10 w-full max-w-5xl rounded-[2rem] p-8 shadow-[0_24px_100px_rgba(15,23,42,0.1)] transition-all duration-700 ease-out md:p-12 ${
          isInView ? "animate-in" : "opacity-0 translate-y-10"
        } ${isActive ? "translate-y-0 scale-100 opacity-100" : "translate-y-10 scale-[0.98] opacity-30"}`}
      >
        {/* 光线扫描效果 */}
        <div className="pointer-events-none absolute inset-0 overflow-hidden rounded-[2rem]">
          <div
            className="absolute inset-y-0 w-1/3 bg-gradient-to-r from-transparent via-white/20 to-transparent"
            style={{
              animation: "light-sweep 4s ease-in-out infinite",
              animationDelay: `${idx * 0.5}s`,
            }}
          />
        </div>

        {scene.mode === "contact" ? (
          /* ── 联系方式场景 ─────────────────────── */
          <div className="relative flex min-h-[520px] flex-col items-center justify-center py-6">
            {/* 水印层 */}
            <div className="pointer-events-none absolute inset-3 overflow-hidden rounded-[1.8rem]">
              {contactWatermarks.map((wm) => (
                <span
                  key={wm.key}
                  className="absolute font-black uppercase tracking-tight text-slate-400/50 blur-[1.2px]"
                  style={{
                    left: `${wm.left}%`, top: `${wm.top}%`,
                    opacity: wm.opacity,
                    fontSize: `${wm.size}px`,
                    transform: `translate3d(${normalizedOffset * wm.driftX}px, ${normalizedOffset * wm.driftY}px, 0)`,
                  }}
                >
                  {wm.key}
                </span>
              ))}
            </div>

            {/* 圆形联系人区域 — 滚动进入时从小变大 */}
            <div
              className="relative h-[420px] w-[420px] max-w-full transition-transform duration-500 ease-out"
              style={{
                transform: `scale(${clamp(1 - absOffset * 0.5, 0.5, 1).toFixed(3)})`,
                opacity: clamp(1 - absOffset * 0.6, 0.3, 1),
              }}
            >
              {/* SVG 轨道环 */}
              <div className="pointer-events-none absolute left-1/2 top-1/2 h-[400px] w-[400px] -translate-x-1/2 -translate-y-1/2">
                {[
                  { r: 155, dash: "600 380", dur: "26s", dir: "normal", width: 2, color: "rgba(59,130,246,0.2)", rot: 10 },
                  { r: 180, dash: "680 460", dur: "34s", dir: "reverse", width: 1.5, color: "rgba(139,92,246,0.18)", rot: 92 },
                  { r: 200, dash: "740 560", dur: "42s", dir: "normal", width: 1.5, color: "rgba(148,163,184,0.15)", rot: -24 },
                ].map((ring, ri) => (
                  <svg
                    key={ri}
                    className="absolute inset-0"
                    style={{ animation: `orbit-ring ${ring.dur} linear infinite ${ring.dir === "reverse" ? "reverse" : ""}` }}
                    viewBox="0 0 400 400" fill="none" aria-hidden
                  >
                    <circle
                      cx="200" cy="200" r={ring.r}
                      stroke={ring.color}
                      strokeWidth={ring.width}
                      strokeLinecap="round"
                      strokeDasharray={ring.dash}
                      transform={`rotate(${ring.rot} 200 200)`}
                    />
                  </svg>
                ))}
              </div>

              {/* 中心头像 */}
              <div className="absolute left-1/2 top-1/2 h-[200px] w-[200px] -translate-x-1/2 -translate-y-1/2 overflow-hidden rounded-full border-2 border-white/60 shadow-[0_12px_40px_rgba(15,23,42,0.12)]">
                <Image
                  src="/api/profile-img/profile_photo.jpg"
                  alt="profile" fill unoptimized
                  className="object-cover"
                  sizes="200px"
                />
              </div>

              {/* 联系方式图标环绕 */}
              <div className="absolute inset-0 animate-[orbit-ring_56s_linear_infinite]">
                {contactEntries.map(([key, link], ci) => {
                  const count = Math.max(contactEntries.length, 1);
                  const angleDeg = (360 / count) * ci;
                  const radius = count > 8 ? 195 : count > 6 ? 188 : 178;
                  const iconSize = count > 8 ? 48 : count > 6 ? 52 : 56;
                  return (
                    <div
                      key={key}
                      className="absolute left-1/2 top-1/2"
                      style={{ transform: `translate(-50%, -50%) rotate(${angleDeg}deg) translateY(-${radius}px)` }}
                    >
                      <a
                        href={normalizeExternalHref(link)} target="_blank" rel="noreferrer"
                        aria-label={key}
                        className="card-3d group flex items-center justify-center rounded-full border border-white/70 bg-white/90 shadow-[0_8px_24px_rgba(15,23,42,0.12)] backdrop-blur-sm"
                        style={{ width: `${iconSize}px`, height: `${iconSize}px` }}
                      >
                        <Image
                          src={`/api/profile-img/${encodeURIComponent(key)}`}
                          alt={key} width={28} height={28} unoptimized
                          className="h-7 w-7 object-contain transition-transform group-hover:scale-110"
                        />
                      </a>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        ) : scene.mode === "play" ? (
          /* ── Play 轮播场景 ────────────────────── */
          <div
            className="relative grid w-full max-w-6xl items-center gap-8 py-2 md:grid-cols-[0.9fr_1.1fr] md:gap-14 md:py-4"
            onWheel={handlePlayWheel}
            onTouchStart={handlePlayTouchStart}
            onTouchEnd={handlePlayTouchEnd}
            onPointerDown={handlePlayPointerDown}
            onPointerUp={handlePlayPointerUp}
          >
            <div>
              <p className="text-[10px] font-bold uppercase tracking-[0.3em] text-blue-500 md:text-xs">{scene.kicker}</p>
              <h2 className="mt-5 text-5xl font-black leading-[0.9] tracking-[-0.06em] text-slate-800 md:text-[6.5rem]">
                我正在<br />
                <span className="gradient-text">玩</span>
              </h2>
              <p className="mt-6 max-w-md text-sm leading-7 text-slate-500 md:text-base">
                点击箭头，探索我最近在玩的内容。
              </p>
              <div className="accent-line mt-8 w-16" />
            </div>

            {playItems.length > 0 ? (
              <div className="relative">
                <div className="pointer-events-none absolute -inset-6 rounded-[2.5rem] bg-gradient-to-br from-blue-100/50 via-transparent to-violet-100/30 blur-2xl" />
                <article className="glass relative min-h-[260px] rounded-[1.5rem] p-8 shadow-[0_20px_60px_rgba(15,23,42,0.1)] transition-all duration-500 md:min-h-[320px] md:p-10 card-3d">
                  <div className="flex h-full flex-col justify-between gap-10">
                    <div>
                      <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-violet-500 md:text-xs">Play Project</p>
                      <h3 className="mt-4 text-3xl font-black leading-tight tracking-tight text-slate-900 md:text-4xl">
                        {activePlayItem?.name}
                      </h3>
                      <p className="mt-4 max-w-lg whitespace-pre-line break-words text-sm leading-7 text-slate-600 md:text-base">
                        {activePlayItem?.description}
                      </p>
                    </div>
                    <div className="flex flex-wrap items-center justify-between gap-4">
                      {activePlayItem && isHereLink(activePlayItem.link) ? (
                        <span className="inline-flex items-center gap-2 text-sm font-semibold text-blue-500">
                          <span className="inline-block h-1.5 w-1.5 rounded-full bg-blue-500" /> 来自这里
                        </span>
                      ) : activePlayItem ? (
                        <a
                          href={normalizeExternalHref(activePlayItem.link)} target="_blank" rel="noreferrer"
                          className="btn-glow inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-blue-600 to-violet-600 px-5 py-2.5 text-sm font-semibold text-white shadow-lg transition hover:shadow-xl"
                        >
                          Explore <span aria-hidden>→</span>
                        </a>
                      ) : null}
                      <div className="flex items-center gap-3">
                        {playItems.length > 1 && (
                          <div className="flex items-center gap-2">
                            {[(-1), 1].map((dir) => (
                              <button
                                key={dir}
                                type="button"
                                aria-label={dir === -1 ? "上一个" : "下一个"}
                                onClick={() => goToPlay(dir)}
                                className="flex h-8 w-8 items-center justify-center rounded-full border border-slate-200 bg-white text-slate-500 shadow-sm transition hover:-translate-y-0.5 hover:text-slate-900"
                              >
                                <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                                  <polyline points={dir === -1 ? "15 18 9 12 15 6" : "9 18 15 12 9 6"} />
                                </svg>
                              </button>
                            ))}
                          </div>
                        )}
                        <span className="font-mono text-xs font-semibold tracking-wider text-slate-400">
                          {String(safeActivePlayIndex + 1).padStart(2, "0")}/{String(playItems.length).padStart(2, "0")}
                        </span>
                      </div>
                    </div>
                  </div>
                </article>
                {playItems.length > 1 && (
                  <div className="mt-5 flex justify-end gap-1.5">
                    {playItems.map((item, pi) => (
                      <button
                        key={`dot-${pi}`}
                        type="button"
                        aria-label={`切换到第 ${pi + 1} 项`}
                        onClick={() => setActivePlayIndex(() => pi)}
                        className={`rounded-full transition-all duration-300 ${
                          pi === safeActivePlayIndex
                            ? "w-8 h-1.5 bg-gradient-to-r from-blue-500 to-violet-500"
                            : "w-3 h-1.5 bg-slate-300 hover:bg-slate-400"
                        }`}
                      />
                    ))}
                  </div>
                )}
              </div>
            ) : (
              <div className="flex min-h-[240px] items-center justify-center rounded-[1.5rem] border-2 border-dashed border-slate-200 bg-white/40 text-slate-400">
                暂无 play 内容
              </div>
            )}
          </div>
        ) : (
          /* ── 默认文本场景 ─────────────────────── */
          <>
            <p
              className="text-[10px] font-bold uppercase tracking-[0.3em] text-blue-500 md:text-xs"
              style={{
                opacity: titleReveal,
                transform: `translate3d(0, ${(1 - titleReveal) * 20}px, 0)`,
                filter: `blur(${(1 - titleReveal) * 2}px)`,
              }}
            >
              {scene.kicker}
            </p>
            <h1 className="mt-4 text-5xl font-black leading-[0.95] tracking-tight text-slate-900 md:text-[5.5rem]">
              <span
                className={scene.id === "intro" ? "gradient-text inline-block" : "inline-block"}
                style={{
                  opacity: titleReveal,
                  filter: `blur(${(1 - titleReveal) * 5}px)`,
                  transform: `translate3d(0, ${titleY + (1 - titleReveal) * 50}px, 0) scale(${(0.92 + titleReveal * 0.08).toFixed(3)})`,
                  transformOrigin: "left center",
                }}
              >
                {scene.title}
              </span>
            </h1>
            <p className="mt-6 max-w-3xl text-xl font-semibold leading-snug text-slate-600 md:text-3xl">
              <span
                style={{
                  display: "inline-block",
                  opacity: subtitleReveal,
                  filter: `blur(${(1 - subtitleReveal) * 3}px)`,
                  transform: `translate3d(0, ${subtitleY + (1 - subtitleReveal) * 38}px, 0) scale(${(0.94 + subtitleReveal * 0.06).toFixed(3)})`,
                  transformOrigin: "left center",
                }}
              >
                {scene.subtitle}
              </span>
            </p>
            <div className="accent-line mt-6 w-12" />
            <p
              className="mt-5 max-w-3xl text-base leading-8 text-slate-500 md:text-lg"
              style={{
                opacity: bodyReveal,
                filter: `blur(${(1 - bodyReveal) * 2}px)`,
                transform: `translate3d(0, ${bodyY + (1 - bodyReveal) * 28}px, 0)`,
              }}
            >
              {scene.body}
            </p>

            {/* 标签展示 (tags 场景) */}
            {scene.id === "tags" && tags.length > 0 && (
              <div
                className="mt-8 flex flex-wrap gap-2"
                style={{ opacity: bodyReveal, filter: `blur(${(1 - bodyReveal) * 1.5}px)` }}
              >
                {tags.map((tag: string, ti: number) => (
                  <span key={tag} className="tag-pill" style={{ animationDelay: `${ti * 0.05}s` }}>
                    {tag}
                  </span>
                ))}
              </div>
            )}

            {/* 链接按钮 */}
            {scene.link && (
              isHereLink(scene.link) ? (
                <span className="mt-8 inline-flex items-center gap-2 rounded-full border border-slate-300/70 px-6 py-2.5 text-sm font-semibold text-slate-600 backdrop-blur-sm">
                  <span className="inline-block h-1.5 w-1.5 rounded-full bg-slate-400" /> 来自这里
                </span>
              ) : (
                <a
                  href={normalizeExternalHref(scene.link)} target="_blank" rel="noreferrer"
                  className="btn-glow mt-8 inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-slate-800 to-slate-900 px-7 py-3 text-sm font-semibold text-white shadow-lg transition hover:shadow-xl hover:translate-y-[-1px]"
                >
                  打开链接 <span aria-hidden className="text-white/70">↗</span>
                </a>
              )
            )}
          </>
        )}
      </article>
    </section>
  );
}