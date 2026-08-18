import {
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
  useCallback,
  useEffect,
  useRef,
  useState,
} from "react";
import "./qixi-story.css";

const PHOTO_BASE = "/qx/photos";
const photo = (name: string) => `${PHOTO_BASE}/${name}.webp`;

const SLIDE_TITLES = [
  "开场",
  "是你",
  "片段",
  "小屋",
  "日常",
  "以后",
  "情书",
] as const;

const PETALS = Array.from({ length: 18 }, (_, index) => ({
  left: `${(index * 37 + 11) % 100}%`,
  delay: `${-((index * 0.83) % 9)}s`,
  duration: `${8 + (index % 6) * 1.4}s`,
  size: `${5 + (index % 4) * 3}px`,
  drift: `${(index % 2 === 0 ? 1 : -1) * (30 + (index % 5) * 12)}px`,
}));

type PhotoCardProps = {
  src: string;
  alt: string;
  className?: string;
  label?: string;
};

function PhotoCard({ src, alt, className = "", label }: PhotoCardProps) {
  const [failed, setFailed] = useState(false);
  return (
    <figure className={`qx-photo ${className}${failed ? " qx-photo--failed" : ""}`}>
      {!failed && <img src={src} alt={alt} onError={() => setFailed(true)} />}
      {failed && <span className="qx-photo-fallback" aria-hidden="true">♥</span>}
      {label && <figcaption>{label}</figcaption>}
    </figure>
  );
}

export function QixiStory() {
  const [current, setCurrent] = useState(0);
  const [letterOpen, setLetterOpen] = useState(false);
  const touchStart = useRef<{ x: number; y: number } | null>(null);
  const wheelLocked = useRef(false);

  const goTo = useCallback((index: number) => {
    setCurrent(Math.max(0, Math.min(SLIDE_TITLES.length - 1, index)));
  }, []);
  const next = useCallback(() => goTo(current + 1), [current, goTo]);
  const previous = useCallback(() => goTo(current - 1), [current, goTo]);

  useEffect(() => {
    const previousDocumentTitle = document.title;
    document.title = "给郝雨诗的七夕放映会";
    document.documentElement.classList.add("qx-page-active");
    const themeColor = document.querySelector<HTMLMetaElement>('meta[name="theme-color"]');
    const oldThemeColor = themeColor?.content;
    if (themeColor) themeColor.content = "#250d19";
    return () => {
      document.title = previousDocumentTitle;
      document.documentElement.classList.remove("qx-page-active");
      if (themeColor && oldThemeColor) themeColor.content = oldThemeColor;
    };
  }, []);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "ArrowRight" || event.key === "ArrowDown" || event.key === " ") {
        event.preventDefault();
        next();
      } else if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
        event.preventDefault();
        previous();
      } else if (event.key === "Home") {
        event.preventDefault();
        goTo(0);
      } else if (event.key === "End") {
        event.preventDefault();
        goTo(SLIDE_TITLES.length - 1);
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [goTo, next, previous]);

  const handleWheel = (event: React.WheelEvent<HTMLElement>) => {
    if (wheelLocked.current || Math.abs(event.deltaY) < 26) return;
    wheelLocked.current = true;
    if (event.deltaY > 0) next();
    else previous();
    window.setTimeout(() => {
      wheelLocked.current = false;
    }, 700);
  };

  const handlePointerDown = (event: ReactPointerEvent<HTMLElement>) => {
    if (event.pointerType === "touch") {
      touchStart.current = { x: event.clientX, y: event.clientY };
    }
  };

  const handlePointerUp = (event: ReactPointerEvent<HTMLElement>) => {
    const start = touchStart.current;
    touchStart.current = null;
    if (!start || event.pointerType !== "touch") return;
    const deltaX = event.clientX - start.x;
    const deltaY = event.clientY - start.y;
    if (Math.abs(deltaX) > 52 && Math.abs(deltaX) > Math.abs(deltaY)) {
      if (deltaX < 0) next();
      else previous();
    }
  };

  return (
    <main
      className={`qx-story qx-story--slide-${current}`}
      onWheel={handleWheel}
      onPointerDown={handlePointerDown}
      onPointerUp={handlePointerUp}
    >
      <div className="qx-aurora" aria-hidden="true" />
      <div className="qx-stars" aria-hidden="true" />
      <div className="qx-petals" aria-hidden="true">
        {PETALS.map((petal, index) => (
          <i
            key={index}
            style={{
              "--left": petal.left,
              "--delay": petal.delay,
              "--duration": petal.duration,
              "--size": petal.size,
              "--drift": petal.drift,
            } as CSSProperties}
          />
        ))}
      </div>

      <header className="qx-topbar">
        <button className="qx-wordmark" onClick={() => goTo(0)} aria-label="回到开场">
          <span className="qx-wordmark-heart">♥</span>
          <span>LOVE COTTAGE</span>
          <em>七夕限定</em>
        </button>
        <div className="qx-page-count" aria-live="polite">
          <b>{String(current + 1).padStart(2, "0")}</b>
          <span>/ {String(SLIDE_TITLES.length).padStart(2, "0")}</span>
        </div>
      </header>

      <div
        className="qx-deck"
        style={{ transform: `translate3d(-${current * 100}vw, 0, 0)` }}
      >
        <section className="qx-slide qx-cover" aria-hidden={current !== 0}>
          <div className="qx-cover-copy qx-reveal">
            <p className="qx-kicker">A LITTLE FILM FOR MY FAVORITE GIRL</p>
            <h1>
              给郝雨诗的
              <span>七夕放映会</span>
            </h1>
            <p className="qx-lede">这一晚，星河是布景，而你是唯一的主角。</p>
            <button className="qx-primary-button" onClick={next}>
              <span>开始放映</span>
              <i aria-hidden="true">→</i>
            </button>
            <small className="qx-interaction-tip">点击 / 滑动 / 按方向键翻页</small>
          </div>
          <div className="qx-cover-visual qx-reveal qx-reveal--late">
            <div className="qx-orbit qx-orbit--one" aria-hidden="true" />
            <div className="qx-orbit qx-orbit--two" aria-hidden="true" />
            <PhotoCard src={photo("t7")} alt="小赵和郝雨诗的合照" className="qx-hero-photo" />
            <div className="qx-photo-note qx-note--top">YOU &amp; ME</div>
            <div className="qx-photo-note qx-note--bottom">今天也最喜欢你</div>
            <div className="qx-big-heart" aria-hidden="true">♥</div>
          </div>
        </section>

        <section className="qx-slide qx-you" aria-hidden={current !== 1}>
          <div className="qx-section-number qx-reveal">01</div>
          <div className="qx-you-copy qx-reveal">
            <p className="qx-kicker">THE ANSWER IS YOU</p>
            <h2>故事的答案，<br />一直都是<span>你</span>。</h2>
            <p>
              我常常想，一个人怎么会同时让日子变得热闹，
              又让心变得安定。后来我知道，答案就是你。
            </p>
            <blockquote>“你是郝雨诗，也是我的星河大王。”</blockquote>
          </div>
          <div className="qx-you-gallery qx-reveal qx-reveal--late">
            <PhotoCard src={photo("t2")} alt="郝雨诗戴着眼镜的照片" className="qx-you-photo qx-you-photo--one" />
            <PhotoCard src={photo("t6")} alt="郝雨诗旅行中的照片" className="qx-you-photo qx-you-photo--two" />
            <PhotoCard src={photo("t11")} alt="郝雨诗的可爱自拍" className="qx-you-photo qx-you-photo--three" />
            <span className="qx-handwritten">喜欢你的<br />每一种样子</span>
          </div>
        </section>

        <section className="qx-slide qx-moments" aria-hidden={current !== 2}>
          <div className="qx-moments-heading qx-reveal">
            <p className="qx-kicker">US, IN LITTLE MOMENTS</p>
            <h2>被我们牵住的，<br />不止是<span>手</span>。</h2>
            <p>是当时的风，是并肩的温度，也是我偷偷开心了很久的那些瞬间。</p>
          </div>
          <div className="qx-moment-strip qx-reveal qx-reveal--late">
            <PhotoCard src={photo("t1")} alt="戴着手表牵手的照片" label="靠近一点" />
            <PhotoCard src={photo("t3")} alt="光影里的牵手照片" label="再靠近一点" />
            <PhotoCard src={photo("t8")} alt="一起走在路上的牵手照片" label="一起走很远" />
            <PhotoCard src={photo("t12")} alt="日常里的牵手照片" label="就这样，不松手" />
          </div>
          <div className="qx-film-caption qx-reveal qx-reveal--latest">
            <span>LOVE ARCHIVE</span>
            <b>04 frames / countless memories</b>
          </div>
        </section>

        <section className="qx-slide qx-cottage" aria-hidden={current !== 3}>
          <div className="qx-cottage-scene qx-reveal">
            <div className="qx-moon" aria-hidden="true" />
            <img src="/app-icon.png" alt="爱情小屋 Logo" className="qx-cottage-logo" />
            <div className="qx-cottage-chip qx-chip--one"><b>聊天</b><span>今天也有好好说话</span></div>
            <div className="qx-cottage-chip qx-chip--two"><b>相册</b><span>把喜欢一张张存下</span></div>
            <div className="qx-cottage-chip qx-chip--three"><b>回信</b><span>认真回答彼此</span></div>
          </div>
          <div className="qx-cottage-copy qx-reveal qx-reveal--late">
            <p className="qx-kicker">A HOME BUILT WITH LOVE &amp; CODE</p>
            <h2>我把会写的代码，<br />都拿来给我们<span>安一个家</span>。</h2>
            <p>
              不是为了把爱变成一个产品，
              只是舍不得那些细小又珍贵的瞬间，被时间悄悄忘记。
            </p>
            <div className="qx-code-line"><span>const</span> forever = <b>"和你一起"</b>;</div>
          </div>
        </section>

        <section className="qx-slide qx-ordinary" aria-hidden={current !== 4}>
          <div className="qx-ordinary-copy qx-reveal">
            <p className="qx-kicker">THE ORDINARY DAYS</p>
            <h2>我最贪心的愿望，<br />是和你过很多<span>普通日子</span>。</h2>
            <p>
              一起吃饭、一起散步，各自忙碌以后还能说一声晚安。
              爱不必每一刻都盛大，但每一刻都可以有你。
            </p>
          </div>
          <div className="qx-ordinary-layout qx-reveal qx-reveal--late">
            <PhotoCard src={photo("t10")} alt="一起吃饭的生活照片" className="qx-wide-photo" />
            <PhotoCard src={photo("t4")} alt="夜晚散步时的照片" className="qx-tall-photo" />
            <div className="qx-ordinary-note">
              <span>愿望清单 · 001</span>
              <strong>一起吃很多顿饭，<br />走很多段路，<br />看很多次日落。</strong>
              <i>to be continued…</i>
            </div>
          </div>
        </section>

        <section className="qx-slide qx-future" aria-hidden={current !== 5}>
          <div className="qx-future-title qx-reveal">
            <p className="qx-kicker">MY PROMISES TO YOU</p>
            <h2>关于以后，<br />我想认真做到这些。</h2>
          </div>
          <div className="qx-promises qx-reveal qx-reveal--late">
            <article><span>01</span><h3>认真听你说话</h3><p>不只听见开心，也接住你的委屈。</p></article>
            <article><span>02</span><h3>生气也不撤回爱</h3><p>问题可以慢慢解决，喜欢不会被拿来惩罚你。</p></article>
            <article><span>03</span><h3>多留下合照</h3><p>不躲镜头，把每一岁的我们都好好收藏。</p></article>
            <article><span>04</span><h3>一直把你放进未来</h3><p>每一次计划下一站，身边的位置都留给你。</p></article>
          </div>
          <button className="qx-final-button qx-reveal qx-reveal--latest" onClick={next}>
            去看最后一页 <span>→</span>
          </button>
        </section>

        <section className={`qx-slide qx-letter${letterOpen ? " qx-letter--open" : ""}`} aria-hidden={current !== 6}>
          <div className="qx-letter-heading qx-reveal">
            <p className="qx-kicker">ONE LAST THING</p>
            <h2>最后一页，<br />只留给你。</h2>
          </div>
          <div className="qx-envelope-wrap qx-reveal qx-reveal--late">
            <div className="qx-heart-burst" aria-hidden="true">
              {Array.from({ length: 12 }, (_, index) => (
                <i key={index} style={{ "--i": index } as CSSProperties}>♥</i>
              ))}
            </div>
            <div className="qx-letter-paper">
              <p>郝雨诗：</p>
              <p><b>七夕快乐。</b></p>
              <p>
                遇见你以后，我才明白，喜欢不是偶尔想起，
                而是每一次计划未来时，都很自然地把你放进去。
              </p>
              <p>
                谢谢你来到我身边，也谢谢你愿意留在我的故事里。
                星河很大，但我最想奔赴的人，一直是你。
              </p>
              <p>往后的很多年，也请继续做我的星河大王。</p>
              <footer><span>爱你的</span><strong>小赵</strong><i>♥</i></footer>
            </div>
            <button
              className="qx-envelope"
              onClick={() => setLetterOpen(true)}
              aria-label="拆开写给郝雨诗的信"
              aria-expanded={letterOpen}
            >
              <span className="qx-envelope-flap" />
              <span className="qx-envelope-front" />
              <i>♥</i>
              <b>替我拆开</b>
            </button>
          </div>
          {letterOpen && (
            <button className="qx-replay" onClick={() => { setLetterOpen(false); goTo(0); }}>
              ↻ 再看一遍
            </button>
          )}
        </section>
      </div>

      <nav className="qx-controls" aria-label="幻灯片导航">
        <button onClick={previous} disabled={current === 0} aria-label="上一页">←</button>
        <div className="qx-progress">
          {SLIDE_TITLES.map((title, index) => (
            <button
              key={title}
              className={index === current ? "is-active" : ""}
              onClick={() => goTo(index)}
              aria-label={`第 ${index + 1} 页：${title}`}
              aria-current={index === current ? "step" : undefined}
            ><span /></button>
          ))}
        </div>
        <button onClick={next} disabled={current === SLIDE_TITLES.length - 1} aria-label="下一页">→</button>
      </nav>
    </main>
  );
}
