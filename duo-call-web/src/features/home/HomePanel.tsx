import { Icon } from "@iconify/react";
import { useEffect, useMemo, useState } from "react";
import { ProfileAvatar } from "../../components/ProfileAvatar";
import { ZoomableImage } from "../../components/ImageViewer";
import {
  mediaUrl,
  type AlbumItem,
  type Anniversary,
  type CottageView,
  type DailyState,
  type GrowthEvent,
  type Identity,
  type LoveNote,
  type TreeState,
  type WeeklyMemory,
} from "../../domain";
import { displayNameForSlot, orderTreeMembers } from "../../preferences";
import {
  editorialFallbackCopy,
  editorialMember,
  editorialWeekLabel,
  selectEditorialCover,
  selectEditorialMoments,
  selectLatestWeeklyMemory,
  selectRewindMoment,
  weeklyMemoryLabel,
} from "./homeEditorial";

const MOMENT_META: Record<GrowthEvent["eventType"], { icon: string; label: string }> = {
  album: { icon: "solar:gallery-wide-bold-duotone", label: "新照片" },
  daily_reply: { icon: "solar:letter-bold-duotone", label: "共同回信" },
  note: { icon: "solar:chat-round-heart-bold-duotone", label: "一句留言" },
  chat: { icon: "solar:chat-round-dots-bold-duotone", label: "聊了聊今天" },
  call: { icon: "solar:phone-calling-rounded-bold-duotone", label: "见了一面" },
};

type MissYouState = "idle" | "sending" | "sent" | "recorded" | "error";

function togetherDaysFrom(anniversaries: Anniversary[]): number {
  const anniversary = anniversaries[0];
  if (!anniversary) return 0;
  return Math.max(
    0,
    Math.floor((Date.now() - new Date(anniversary.date).getTime()) / 86400000),
  );
}

function sameCalendarDay(left: Date, right: Date): boolean {
  return left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
}

function EditorialMembers({
  identities,
  me,
  partnerOnline,
}: {
  identities: Identity[];
  me: number;
  partnerOnline: boolean;
}) {
  return (
    <div className="editorial-members" aria-label="此刻的我们">
      {orderTreeMembers(identities, me).map((identity) => {
        const isMe = identity.slot === me;
        const online = isMe || partnerOnline;
        return (
          <article key={identity.slot} className={online ? "is-online" : ""}>
            <div className="editorial-member-avatar">
              <ProfileAvatar identity={identity} />
              <i aria-label={online ? "在线" : "离线"} />
            </div>
            <span>
              <strong>{identity.displayName}</strong>
              <small>
                {identity.status?.emoji && <b>{identity.status.emoji}</b>}
                {identity.status?.label || (online ? "现在在线" : "稍后回来")}
              </small>
            </span>
          </article>
        );
      })}
    </div>
  );
}

function StoryDialog({
  story,
  close,
}: {
  story: WeeklyMemory;
  close: () => void;
}) {
  return (
    <div className="editorial-dialog-backdrop" onClick={close}>
      <article
        className="editorial-dialog editorial-story-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="editorial-story-title"
        onClick={(event) => event.stopPropagation()}
      >
        <button type="button" className="editorial-dialog-close" onClick={close} aria-label="关闭">
          <Icon icon="solar:close-circle-bold" />
        </button>
        <p>{story.source === "ai" ? "AI 整理的共同周记" : "本周故事"}</p>
        <h2 id="editorial-story-title">{story.title}</h2>
        <blockquote>{story.summary}</blockquote>
        <footer>{weeklyMemoryLabel(story.weekKey)}</footer>
      </article>
    </div>
  );
}

function MomentDialog({
  moment,
  identities,
  me,
  close,
}: {
  moment: GrowthEvent;
  identities: Identity[];
  me: number;
  close: () => void;
}) {
  const meta = MOMENT_META[moment.eventType];
  return (
    <div className="editorial-dialog-backdrop" onClick={close}>
      <article
        className="editorial-dialog editorial-moment-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="editorial-moment-title"
        onClick={(event) => event.stopPropagation()}
      >
        <button type="button" className="editorial-dialog-close" onClick={close} aria-label="关闭">
          <Icon icon="solar:close-circle-bold" />
        </button>
        {moment.imageUrl && (
          <ZoomableImage src={mediaUrl(moment.imageUrl)} alt="这次共同记录的照片" />
        )}
        <p><Icon icon={meta.icon} />{meta.label}</p>
        <h2 id="editorial-moment-title">{moment.title}</h2>
        {moment.summary && <blockquote>{moment.summary}</blockquote>}
        <footer>
          {displayNameForSlot(identities, moment.slot, me)} · {new Date(moment.occurredAt).toLocaleDateString("zh-CN", {
            year: "numeric",
            month: "long",
            day: "numeric",
          })}
        </footer>
      </article>
    </div>
  );
}

export function HomePanel({
  albums,
  anniversaries,
  notes,
  openNote,
  sendMissYou,
  daily,
  me,
  openDaily,
  openView,
  identities,
  partnerOnline,
  tree,
}: {
  albums: AlbumItem[];
  anniversaries: Anniversary[];
  notes: LoveNote[];
  openNote: () => void;
  sendMissYou: () => Promise<{ wechatQueued: boolean }>;
  daily: DailyState | null;
  me: number;
  openDaily: () => void;
  openView?: (view: Extract<CottageView, "call" | "album" | "settings">) => void;
  identities: Identity[];
  partnerOnline: boolean;
  tree: TreeState | null;
}) {
  const [selectedMoment, setSelectedMoment] = useState<GrowthEvent | null>(null);
  const [openStory, setOpenStory] = useState<WeeklyMemory | null>(null);
  const [missYouState, setMissYouState] = useState<MissYouState>("idle");
  const cover = useMemo(() => selectEditorialCover(albums), [albums]);
  const moments = useMemo(() => selectEditorialMoments(tree?.events || []), [tree?.events]);
  const weeklyStories = useMemo(
    () => [...(tree?.weeklyMemories || [])].sort((left, right) => right.weekKey.localeCompare(left.weekKey)),
    [tree?.weeklyMemories],
  );
  const latestStory = useMemo(() => selectLatestWeeklyMemory(weeklyStories), [weeklyStories]);
  const rewindMoment = useMemo(() => selectRewindMoment(tree?.events || []), [tree?.events]);
  const togetherDays = tree?.togetherDays ?? togetherDaysFrom(anniversaries);
  const latestNote = useMemo(
    () => [...notes].sort((left, right) =>
      new Date(right.CreatedAt).getTime() - new Date(left.CreatedAt).getTime())[0] || null,
    [notes],
  );
  const pushRef = new URLSearchParams(location.search).get("push") || "";
  const pushedWeek = pushRef.startsWith("tree:") ? pushRef.replace("tree:", "") : "";

  useEffect(() => {
    if (!pushedWeek) return;
    const story = weeklyStories.find((item) => item.weekKey === pushedWeek);
    if (story) setOpenStory(story);
  }, [pushedWeek, weeklyStories]);

  const triggerMissYou = async () => {
    if (missYouState === "sending") return;
    setMissYouState("sending");
    try {
      const result = await sendMissYou();
      setMissYouState(result.wechatQueued ? "sent" : "recorded");
    } catch {
      setMissYouState("error");
    }
    window.setTimeout(() => setMissYouState("idle"), 2600);
  };

  const myReply = daily?.replies?.find((reply) => reply.slot === me);
  const dailyStatus = daily?.revealedAt
    ? "两封回信已经揭晓"
    : myReply?.submitted
    ? "已经写下，等待对方"
    : "写一封只在双方回答后打开的回信";
  const coverSummary = latestStory?.summary || editorialFallbackCopy(moments.length);
  const rewindIsToday = rewindMoment
    ? sameCalendarDay(new Date(rewindMoment.occurredAt), new Date())
      && new Date(rewindMoment.occurredAt).getFullYear() < new Date().getFullYear()
    : false;

  return (
    <main className="home-panel editorial-home">
      <section className={`editorial-cover ${cover ? "has-cover-photo" : "is-typographic"}`}>
        {cover && (
          <button type="button" className="editorial-cover-photo" onClick={() => openView?.("album")} aria-label="打开相册">
            <img src={mediaUrl(cover.imageUrl)} alt="本期封面照片" />
          </button>
        )}
        <div className="editorial-cover-wash" aria-hidden="true" />
        <header className="editorial-masthead">
          <span><b>US, LATELY.</b><small>最近的我们</small></span>
          <em>{editorialWeekLabel()}</em>
        </header>

        <div className="editorial-cover-copy">
          <p>LOVE COTTAGE · WEEKLY EDITION</p>
          <h1>把普通日子，<br />留在这一期。</h1>
          <blockquote>{coverSummary}</blockquote>
          <div className="editorial-cover-meta">
            <span><strong>{togetherDays || "—"}</strong><small>一起走过的日子</small></span>
            <i />
            <span><strong>{moments.length}</strong><small>最近收好的时刻</small></span>
          </div>
        </div>

        <EditorialMembers identities={identities} me={me} partnerOnline={partnerOnline} />
      </section>

      <section className="editorial-now" aria-label="今天与快捷操作">
        <button type="button" className="editorial-daily-card" onClick={openDaily}>
          <span><Icon icon="solar:letter-bold-duotone" />TODAY'S LETTER</span>
          <strong>{daily?.question || "今天的问题正在准备中…"}</strong>
          <small>{dailyStatus}<Icon icon="solar:arrow-right-bold" /></small>
        </button>

        <div className="editorial-actions">
          <button
            type="button"
            className={`editorial-miss-you state-${missYouState}`}
            onClick={() => void triggerMissYou()}
            disabled={missYouState === "sending"}
          >
            <Icon icon={missYouState === "sent" ? "solar:heart-shine-bold-duotone" : "solar:heart-angle-bold-duotone"} />
            <span>
              <b>{missYouState === "sending" ? "正在想你" : missYouState === "error" ? "再试一次" : missYouState === "sent" ? "已送达" : missYouState === "recorded" ? "已记下" : "想你了"}</b>
              <small>{missYouState === "sent" ? "微信提醒已排队" : missYouState === "recorded" ? "等 TA 下次进来" : "轻轻告诉 TA"}</small>
            </span>
          </button>
          <button type="button" onClick={openNote}>
            <Icon icon="solar:chat-round-heart-bold-duotone" /><span><b>留句话</b><small>写在这一期</small></span>
          </button>
          <button type="button" onClick={() => openView?.("call")}>
            <Icon icon="solar:phone-calling-rounded-bold-duotone" /><span><b>见一面</b><small>{partnerOnline ? "TA 正在线" : "发起连线"}</small></span>
          </button>
          <button type="button" onClick={() => openView?.("album")}>
            <Icon icon="solar:gallery-wide-bold-duotone" /><span><b>相册</b><small>收藏新照片</small></span>
          </button>
          <button type="button" onClick={() => openView?.("settings")}>
            <Icon icon="solar:settings-bold-duotone" /><span><b>设置</b><small>把小屋调舒服</small></span>
          </button>
        </div>
      </section>

      {latestNote && (
        <aside className="editorial-pull-quote">
          <Icon icon="solar:quote-up-bold-duotone" />
          <blockquote>“{latestNote.content}”</blockquote>
          <span>— {editorialMember(identities, latestNote.senderSlot)?.displayName || "我们"}</span>
        </aside>
      )}

      <section className="editorial-moments" aria-labelledby="editorial-moments-title">
        <header>
          <div><p>THE LATEST PAGES</p><h2 id="editorial-moments-title">最近收好的时刻</h2></div>
          <span>{moments.length ? `最近 ${moments.length} 则` : "等待第一则"}</span>
        </header>
        {moments.length ? (
          <div className="editorial-moment-grid">
            {moments.map((moment, index) => {
              const meta = MOMENT_META[moment.eventType];
              const contributor = editorialMember(identities, moment.slot);
              return (
                <button
                  type="button"
                  key={moment.ID}
                  className={`editorial-moment-card ${moment.imageUrl ? "has-image" : ""} card-${index + 1}`}
                  onClick={() => setSelectedMoment(moment)}
                >
                  {moment.imageUrl && <img src={mediaUrl(moment.imageUrl)} alt="" />}
                  <span className="editorial-moment-kind"><Icon icon={meta.icon} />{meta.label}</span>
                  <time dateTime={moment.occurredAt}>{new Date(moment.occurredAt).toLocaleDateString("zh-CN", { month: "short", day: "numeric" })}</time>
                  <strong>{moment.title}</strong>
                  {moment.summary && <small>{moment.summary}</small>}
                  <footer>{contributor?.displayName || "我们"}<Icon icon="solar:arrow-up-right-bold" /></footer>
                </button>
              );
            })}
          </div>
        ) : (
          <div className="editorial-empty">
            <Icon icon="solar:camera-add-bold-duotone" />
            <h3>这一期还留着空白。</h3>
            <p>写封回信、留句话，或者收藏第一张照片。</p>
            <button type="button" onClick={() => openView?.("album")}>从一张照片开始</button>
          </div>
        )}
      </section>

      <section className="editorial-archive" aria-label="共同故事与回看">
        <article className="editorial-weekly-stories">
          <header><p>OUR WEEKLY STORIES</p><h2>每周的一页</h2></header>
          {weeklyStories.length ? (
            <div>
              {weeklyStories.slice(0, 3).map((story, index) => (
                <button type="button" key={story.ID} onClick={() => setOpenStory(story)}>
                  <em>{String(index + 1).padStart(2, "0")}</em>
                  <span><b>{story.title}</b><small>{weeklyMemoryLabel(story.weekKey)}</small></span>
                  <Icon icon="solar:arrow-right-bold" />
                </button>
              ))}
            </div>
          ) : <p className="editorial-story-empty">第一篇共同周记，会在故事发生以后来到这里。</p>}
        </article>

        <article className="editorial-rewind">
          <header><p>REWIND</p><h2>{rewindIsToday ? "从前的今天" : "翻一页以前"}</h2></header>
          {rewindMoment ? (
            <button type="button" onClick={() => setSelectedMoment(rewindMoment)}>
              {rewindMoment.imageUrl
                ? <img src={mediaUrl(rewindMoment.imageUrl)} alt="过去的一张照片" />
                : <Icon icon={MOMENT_META[rewindMoment.eventType].icon} />}
              <span>
                <time>{new Date(rewindMoment.occurredAt).toLocaleDateString("zh-CN", { year: "numeric", month: "long", day: "numeric" })}</time>
                <b>{rewindMoment.title}</b>
              </span>
            </button>
          ) : <p>等有了更多故事，再一起翻回来看看。</p>}
        </article>
      </section>

      {selectedMoment && (
        <MomentDialog moment={selectedMoment} identities={identities} me={me} close={() => setSelectedMoment(null)} />
      )}
      {openStory && <StoryDialog story={openStory} close={() => setOpenStory(null)} />}
    </main>
  );
}
