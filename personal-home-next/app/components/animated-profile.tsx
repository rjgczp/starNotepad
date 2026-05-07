"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Image from "next/image";

const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

const normalizeExternalHref = (raw: string): string => {
  const value = (raw || "").trim();
  if (!value) return "#";

  const hasProtocol = /^[a-zA-Z][a-zA-Z\d+\-.]*:/.test(value);
  if (hasProtocol) return value;

  if (value.includes("@") && !value.includes("/")) {
    return `mailto:${value}`;
  }

  return `https://${value}`;
};

const isHereLink = (raw: string): boolean => (raw || "").trim().toLowerCase() === "here";

const hashString = (input: string): number => {
  let hash = 0;
  for (let i = 0; i < input.length; i += 1) {
    hash = (hash * 31 + input.charCodeAt(i)) >>> 0;
  }
  return hash;
};

type ContactWatermark = {
  key: string;
  left: number;
  top: number;
  size: number;
  driftX: number;
  driftY: number;
  opacity: number;
};

const WATERMARK_ANCHORS = [
  { left: 14, top: 16 },
  { left: 74, top: 14 },
  { left: 8, top: 44 },
  { left: 80, top: 46 },
  { left: 18, top: 74 },
  { left: 70, top: 76 },
];

const buildDeterministicWatermarks = (entries: Array<[string, string]>): ContactWatermark[] => {
  return entries.map(([key], idx) => {
    const hash = hashString(`${key}-${idx}`);
    const base = WATERMARK_ANCHORS[idx % WATERMARK_ANCHORS.length];
    return {
      key,
      left: clamp(base.left + ((hash % 9) - 4), 5, 86),
      top: clamp(base.top + ((Math.floor(hash / 17) % 9) - 4), 6, 84),
      size: 42 + (hash % 30),
      driftX: (hash % 28) - 14,
      driftY: (Math.floor(hash / 13) % 24) - 12,
      opacity: 0.13 + (hash % 10) * 0.01,
    };
  });
};

const buildRandomWatermarks = (entries: Array<[string, string]>): ContactWatermark[] => {
  const shuffledAnchors = [...WATERMARK_ANCHORS].sort(() => Math.random() - 0.5);
  return entries.map(([key], idx) => {
    const base = shuffledAnchors[idx % shuffledAnchors.length];
    return {
      key,
      left: clamp(base.left + (Math.random() * 12 - 6), 5, 86),
      top: clamp(base.top + (Math.random() * 12 - 6), 6, 84),
      size: 40 + Math.random() * 34,
      driftX: Math.random() * 34 - 17,
      driftY: Math.random() * 30 - 15,
      opacity: 0.12 + Math.random() * 0.12,
    };
  });
};

type Project = {
  name: string;
  description: string;
  link: string;
};

type PlayItem = {
  name: string;
  description: string;
  link: string;
};

type ProfileData = {
  siteLabel: string;
  name: string;
  title: string;
  bio: string;
  hobby: string[];
  tags: string[];
  projects: Project[];
  play: PlayItem[];
  contact: Record<string, string>;
};

type AnimatedProfileProps = {
  profile: ProfileData;
};

type ChatMessage = {
  role: "assistant" | "user";
  content: string;
};

type EggParticle = {
  id: number;
  text: string;
  x: number;
  delay: number;
  dur: number;
  color: string;
  size: number;
  rot: number;
};

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
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
    {
      role: "assistant",
      content: "你好，我是这个主页里的 AI 小助手。你可以问我关于站主、项目、兴趣方向或我的联系方式。",
    },
  ]);
  const [isChatLoading, setIsChatLoading] = useState(false);
  const [eggParticles, setEggParticles] = useState<EggParticle[]>([]);
  const [cloudOffset, setCloudOffset] = useState({ x: 0, y: 0, rotate: 0 });
  const chatBottomRef = useRef<HTMLDivElement>(null);

  const _cp = (...codes: number[]) => String.fromCodePoint(...codes);
  const _T  = [26143,27827,22823,29579,54,54,54] as const;
  const _L1 = [26143,27827,22823,29579] as const;
  const _L2 = [54,54,54] as const;

  useEffect(() => {
    chatBottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [chatMessages]);

  const triggerEgg = () => {
    const hearts = ["\u2764\uFE0F","\uD83D\uDC95","\uD83D\uDC97","\uD83C\uDF38","\u2728"];
    const palette = ["#ffb3c6","#ffc8dd","#bde0fe","#cdb4db","#a2d2ff","#b5e8cb","#ffd6a5","#caffbf","#fdcfe8","#c8b6ff"];
    const phrases = [
      [22909,21487,29233],   // 好可爱
      [30495,26834],         // 真棒
      [20320,26368,24069],   // 你最帅
      [22826,37239,20102],   // 太酷了
      [24320,24515],         // 开心
      [38378,38378,21457,20809], // 闪闪发光
      [23431,23449,26080,25932,21487,29233], // 宇宙无敌
    ].map((c) => _cp(...c));
    const items = [_cp(..._L1), _cp(..._L2), ...hearts, ...phrases];
    const ps: EggParticle[] = Array.from({ length: 72 }, (_, i) => ({
      id: i,
      text: items[Math.floor(Math.random() * items.length)],
      x: Math.random() * 94,
      delay: Math.random() * 3.5,
      dur: 2.8 + Math.random() * 1.8,
      color: palette[Math.floor(Math.random() * palette.length)],
      size: 13 + Math.floor(Math.random() * 22),
      rot: Math.random() * 34 - 17,
    }));
    setEggParticles(ps);
    setTimeout(() => setEggParticles([]), 8200);
  };
  const contactEntries = useMemo(
    () => Object.entries(profile.contact || {}).filter(([, value]) => Boolean(value)),
    [profile.contact]
  );
  const deterministicWatermarks = useMemo(
    () => buildDeterministicWatermarks(contactEntries),
    [contactEntries]
  );
  const contactWatermarks = useMemo(
    () => (watermarkRandomTick > 0 ? buildRandomWatermarks(contactEntries) : deterministicWatermarks),
    [contactEntries, deterministicWatermarks, watermarkRandomTick]
  );
  const hobbyWords = useMemo(() => {
    const clean = (profile.hobby || []).filter(Boolean);
    if (clean.length === 0) return ["Hobby", "Life", "Focus", "Play"];
    return Array.from({ length: 4 }, (_, idx) => clean[idx % clean.length]);
  }, [profile.hobby]);
  const playItems = useMemo(() => profile.play || [], [profile.play]);
  const [activePlayIndex, setActivePlayIndex] = useState(0);
  const playTouchStartX = useRef<number | null>(null);
  const playPointerStartX = useRef<number | null>(null);
  const playWheelLockedUntil = useRef(0);
  const safeActivePlayIndex = playItems.length > 0 ? Math.min(activePlayIndex, playItems.length - 1) : 0;

  useEffect(() => {
    if (playItems.length <= 1) return;
    const timer = setInterval(() => {
      setActivePlayIndex((current) => (current + 1) % playItems.length);
    }, 10000);
    return () => clearInterval(timer);
  }, [playItems.length]);

  const goToPlay = (delta: number) => {
    if (playItems.length === 0) return;
    setActivePlayIndex((current) => {
      const next = (current + delta + playItems.length) % playItems.length;
      return next;
    });
  };

  const handlePlayTouchStart = (e: React.TouchEvent<HTMLDivElement>) => {
    playTouchStartX.current = e.touches[0]?.clientX ?? null;
  };
  const handlePlayTouchEnd = (e: React.TouchEvent<HTMLDivElement>) => {
    const start = playTouchStartX.current;
    playTouchStartX.current = null;
    if (start == null) return;
    const end = e.changedTouches[0]?.clientX ?? start;
    const dx = end - start;
    if (Math.abs(dx) < 40) return;
    goToPlay(dx > 0 ? -1 : 1);
  };
  const handlePlayPointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    if (e.pointerType === "touch") return;
    playPointerStartX.current = e.clientX;
  };
  const handlePlayPointerUp = (e: React.PointerEvent<HTMLDivElement>) => {
    if (e.pointerType === "touch") return;
    const start = playPointerStartX.current;
    playPointerStartX.current = null;
    if (start == null) return;
    const dx = e.clientX - start;
    if (Math.abs(dx) < 40) return;
    goToPlay(dx > 0 ? -1 : 1);
  };
  const handlePlayWheel = (e: React.WheelEvent<HTMLDivElement>) => {
    if (playItems.length <= 1) return;
    if (Math.abs(e.deltaY) < 18) return;
    e.preventDefault();
    const now = Date.now();
    if (now < playWheelLockedUntil.current) return;
    playWheelLockedUntil.current = now + 700;
    goToPlay(e.deltaY > 0 ? 1 : -1);
  };

  const handleChatSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const text = chatInput.trim();
    if (!text || isChatLoading) return;
    if (text.includes(_cp(..._T))) triggerEgg();
    const userMessage: ChatMessage = { role: "user", content: text };
    setChatInput("");
    setChatMessages((current) => [...current, userMessage]);
    setIsChatLoading(true);
    try {
      const history = chatMessages.map((m) => ({ role: m.role, content: m.content }));
      const res = await fetch("/api/bc/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages: [...history, { role: userMessage.role, content: userMessage.content }] }),
      });
      const json = (await res.json()) as { code?: number; data?: { reply?: string }; msg?: string };
      const reply = json?.data?.reply ?? json?.msg ?? "抱歉，AI 暂时无法回复，请稍后再试。";
      setChatMessages((current) => [...current, { role: "assistant", content: reply }]);
    } catch {
      setChatMessages((current) => [
        ...current,
        { role: "assistant", content: "网络错误，请稍后再试。" },
      ]);
    } finally {
      setIsChatLoading(false);
    }
  };

  useEffect(() => {
    const timer = setInterval(() => {
      setCloudOffset({
        x: Math.round(Math.random() * 18 - 9),
        y: Math.round(Math.random() * 14 - 7),
        rotate: Math.round(Math.random() * 8 - 4),
      });
    }, 2600);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    const frame = requestAnimationFrame(() => {
      setWatermarkRandomTick((v) => v + 1);
    });
    return () => cancelAnimationFrame(frame);
  }, [contactEntries]);

  useEffect(() => {
    let frameId = 0;
    const duration = 1800;
    const delay = 120;
    const start = performance.now();

    const tick = (now: number) => {
      const elapsed = Math.max(0, now - start - delay);
      const progress = clamp(elapsed / duration, 0, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      setIntroReveal(eased);
      if (progress < 1) {
        frameId = requestAnimationFrame(tick);
      }
    };

    frameId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frameId);
  }, []);

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
        kicker: "能力关键词",
        title: "我专注的方向",
        subtitle: profile.tags.slice(0, 5).join(" · "),
        body: "每一项关键词都对应我持续投入的实践方向。",
        accents: profile.tags.slice(0, 4),
      },
      ...profile.projects.map((project, idx) => ({
        id: `project-${idx}`,
        kicker: `项目 ${idx + 1}`,
        title: project.name,
        subtitle: project.description,
        body: "点击左下角按钮可直达项目链接。",
        accents: ["Project", project.name, "Case", "Ship"],
        link: project.link,
      })),
      {
        id: "play",
        kicker: "Play",
        title: "最近在玩什么",
        subtitle: "我还是一名重度游戏爱好者，甚至有时会沉迷游戏。",
        body: "像轮播图一样切换条目，它们是我生活中的调味剂。",
        accents: ["Play", "Deck", "Flip", "Fun"],
        mode: "play",
      },
      {
        id: "contact",
        kicker: "联系方式",
        title: "一起做点有趣的事",
        subtitle: "您可以通过这些方式联系我",
        body: "点击任意图标即可跳转到对应平台",
        accents: hobbyWords,
        mode: "contact",
      },
    ],
    [profile, hobbyWords]
  );

  useEffect(() => {
    let rafId = 0;
    const onScroll = () => {
      cancelAnimationFrame(rafId);
      rafId = requestAnimationFrame(() => {
        setScrollY(window.scrollY || 0);
      });
    };

    const updateLayoutMetrics = () => {
      setViewportHeight(window.innerHeight || 1);
      const elements = Array.from(document.querySelectorAll<HTMLElement>("[data-scene-index]"))
        .sort(
          (a, b) =>
            Number(a.getAttribute("data-scene-index") || 0) -
            Number(b.getAttribute("data-scene-index") || 0)
        );
      const offsets = elements.map((el) => el.offsetTop);
      const heights = elements.map((el) => el.offsetHeight);
      setSectionOffsets(offsets);
      setSectionHeights(heights);
    };

    updateLayoutMetrics();
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", updateLayoutMetrics);

    return () => {
      cancelAnimationFrame(rafId);
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", updateLayoutMetrics);
    };
  }, [scenes.length, playItems.length]);

  useEffect(() => {
    if (sectionOffsets.length === 0) return;
    const viewportAnchor = scrollY + viewportHeight * 0.5;
    let nextIndex = 0;

    for (let idx = 0; idx < sectionOffsets.length; idx += 1) {
      const top = sectionOffsets[idx] ?? 0;
      const height = sectionHeights[idx] ?? viewportHeight;
      const bottom = top + height;
      if (viewportAnchor >= top && viewportAnchor < bottom) {
        nextIndex = idx;
        break;
      }
      if (viewportAnchor >= bottom) {
        nextIndex = idx;
      }
    }

    if (nextIndex !== activeIndex) {
      setActiveIndex(nextIndex);
    }
  }, [scrollY, viewportHeight, sectionOffsets, sectionHeights, activeIndex]);

  const parallaxSlowY = scrollY * 0.08;
  const parallaxMidY = scrollY * 0.14;
  const parallaxFastY = scrollY * 0.2;
  const activePlayItem = playItems[safeActivePlayIndex];
  const scrollToScene = (idx: number) => {
    const top = sectionOffsets[idx];
    if (typeof top !== "number") {
      document
        .querySelector<HTMLElement>(`[data-scene-index='${idx}']`)
        ?.scrollIntoView({ behavior: "smooth", block: "start" });
      return;
    }
    window.scrollTo({ top, behavior: "smooth" });
  };

  return (
    <main className="relative snap-y snap-mandatory overflow-x-clip bg-[#f5f5f7] text-slate-900">
      <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
        <div
          className="absolute -left-24 top-[-12rem] h-[34rem] w-[34rem] rounded-full bg-pink-300/35 blur-3xl"
          style={{ transform: `translate3d(0, ${parallaxSlowY}px, 0)` }}
        />
        <div
          className="absolute right-[-8rem] top-[22vh] h-[26rem] w-[26rem] rounded-full bg-blue-300/30 blur-3xl"
          style={{ transform: `translate3d(0, ${-parallaxMidY}px, 0)` }}
        />
        <div
          className="absolute left-1/2 top-[58vh] h-[30rem] w-[30rem] -translate-x-1/2 rounded-full bg-violet-200/25 blur-3xl"
          style={{ transform: `translate3d(-50%, ${parallaxFastY}px, 0)` }}
        />
        <div
          className="absolute inset-0 opacity-20"
          style={{
            transform: `translate3d(0, ${-parallaxSlowY}px, 0)`,
            backgroundImage:
              "radial-gradient(circle, rgba(15,23,42,0.22) 1.2px, transparent 1.2px)",
            backgroundSize: "30px 30px",
          }}
        />
      </div>

      <div className="fixed left-5 top-1/2 z-20 hidden -translate-y-1/2 gap-2 md:flex md:flex-col">
        {scenes.map((scene, idx) => (
          <button
            key={scene.id}
            aria-label={`跳转到第${idx + 1}幕`}
            onClick={() => scrollToScene(idx)}
            className={`h-2.5 w-2.5 rounded-full transition-all ${
              idx === activeIndex ? "w-8 bg-sky-600" : "bg-slate-300"
            }`}
          />
        ))}
      </div>

      <div className="fixed right-5 top-5 z-50 md:right-8 md:top-8">
        {isChatOpen ? (
          <div className="w-[min(calc(100vw-2.5rem),380px)] overflow-hidden rounded-[2rem] border border-white/80 bg-white/85 shadow-[0_24px_80px_rgba(15,23,42,0.22)] backdrop-blur-2xl">
            <div className="flex items-center justify-between border-b border-slate-200/80 px-5 py-4">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.22em] text-sky-500">Cloud AI</p>
                <h2 className="mt-1 text-lg font-black text-slate-950">个人主页助手</h2>
              </div>
              <button
                type="button"
                aria-label="关闭 AI 聊天窗口"
                onClick={() => setIsChatOpen(false)}
                className="rounded-full border border-slate-200 bg-white px-3 py-1.5 text-sm font-bold text-slate-500 shadow-sm transition hover:text-slate-950"
              >
                ×
              </button>
            </div>
            <div className="max-h-[360px] space-y-3 overflow-y-auto px-5 py-4">
              {chatMessages.map((message, messageIdx) => (
                <div
                  key={`${message.role}-${messageIdx}`}
                  className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}
                >
                  <div
                    className={`max-w-[82%] rounded-3xl px-4 py-3 text-sm leading-6 shadow-sm ${
                      message.role === "user"
                        ? "bg-slate-950 text-white"
                        : "border border-slate-200 bg-white text-slate-700"
                    }`}
                  >
                    {message.content}
                  </div>
                </div>
              ))}
              <div ref={chatBottomRef} />
            </div>
            <div className="border-t border-slate-200/80 p-4">
              <form onSubmit={handleChatSubmit} className="flex items-center gap-2">
                <input
                  value={chatInput}
                  onChange={(e) => setChatInput(e.target.value)}
                  placeholder="问问我的个人信息、项目或兴趣..."
                  disabled={isChatLoading}
                  className="min-w-0 flex-1 rounded-full border border-slate-200 bg-white px-4 py-3 text-sm text-slate-800 outline-none transition focus:border-sky-300 focus:ring-4 focus:ring-sky-100 disabled:opacity-50"
                />
                <button
                  type="submit"
                  disabled={isChatLoading}
                  className="rounded-full bg-slate-950 px-4 py-3 text-sm font-black text-white shadow-lg transition hover:-translate-y-0.5 disabled:opacity-50"
                >
                  {isChatLoading ? "…" : "发送"}
                </button>
              </form>
            </div>
          </div>
        ) : (
          <button
            type="button"
            aria-label="打开 AI 聊天助手"
            onClick={() => setIsChatOpen(true)}
            className="group relative h-24 w-24 transition-transform duration-700 ease-in-out md:h-28 md:w-28"
            style={{
              transform: `translate3d(${cloudOffset.x}px, ${cloudOffset.y}px, 0) rotate(${cloudOffset.rotate}deg)`,
            }}
          >
            <span className="absolute inset-0 rounded-full bg-pink-200/70 blur-2xl transition duration-700 group-hover:scale-125 group-hover:bg-pink-300/60" />
            <span className="absolute inset-1.5 rounded-full border border-white/90 bg-gradient-to-br from-pink-50/80 to-rose-50/60 shadow-[0_16px_48px_rgba(251,113,133,0.22)] backdrop-blur-3xl transition duration-500 group-hover:scale-105" />
            <span className="absolute inset-[0.9rem] rounded-full bg-gradient-to-br from-white via-pink-50 to-rose-100/70 shadow-[inset_0_2px_12px_rgba(251,113,133,0.12)]" />
            <span className="absolute left-1/2 top-1/2 h-[4.6rem] w-[4.6rem] -translate-x-1/2 -translate-y-1/2 rounded-full bg-gradient-to-br from-pink-100 via-white to-rose-100/80 shadow-[0_8px_32px_rgba(251,113,133,0.18),inset_0_1px_0_rgba(255,255,255,0.95)] transition duration-500 group-hover:rotate-6 md:h-[5.2rem] md:w-[5.2rem]" />
            <span className="absolute left-1/2 top-1/2 h-[6rem] w-[6rem] -translate-x-1/2 -translate-y-1/2 rounded-full border border-pink-300/50 animate-[spin_18s_linear_infinite] md:h-[7rem] md:w-[7rem]" />
            <span className="absolute left-1/2 top-1/2 h-[6.6rem] w-[6.6rem] -translate-x-1/2 -translate-y-1/2 rounded-full border border-dashed border-rose-200/60 animate-[spin_28s_linear_infinite_reverse] md:h-[7.8rem] md:w-[7.8rem]" />
            <span className="absolute right-3 top-3.5 h-2.5 w-2.5 rounded-full bg-white shadow-[0_0_12px_rgba(255,255,255,1),0_0_24px_rgba(251,113,133,0.5)]" />
            <span className="absolute bottom-4 left-3.5 h-2 w-2 rounded-full bg-pink-100 shadow-[0_0_10px_rgba(251,113,133,0.45)]" />
            <span className="absolute -right-0.5 top-[42%] h-1.5 w-1.5 rounded-full bg-rose-200/90 shadow-[0_0_8px_rgba(251,113,133,0.4)]" />
            <span className="absolute inset-x-0 top-7 text-center text-sm font-black tracking-tight text-slate-900 md:top-8">
              AI
            </span>
            <span className="absolute inset-x-0 bottom-7 text-center text-sm font-black tracking-tight text-slate-900 md:bottom-8">
              Chat
            </span>
          </button>
        )}
      </div>

      {eggParticles.length > 0 && (
        <div className="pointer-events-none fixed inset-0 z-[9998] overflow-hidden">
          {eggParticles.map((p) => (
            <span
              key={p.id}
              className="absolute top-0 select-none font-black"
              style={{
                left: `${p.x}%`,
                color: p.color,
                fontSize: `${p.size}px`,
                textShadow: `0 0 10px ${p.color}88`,
                animationName: "fall",
                animationDuration: `${p.dur}s`,
                animationDelay: `${p.delay}s`,
                animationTimingFunction: "linear",
                animationFillMode: "both",
                ["--r" as string]: `${p.rot}deg`,
              }}
            >
              {p.text}
            </span>
          ))}
        </div>
      )}

      {scenes.map((scene, idx) => (
        (() => {
          const isIntroScene = idx === 0;
          const titleReveal = isIntroScene ? clamp((introReveal - 0.14) / 0.86, 0, 1) : 1;
          const subtitleReveal = isIntroScene ? clamp((introReveal - 0.28) / 0.72, 0, 1) : 1;
          const bodyReveal = isIntroScene ? clamp((introReveal - 0.4) / 0.6, 0, 1) : 1;
          const accentReveal = (delay: number) =>
            isIntroScene ? clamp((introReveal - delay) / (1 - delay), 0, 1) : 1;
          const sectionTop = sectionOffsets[idx] ?? idx * viewportHeight;
          const normalizedOffset = (scrollY - sectionTop) / viewportHeight;
          const absOffset = Math.abs(normalizedOffset);
          const titleScale = 1 - clamp(absOffset, 0, 1.2) * 0.12;
          const subtitleScale = 1 - clamp(absOffset, 0, 1.2) * 0.07;
          const cardOpacity = 1 - clamp(absOffset, 0, 1.4) * 0.52;
          const titleY = normalizedOffset * -56;
          const subtitleY = normalizedOffset * -28;
          const bodyY = normalizedOffset * -16;

          return (
        <section
          key={scene.id}
          data-scene-index={idx}
          className="relative flex min-h-screen snap-start items-center justify-center px-6 py-16"
        >
          <div className="pointer-events-none absolute inset-0">
            <span
              className="absolute left-[8%] top-[14%] text-4xl font-extrabold text-pink-400/70 md:text-7xl"
              style={{
                opacity: clamp(0.85 - absOffset * 0.5, 0.18, 0.85) * accentReveal(0.06),
                transform: `translate3d(${parallaxSlowY * 0.4 + normalizedOffset * -20}px, ${
                  -parallaxSlowY * 0.45 + normalizedOffset * -28 + (1 - accentReveal(0.06)) * 52
                }px, 0) scale(${0.8 + accentReveal(0.06) * 0.2})`,
              }}
            >
              {scene.accents?.[0]}
            </span>
            <span
              className="absolute right-[10%] top-[32%] text-5xl font-black text-pink-500/75 md:text-8xl"
              style={{
                transform: `translate3d(${(-parallaxMidY * 0.42 + normalizedOffset * 26).toFixed(2)}px, ${(parallaxMidY * 0.3 + normalizedOffset * -14 + (1 - accentReveal(0.12)) * 44).toFixed(2)}px, 0) scale(${(0.82 + accentReveal(0.12) * 0.18).toFixed(3)})`,
                opacity: clamp(0.9 - absOffset * 0.55, 0.14, 0.9) * accentReveal(0.12),
              }}
            >
              {scene.accents?.[1]}
            </span>
            <span
              className="absolute left-[18%] bottom-[22%] text-3xl font-extrabold text-blue-400/65 md:text-6xl"
              style={{
                opacity: clamp(0.8 - absOffset * 0.45, 0.16, 0.8) * accentReveal(0.18),
                transform: `translate3d(${parallaxFastY * 0.24 + normalizedOffset * 18}px, ${
                  -parallaxFastY * 0.25 + normalizedOffset * 18 + (1 - accentReveal(0.18)) * 40
                }px, 0) scale(${0.82 + accentReveal(0.18) * 0.18})`,
              }}
            >
              {scene.accents?.[2]}
            </span>
            <span
              className="absolute right-[16%] bottom-[14%] text-2xl font-bold text-violet-400/65 md:text-5xl"
              style={{
                opacity: clamp(0.72 - absOffset * 0.5, 0.12, 0.72) * accentReveal(0.24),
                transform: `translate3d(${-parallaxSlowY * 0.3 + normalizedOffset * -12}px, ${
                  parallaxSlowY * 0.3 + normalizedOffset * 26 + (1 - accentReveal(0.24)) * 34
                }px, 0) scale(${0.84 + accentReveal(0.24) * 0.16})`,
              }}
            >
              {scene.accents?.[3]}
            </span>
          </div>

          <article
            className={`relative z-10 w-full max-w-4xl rounded-[2.2rem] border border-white/70 bg-white/55 p-8 shadow-[0_24px_100px_rgba(15,23,42,0.12)] backdrop-blur-xl transition-all duration-700 md:p-12 ${
              idx === activeIndex
                ? "translate-y-0 scale-100 opacity-100"
                : "translate-y-14 scale-[0.97] opacity-25"
            }`}
            style={{ opacity: clamp(cardOpacity, 0.25, 1) }}
          >
            {scene.mode === "contact" ? (
              <div className="relative flex min-h-[560px] flex-col items-center justify-center py-8">
                <div className="pointer-events-none absolute inset-3 overflow-hidden rounded-[2rem]">
                  {contactWatermarks.map((wm) => (
                    <span
                      key={wm.key}
                      className="absolute font-black uppercase tracking-tight text-slate-500 blur-[1.6px]"
                      style={{
                        left: `${wm.left}%`,
                        top: `${wm.top}%`,
                        opacity: wm.opacity,
                        fontSize: `${wm.size}px`,
                        transform: `translate3d(${normalizedOffset * wm.driftX}px, ${normalizedOffset * wm.driftY}px, 0)`,
                      }}
                    >
                      {wm.key}
                    </span>
                  ))}
                </div>
                <div className="relative h-[460px] w-[460px] max-w-full rounded-full">
                  <div className="pointer-events-none absolute left-1/2 top-1/2 h-[430px] w-[430px] -translate-x-1/2 -translate-y-1/2">
                    <svg
                      className="absolute inset-0 animate-[spin_26s_linear_infinite]"
                      viewBox="0 0 430 430"
                      fill="none"
                      aria-hidden
                    >
                      <circle
                        cx="215"
                        cy="215"
                        r="160"
                        stroke="rgba(100,116,139,0.36)"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeDasharray="620 385"
                        transform="rotate(10 215 215)"
                      />
                    </svg>
                    <svg
                      className="absolute inset-0 animate-[spin_34s_linear_infinite_reverse]"
                      viewBox="0 0 430 430"
                      fill="none"
                      aria-hidden
                    >
                      <circle
                        cx="215"
                        cy="215"
                        r="188"
                        stroke="rgba(148,163,184,0.3)"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeDasharray="700 480"
                        transform="rotate(92 215 215)"
                      />
                    </svg>
                    <svg
                      className="absolute inset-0 animate-[spin_42s_linear_infinite]"
                      viewBox="0 0 430 430"
                      fill="none"
                      aria-hidden
                    >
                      <circle
                        cx="215"
                        cy="215"
                        r="213"
                        stroke="rgba(148,163,184,0.26)"
                        strokeWidth="1.5"
                        strokeLinecap="round"
                        strokeDasharray="760 580"
                        transform="rotate(-24 215 215)"
                      />
                    </svg>
                  </div>

                  <div className="absolute left-1/2 top-1/2 h-[240px] w-[240px] -translate-x-1/2 -translate-y-1/2 overflow-hidden rounded-full border border-slate-200 bg-white shadow-[0_10px_30px_rgba(15,23,42,0.1)]">
                    <Image
                      src="/api/profile-img/profile_photo.jpg"
                      alt="profile"
                      fill
                      className="object-cover"
                      sizes="240px"
                    />
                  </div>

                  <div className="absolute inset-0 animate-[spin_56s_linear_infinite]">
                    {contactEntries.map(([key, link], contactIdx) => {
                      const count = Math.max(contactEntries.length, 1);
                      const angleDeg = (360 / count) * contactIdx;
                      const radius = count > 8 ? 214 : count > 6 ? 206 : 196;
                      const iconSize = count > 8 ? 52 : count > 6 ? 56 : 64;
                      return (
                        <div
                          key={key}
                          className="absolute left-1/2 top-1/2"
                          style={{
                            transform: `translate(-50%, -50%) rotate(${angleDeg}deg) translateY(-${radius}px)`,
                          }}
                        >
                          <a
                            href={normalizeExternalHref(link)}
                            target="_blank"
                            rel="noreferrer"
                            aria-label={key}
                            className="group flex items-center justify-center rounded-full border border-slate-200 bg-white shadow-[0_8px_24px_rgba(15,23,42,0.15)] transition-transform hover:scale-110"
                            style={{ width: `${iconSize}px`, height: `${iconSize}px` }}
                          >
                            <Image
                              src={`/api/profile-img/${encodeURIComponent(key)}`}
                              alt={key}
                              width={32}
                              height={32}
                              className="h-8 w-8 object-contain"
                            />
                          </a>
                        </div>
                      );
                    })}
                  </div>

                </div>
              </div>
            ) : scene.mode === "play" ? (
              <div
                className="relative grid w-full max-w-6xl items-center gap-10 py-2 md:grid-cols-[0.95fr_1.05fr] md:gap-16 md:py-6"
                onWheel={handlePlayWheel}
                onTouchStart={handlePlayTouchStart}
                onTouchEnd={handlePlayTouchEnd}
                onPointerDown={handlePlayPointerDown}
                onPointerUp={handlePlayPointerUp}
              >
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.26em] text-slate-500 md:text-sm">
                    {scene.kicker}
                  </p>
                  <h2 className="mt-4 text-6xl font-black leading-[0.88] tracking-[-0.08em] text-slate-800 md:text-[7.5rem]">
                    我正在
                    <br />
                    玩
                  </h2>
                  <p className="mt-6 max-w-md text-sm leading-7 text-slate-500 md:text-base">
                    点击箭头，切换我最近在玩的内容。
                  </p>
                </div>

                {playItems.length > 0 ? (
                  <div className="relative">
                    <div className="pointer-events-none absolute -inset-8 rounded-[3rem] bg-gradient-to-br from-slate-200/70 via-transparent to-white blur-2xl" />
                    <article className="relative min-h-[280px] rounded-[1.6rem] border border-slate-200/80 bg-white/86 p-8 shadow-[0_24px_60px_rgba(15,23,42,0.14)] backdrop-blur-xl transition-all duration-500 md:min-h-[340px] md:p-10">
                      <div className="flex h-full flex-col justify-between gap-12">
                        <div>
                          <p className="text-xs font-black uppercase tracking-[0.24em] text-blue-500">
                            Play Project
                          </p>
                          <h3 className="mt-5 text-4xl font-black leading-none tracking-tight text-slate-950 md:text-5xl">
                            {activePlayItem?.name}
                          </h3>
                          <p className="mt-5 max-w-lg whitespace-pre-line break-words text-base leading-7 text-slate-600">
                            {activePlayItem?.description}
                          </p>
                        </div>

                        <div className="flex flex-wrap items-center justify-between gap-4">
                          {activePlayItem && isHereLink(activePlayItem.link) ? (
                            <span className="inline-flex items-center gap-2 text-sm font-bold text-blue-500">
                              来自这里
                            </span>
                          ) : activePlayItem ? (
                            <a
                              href={normalizeExternalHref(activePlayItem.link)}
                              target="_blank"
                              rel="noreferrer"
                              className="inline-flex items-center gap-2 text-sm font-bold text-blue-500 transition-transform hover:translate-x-1"
                            >
                              Explore Project
                              <span aria-hidden>→</span>
                            </a>
                          ) : null}
                          <div className="flex items-center gap-4">
                            {playItems.length > 1 ? (
                              <div className="flex items-center gap-2">
                                <button
                                  type="button"
                                  aria-label="上一个 play 项目"
                                  onClick={() => goToPlay(-1)}
                                  className="rounded-full border border-slate-200 bg-white p-2 text-slate-500 shadow-sm transition hover:-translate-x-0.5 hover:text-slate-900"
                                >
                                  <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                                    <polyline points="15 18 9 12 15 6" />
                                  </svg>
                                </button>
                                <button
                                  type="button"
                                  aria-label="下一个 play 项目"
                                  onClick={() => goToPlay(1)}
                                  className="rounded-full border border-slate-200 bg-white p-2 text-slate-500 shadow-sm transition hover:translate-x-0.5 hover:text-slate-900"
                                >
                                  <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                                    <polyline points="9 18 15 12 9 6" />
                                  </svg>
                                </button>
                              </div>
                            ) : null}
                            <span className="text-xs font-bold tracking-[0.18em] text-slate-400">
                              {String(safeActivePlayIndex + 1).padStart(2, "0")}/{String(playItems.length).padStart(2, "0")}
                            </span>
                          </div>
                        </div>
                      </div>
                    </article>

                    {playItems.length > 1 ? (
                      <div className="mt-6 flex justify-end gap-2">
                        {playItems.map((item, playIdx) => (
                          <button
                            type="button"
                            key={`play-dot-${item.name}-${playIdx}`}
                            aria-label={`切换到第 ${playIdx + 1} 个 play 项目`}
                            onClick={() => setActivePlayIndex(playIdx)}
                            className={`h-1.5 rounded-full transition-all ${
                              playIdx === safeActivePlayIndex ? "w-10 bg-slate-800" : "w-4 bg-slate-300"
                            }`}
                          />
                        ))}
                      </div>
                    ) : null}
                  </div>
                ) : (
                  <div className="flex min-h-[260px] items-center justify-center rounded-[1.6rem] border border-dashed border-slate-300 bg-white/60 text-slate-500">
                    暂无 play 内容
                  </div>
                )}
              </div>
            ) : (
              <>
                <p
                  className="text-xs font-semibold uppercase tracking-[0.26em] text-slate-500 md:text-sm"
                  style={{
                    opacity: titleReveal,
                    transform: `translate3d(0, ${(1 - titleReveal) * 24}px, 0)`,
                    filter: `blur(${(1 - titleReveal) * 2.5}px)`,
                  }}
                >
                  {scene.kicker}
                </p>
                <h1 className="mt-4 text-6xl font-black leading-[0.96] tracking-tight text-slate-900 md:text-[6.4rem]">
                  <span
                    className={
                      scene.id === "intro"
                        ? "inline-block bg-gradient-to-r from-blue-300 via-sky-300 to-indigo-300 bg-clip-text text-transparent"
                        : "inline-block"
                    }
                    style={{
                      opacity: titleReveal,
                      filter: `blur(${(1 - titleReveal) * 5}px)`,
                      transform: `translate3d(0, ${titleY + (1 - titleReveal) * 56}px, 0) scale(${titleScale * (0.92 + titleReveal * 0.08)})`,
                      transformOrigin: "left center",
                    }}
                  >
                    {scene.title}
                  </span>
                </h1>
                <p className="mt-7 max-w-3xl text-2xl font-semibold leading-snug text-slate-700 md:text-4xl">
                  <span
                    style={{
                      display: "inline-block",
                      opacity: subtitleReveal,
                      filter: `blur(${(1 - subtitleReveal) * 3.2}px)`,
                      transform: `translate3d(0, ${subtitleY + (1 - subtitleReveal) * 42}px, 0) scale(${subtitleScale * (0.94 + subtitleReveal * 0.06)})`,
                      transformOrigin: "left center",
                    }}
                  >
                    {scene.subtitle}
                  </span>
                </p>
                <p
                  className="mt-6 max-w-3xl text-base leading-8 text-slate-600 md:text-lg"
                  style={{
                    opacity: bodyReveal,
                    filter: `blur(${(1 - bodyReveal) * 2.4}px)`,
                    transform: `translate3d(0, ${bodyY + (1 - bodyReveal) * 32}px, 0)`,
                  }}
                >
                  {scene.body}
                </p>

                {scene.link ? (
                  isHereLink(scene.link) ? (
                    <span className="mt-10 inline-flex items-center gap-2 rounded-full border border-slate-300 px-7 py-3 text-sm font-semibold text-slate-700">
                      来自这里
                    </span>
                  ) : (
                    <a
                      href={normalizeExternalHref(scene.link)}
                      target="_blank"
                      rel="noreferrer"
                      className="mt-10 inline-flex items-center gap-2 rounded-full bg-slate-900 px-7 py-3 text-sm font-semibold text-white transition-transform hover:translate-x-1"
                    >
                      打开链接
                      <span aria-hidden>↗</span>
                    </a>
                  )
                ) : null}
              </>
            )}
          </article>
        </section>
          );
        })()
      ))}
    </main>
  );
}
