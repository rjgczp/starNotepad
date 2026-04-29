"use client";

import { useEffect, useMemo, useState } from "react";
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

type ProfileData = {
  siteLabel: string;
  name: string;
  title: string;
  bio: string;
  hobby: string[];
  tags: string[];
  projects: Project[];
  contact: Record<string, string>;
};

type AnimatedProfileProps = {
  profile: ProfileData;
};

type Scene = {
  id: string;
  kicker: string;
  title: string;
  subtitle: string;
  body: string;
  accents?: string[];
  link?: string;
};

export default function AnimatedProfile({ profile }: AnimatedProfileProps) {
  const [activeIndex, setActiveIndex] = useState(0);
  const [scrollY, setScrollY] = useState(0);
  const [viewportHeight, setViewportHeight] = useState(1);
  const [watermarkRandomTick, setWatermarkRandomTick] = useState(0);
  const [introReveal, setIntroReveal] = useState(0);
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
        body: "点击右下角按钮可直达项目链接。",
        accents: ["Project", project.name, "Case", "Ship"],
        link: project.link,
      })),
      {
        id: "contact",
        kicker: "联系方式",
        title: "一起做点有趣的事",
        subtitle: "您可以通过这些方式联系我",
        body: "点击任意图标即可跳转到对应平台",
        accents: hobbyWords,
      },
    ],
    [profile, hobbyWords]
  );

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          const next = Number(entry.target.getAttribute("data-scene-index"));
          if (!Number.isNaN(next)) setActiveIndex(next);
        });
      },
      {
        threshold: 0.6,
      }
    );

    const elements = document.querySelectorAll<HTMLElement>("[data-scene-index]");
    elements.forEach((el) => observer.observe(el));

    return () => observer.disconnect();
  }, [scenes.length]);

  useEffect(() => {
    let rafId = 0;
    const onScroll = () => {
      cancelAnimationFrame(rafId);
      rafId = requestAnimationFrame(() => {
        setScrollY(window.scrollY || 0);
      });
    };

    const onResize = () => {
      setViewportHeight(window.innerHeight || 1);
    };

    onResize();
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onResize);

    return () => {
      cancelAnimationFrame(rafId);
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onResize);
    };
  }, []);

  const parallaxSlowY = scrollY * 0.08;
  const parallaxMidY = scrollY * 0.14;
  const parallaxFastY = scrollY * 0.2;

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
            onClick={() => {
              document
                .querySelector<HTMLElement>(`[data-scene-index='${idx}']`)
                ?.scrollIntoView({ behavior: "smooth", block: "start" });
            }}
            className={`h-2.5 w-2.5 rounded-full transition-all ${
              idx === activeIndex ? "w-8 bg-sky-600" : "bg-slate-300"
            }`}
          />
        ))}
      </div>

      {scenes.map((scene, idx) => (
        (() => {
          const isIntroScene = idx === 0;
          const titleReveal = isIntroScene ? clamp((introReveal - 0.14) / 0.86, 0, 1) : 1;
          const subtitleReveal = isIntroScene ? clamp((introReveal - 0.28) / 0.72, 0, 1) : 1;
          const bodyReveal = isIntroScene ? clamp((introReveal - 0.4) / 0.6, 0, 1) : 1;
          const accentReveal = (delay: number) =>
            isIntroScene ? clamp((introReveal - delay) / (1 - delay), 0, 1) : 1;
          const normalizedOffset = (scrollY - idx * viewportHeight) / viewportHeight;
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
            {scene.id === "contact" ? (
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
                  <a
                    href={normalizeExternalHref(scene.link)}
                    target="_blank"
                    rel="noreferrer"
                    className="mt-10 inline-flex items-center gap-2 rounded-full bg-slate-900 px-7 py-3 text-sm font-semibold text-white transition-transform hover:translate-x-1"
                  >
                    打开链接
                    <span aria-hidden>↗</span>
                  </a>
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
