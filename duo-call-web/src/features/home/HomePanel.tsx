import { Icon } from "@iconify/react";
import { type CSSProperties, useEffect, useMemo, useState } from "react";
import { displayNameForSlot, treeEventLabel, treeLeafIcon } from "../../preferences";
import { mediaUrl, type AlbumItem, type Anniversary, type DailyState, type GrowthEvent, type Identity, type LoveNote, type TreeState, type WeeklyMemory } from "../../domain";
import { ProfileAvatar } from "../../components/ProfileAvatar";

export function SharedMemoryTree({
  tree,
  identities,
  me,
  partnerOnline,
  notes,
  openNote,
  togetherFallback,
}: {
  tree: TreeState | null;
  identities: Identity[];
  me: number;
  partnerOnline: boolean;
  notes: LoveNote[];
  openNote: () => void;
  togetherFallback: number;
}) {
  const eventLimit = {
    seed: 0,
    sprout: 1,
    sapling: 3,
    bloom: 4,
    canopy: 5,
  }[tree?.stage?.id || "seed"];
  const events = tree?.events?.slice(0, eventLimit) || [];
  const weekly = useMemo(() => tree?.weeklyMemories || [], [tree?.weeklyMemories]);
  const pushRef = new URLSearchParams(location.search).get("push") || "";
  const pushedWeek = pushRef.startsWith("tree:")
    ? pushRef.replace("tree:", "")
    : "";
  const [selected, setSelected] = useState<GrowthEvent | null>(null);
  const [openWeek, setOpenWeek] = useState<WeeklyMemory | null>(() =>
    weekly.find((item) => item.weekKey === pushedWeek) || null
  );
  useEffect(() => {
    if (!openWeek && pushedWeek) {
      const match = weekly.find((item) => item.weekKey === pushedWeek);
      if (match) setOpenWeek(match);
    }
  }, [openWeek, pushedWeek, weekly]);
  const stage = tree?.stage || {
    id: "seed",
    name: "一颗种子",
    message: "故事已经被轻轻种下",
    minimum: 0,
    next: 40,
    progress: 0,
  };
  const contributor = selected
    ? displayNameForSlot(identities, selected.slot, me)
    : "";
  const members = [...identities].sort((left, right) => left.slot - right.slot);
  const togetherDays = tree?.togetherDays ?? togetherFallback;
  return (
    <section className={`memory-tree stage-${stage.id}`} id="our-tree">
      <header className="tree-heading">
        <div>
          <p>OUR GROWING STORY</p>
          <h2>我们的树</h2>
          <span>{stage.message}</span>
        </div>
        <div className="tree-level">
          <strong>{stage.name}</strong>
          <small>{tree?.totalGrowth || 0} 点共同成长</small>
        </div>
      </header>
      <div className="tree-scene">
        <div className="tree-canvas">
          <div className="tree-glow" />
          <svg className="tree-art" viewBox="0 0 520 390" role="img" aria-label={`${stage.name}，${stage.message}`}>
            <defs>
              <linearGradient id="tree-trunk" x1="0" x2="1">
                <stop offset="0" stopColor="var(--tree-trunk-dark)" />
                <stop offset=".55" stopColor="var(--tree-trunk-light)" />
                <stop offset="1" stopColor="var(--tree-trunk-dark)" />
              </linearGradient>
              <linearGradient id="leaf-light" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0" stopColor="var(--tree-leaf-light)" />
                <stop offset="1" stopColor="var(--tree-leaf)" />
              </linearGradient>
            </defs>
            <ellipse className="tree-shadow" cx="260" cy="355" rx="176" ry="18" />
            <path className="tree-ground" d="M70 355c82-23 298-23 380 0-82 28-298 28-380 0Z" />
            {stage.id === "seed" && (
              <g className="tree-seed tree-stage-art">
                <ellipse cx="260" cy="338" rx="29" ry="17" />
                <path d="M260 329c-4-20 4-34 17-44" />
                <path className="seed-leaf" d="M275 286c-17-2-27 5-29 20 16 1 25-6 29-20Z" />
              </g>
            )}
            {stage.id === "sprout" && (
              <g className="tree-sprout tree-stage-art">
                <path className="sprout-stem" d="M260 346C258 319 258 291 263 267C267 246 273 231 281 218" />
                <path className="sprout-leaf leaf-left" d="M262 292C240 276 217 281 205 304C226 314 249 307 262 292Z" />
                <path className="sprout-leaf leaf-right" d="M265 268C284 248 309 249 326 268C308 284 283 282 265 268Z" />
                <path className="sprout-vein vein-left" d="M259 291C244 294 231 298 217 304" />
                <path className="sprout-vein vein-right" d="M268 267C286 267 299 268 314 270" />
              </g>
            )}
            {(stage.id === "sapling" || stage.id === "bloom" || stage.id === "canopy") && (
              <g className={`tree-plant tree-stage-art tree-${stage.id}`}>
                <g className="tree-canopy-masses" aria-hidden="true">
                  <circle className="canopy-mass canopy-mass-1" cx="174" cy="180" r="61" />
                  <circle className="canopy-mass canopy-mass-2" cx="218" cy="126" r="70" />
                  <circle className="canopy-mass canopy-mass-3" cx="286" cy="101" r="76" />
                  <circle className="canopy-mass canopy-mass-4" cx="352" cy="139" r="68" />
                  <circle className="canopy-mass canopy-mass-5" cx="306" cy="187" r="82" />
                  <circle className="canopy-mass canopy-mass-6" cx="236" cy="198" r="64" />
                </g>
                <path className="tree-trunk" d="M236 352c18-62 15-118 18-174 2-43 8-84 20-121 18 47 20 98 15 145-5 53-4 100 13 150Z" />
                <path className="tree-bark" d="M263 341c-1-62 8-113 4-165-2-31 1-61 7-91" />
                <path className="tree-branch branch-left-low" d="M262 238C229 208 195 192 154 186" />
                <path className="tree-branch branch-right-low" d="M274 222c33-37 67-56 111-63" />
                <path className="tree-branch branch-left-high" d="M268 170c-24-31-49-49-82-60" />
                <path className="tree-branch branch-right-high" d="M278 151c22-29 46-47 78-58" />
                <path className="tree-branch branch-top" d="M274 126c-2-31 3-56 17-79" />
                {stage.id === "sapling"
                  ? (
                    <g className="sapling-leaves">
                      {[
                        [165, 184, -18, 1],
                        [205, 132, 12, 0.9],
                        [251, 105, -26, 0.82],
                        [287, 75, 8, 0.9],
                        [333, 112, 164, 0.9],
                        [380, 164, 190, 1],
                        [226, 192, -8, 0.78],
                        [325, 184, 176, 0.8],
                        [273, 154, 16, 0.72],
                      ].map(([x, y, rotate, scale], index) => (
                        <g
                          className={`sapling-leaf sapling-leaf-${index + 1}`}
                          key={`${x}-${y}`}
                          transform={`translate(${x} ${y}) rotate(${rotate}) scale(${scale})`}
                        >
                          <path d="M0 0C-16-23-42-24-58-5C-43 13-17 14 0 0Z" />
                          <path className="leaf-vein" d="M-4-1C-20-4-35-5-50-5" />
                        </g>
                      ))}
                    </g>
                  )
                  : (
                    <g className="tree-foliage">
                      <ellipse className="foliage foliage-1" cx="167" cy="174" rx="66" ry="52" />
                      <ellipse className="foliage foliage-2" cx="216" cy="114" rx="73" ry="61" />
                      <ellipse className="foliage foliage-3" cx="288" cy="91" rx="77" ry="64" />
                      <ellipse className="foliage foliage-4" cx="360" cy="123" rx="72" ry="59" />
                      <ellipse className="foliage foliage-5" cx="390" cy="184" rx="61" ry="48" />
                      <ellipse className="foliage foliage-6" cx="285" cy="171" rx="94" ry="70" />
                      <ellipse className="foliage foliage-7" cx="229" cy="205" rx="70" ry="49" />
                      <ellipse className="foliage foliage-8" cx="337" cy="213" rx="69" ry="47" />
                    </g>
                  )}
                <g className="tree-blooms">
                  {[[171, 151], [215, 88], [282, 57], [353, 104], [388, 173], [249, 188], [322, 180], [294, 126]].map(([cx, cy]) => (
                    <g key={`${cx}-${cy}`} transform={`translate(${cx} ${cy})`}>
                      <circle cx="-6" cy="0" r="6" />
                      <circle cx="6" cy="0" r="6" />
                      <circle cx="0" cy="-6" r="6" />
                      <circle cx="0" cy="6" r="6" />
                      <circle className="bloom-heart" cx="0" cy="0" r="3.5" />
                    </g>
                  ))}
                </g>
              </g>
            )}
          </svg>
          <div className="memory-leaves">
            {events.map((event, index) => (
              <button
                type="button"
                className={`memory-leaf leaf-${index + 1}`}
                key={event.ID}
                onClick={() => setSelected(event)}
                aria-label={`打开${treeEventLabel(event.eventType)}：${event.title}`}
              >
                <i aria-hidden="true" />
                <Icon icon={treeLeafIcon(event.eventType)} />
                <b>{treeEventLabel(event.eventType)}</b>
                <span>+{event.growth}</span>
              </button>
            ))}
          </div>
        </div>
        <div className="tree-together" aria-label={`我们在一起 ${togetherDays} 天`}>
          <Icon icon="solar:heart-bold-duotone" />
          <strong>{togetherDays || "—"}</strong>
          <span>在一起的日子</span>
        </div>
        <div className="tree-members" aria-label="此刻的我们">
          {members.map((identity, index) => {
            const isMe = identity.slot === me;
            const online = isMe || partnerOnline;
            const memberNotes = notes
              .filter((item) => item.senderSlot === identity.slot)
              .slice(0, 4);
            return (
              <article
                key={identity.slot}
                className={`tree-member member-${index === 0 ? "left" : "right"} ${online ? "is-online" : ""}`}
              >
                {memberNotes.length > 0 && (
                  <div className="tree-note-stream" aria-label={`${identity.displayName}最近的留言`}>
                    {memberNotes.map((note, noteIndex) => (
                      <div
                        key={note.ID}
                        className="tree-note-bubble"
                        style={{ "--note-index": noteIndex } as CSSProperties}
                      >
                        <span>{note.content}</span>
                      </div>
                    ))}
                  </div>
                )}
                <div className="tree-member-avatar">
                  <ProfileAvatar identity={identity} />
                  <i aria-label={online ? "在线" : "离线"} />
                </div>
                <div className="tree-member-copy">
                  <strong>{identity.displayName}</strong>
                </div>
                {isMe && (
                  <div className="tree-member-actions">
                    <button type="button" onClick={openNote} aria-label="给 TA 留言" title="给 TA 留言">
                      <Icon icon="solar:chat-round-dots-bold" />
                    </button>
                  </div>
                )}
              </article>
            );
          })}
        </div>
      </div>
      <div className="tree-progress" aria-label={`成长进度 ${stage.progress}%`}>
        <span><i style={{ width: `${Math.max(3, stage.progress)}%` }} /></span>
        <small>
          {stage.next > stage.minimum
            ? `距离下一次变化还有 ${Math.max(0, stage.next - (tree?.totalGrowth || 0))} 点`
            : "每一片新叶，都会继续留在这里"}
        </small>
      </div>
      {weekly.length > 0 && (
        <div className="weekly-memories">
          <header><span>本周的我们</span><small>树替你们收好的周记</small></header>
          <div>
            {weekly.slice(0, 3).map((item) => (
              <button
                type="button"
                key={item.ID}
                className={item.weekKey === pushedWeek ? "from-push" : ""}
                onClick={() => setOpenWeek(item)}
              >
                <Icon icon="solar:book-2-bold-duotone" />
                <span><b>{item.title}</b><small>{item.weekKey.replace("-W", " · 第 ")} 周</small></span>
                <Icon icon="solar:arrow-right-bold" />
              </button>
            ))}
          </div>
        </div>
      )}
      {(selected || openWeek) && (
        <div className="memory-dialog-backdrop" onClick={() => { setSelected(null); setOpenWeek(null); }}>
          <article className="memory-dialog" role="dialog" aria-modal="true" aria-label="共同回忆" onClick={(event) => event.stopPropagation()}>
            <button className="memory-dialog-close" type="button" onClick={() => { setSelected(null); setOpenWeek(null); }} aria-label="关闭">
              <Icon icon="solar:close-circle-bold" />
            </button>
            {selected
              ? (
                <>
                  {selected.imageUrl && <img src={mediaUrl(selected.imageUrl)} alt="这片叶子收藏的照片" />}
                  <span><Icon icon={treeLeafIcon(selected.eventType)} />{treeEventLabel(selected.eventType)}</span>
                  <h3>{selected.title}</h3>
                  <p>{selected.summary}</p>
                  <footer>{contributor} · {new Date(selected.occurredAt).toLocaleDateString("zh-CN", { year: "numeric", month: "long", day: "numeric" })}</footer>
                </>
              )
              : openWeek
              ? (
                <>
                  <span><Icon icon="solar:stars-bold-duotone" />{openWeek.source === "ai" ? "AI 整理的共同周记" : "共同周记"}</span>
                  <h3>{openWeek.title}</h3>
                  <p>{openWeek.summary}</p>
                  <footer>{openWeek.weekKey.replace("-W", " · 第 ")} 周</footer>
                </>
              )
              : null}
          </article>
        </div>
      )}
    </section>
  );
}

export function HomePanel({
  albums,
  anniversaries,
  notes,
  openNote,
  daily,
  me,
  openDaily,
  identities,
  partnerOnline,
  tree,
}: {
  albums: AlbumItem[];
  anniversaries: Anniversary[];
  notes: LoveNote[];
  openNote: () => void;
  daily: DailyState | null;
  me: number;
  openDaily: () => void;
  identities: Identity[];
  partnerOnline: boolean;
  tree: TreeState | null;
}) {
  const [slide, setSlide] = useState(0);
  const anniversary = anniversaries[0];
  useEffect(() => {
    setSlide(0);
  }, [albums.length]);
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
        <h1>把普通日子，<br />过成我们的收藏。</h1>
        <span>两个人的私密角落 · 今天也有好好想念</span>
      </header>
      <SharedMemoryTree
        tree={tree}
        identities={identities}
        me={me}
        partnerOnline={partnerOnline}
        notes={notes}
        openNote={openNote}
        togetherFallback={days}
      />
      <section className="home-dashboard">
        <article className="home-moment deck-carousel">
          <div className="moment-art" key={albums[slide]?.ID || "empty"}>
            {albums.length
              ? <img src={mediaUrl(albums[slide].imageUrl)} alt="我们的相册照片" />
              : (
                <>
                  <Icon icon="solar:gallery-wide-bold-duotone" />
                  <i />
                  <b>我们的小瞬间</b>
                </>
              )}
          </div>
          {albums.length > 0 && (
            <small className="moment-caption">
              {displayNameForSlot(
                identities,
                albums[slide].uploaderSlot,
                me,
              )} · {new Date(albums[slide].uploadedAt).toLocaleDateString("zh-CN")}
            </small>
          )}
          {albums.length > 1 && (
            <div className="carousel-controls" onClick={(event) => event.stopPropagation()}>
              <button
                type="button"
                onClick={() =>
                  setSlide((current) =>
                    (current - 1 + albums.length) % albums.length)}
                aria-label="上一张照片"
              >
                <Icon icon="solar:alt-arrow-left-bold" />
              </button>
              <div className="carousel-dots">
                {albums.map((album, index) => (
                  <button
                    type="button"
                    key={album.ID}
                    className={index === slide ? "active" : ""}
                    onClick={() => setSlide(index)}
                    aria-label={`查看第 ${index + 1} 张照片`}
                  />
                ))}
              </div>
              <button
                type="button"
                onClick={() =>
                  setSlide((current) => (current + 1) % albums.length)}
                aria-label="下一张照片"
              >
                <Icon icon="solar:alt-arrow-right-bold" />
              </button>
            </div>
          )}
        </article>
        <button className="daily-home-entry" onClick={openDaily}>
        <span>
          <Icon icon="solar:letter-bold-duotone" />
          <small>今日回信 · {daily?.source === "ai" ? "AI 为你们准备" : "温柔题库"}</small>
        </span>
        <strong>{daily?.question || "今天的问题正在准备中…"}</strong>
        <em>
          {daily?.revealedAt
            ? "两封回信已经揭晓"
            : daily?.replies?.find((reply) => reply.slot === me)?.submitted
            ? "已写下，等待对方"
            : "写一封只在双方回答后打开的回信"}
          <Icon icon="solar:arrow-right-bold" />
        </em>
        </button>
      </section>
    </main>
  );
}
