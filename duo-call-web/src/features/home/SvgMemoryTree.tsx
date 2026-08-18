import { useId } from "react";
import type { GrowthEvent, TreeState } from "../../domain";
import { treeEventAnchorsByStage, treeStageThemeVariants, type TreeVisualTheme } from "./treeVisuals";
import loveTreeSeed from "../../assets/tree-stages/love-tree-seed.png";
import loveTreeSprout from "../../assets/tree-stages/love-tree-sprout.png";
import loveTreeInLove from "../../assets/tree-stages/love-tree-in-love.png";
import loveTreeBloom from "../../assets/tree-stages/love-tree-bloom.png";
import loveTreeCanopy from "../../assets/tree-stages/love-tree-canopy.png";
import loveMemoryHeartGreen from "../../assets/tree-stages/love-memory-heart-green.png";
import loveMemoryHeartLightGreen from "../../assets/tree-stages/love-memory-heart-light-green.png";
import loveMemoryHeartPink from "../../assets/tree-stages/love-memory-heart-pink.png";
import loveMemoryHeartLightPink from "../../assets/tree-stages/love-memory-heart-light-pink.png";
import loveMemoryHeartRed from "../../assets/tree-stages/love-memory-heart-red.png";

type GrowthStage = TreeState["stage"]["id"];

type StageTreeAsset = {
  src: string;
  label: string;
  x: number;
  y: number;
  width: number;
  height: number;
};

type SvgMemoryTreeProps = {
  events: GrowthEvent[];
  stage: GrowthStage;
  theme: TreeVisualTheme;
  hoveredId: number | null;
  onHover: (eventId: number | null) => void;
  onSelect: (event: GrowthEvent) => void;
};

const stageTreeAssets: Record<GrowthStage, StageTreeAsset> = {
  seed: {
    src: loveTreeSeed,
    label: "土壤幼苗",
    x: 182,
    y: 199,
    width: 156,
    height: 144,
  },
  sprout: {
    src: loveTreeSprout,
    label: "相遇后长高的小树",
    x: 167,
    y: 57,
    width: 186,
    height: 272,
  },
  sapling: {
    src: loveTreeInLove,
    label: "热恋心叶树",
    x: 117,
    y: -5,
    width: 286,
    height: 381,
  },
  bloom: {
    src: loveTreeBloom,
    label: "陪伴花树",
    x: 130,
    y: 13,
    width: 260,
    height: 337,
  },
  canopy: {
    src: loveTreeCanopy,
    label: "相守双干心愿树",
    x: 101,
    y: 7,
    width: 318,
    height: 333,
  },
};

const memoryHeartAssets = [
  { label: "青绿记忆果实", src: loveMemoryHeartGreen },
  { label: "嫩绿记忆果实", src: loveMemoryHeartLightGreen },
  { label: "粉色记忆果实", src: loveMemoryHeartPink },
  { label: "浅粉记忆果实", src: loveMemoryHeartLightPink },
  { label: "红色记忆果实", src: loveMemoryHeartRed },
] as const;

const stageEventLimit: Record<GrowthStage, number> = {
  seed: 0,
  sprout: 1,
  sapling: 3,
  bloom: 4,
  canopy: 5,
};

const stageLabels: Record<GrowthStage, string> = {
  seed: "相遇",
  sprout: "心动",
  sapling: "热恋",
  bloom: "陪伴",
  canopy: "相守",
};

const eventLabels: Record<GrowthEvent["eventType"], string> = {
  daily_reply: "一封回信",
  album: "一张照片",
  note: "一句心里话",
  chat: "今天的聊天",
  call: "一次见面",
};

function Blossom({ x, y, color }: { x: number; y: number; color: string }) {
  return (
    <g transform={`translate(${x} ${y})`}>
      <circle cx="-4" cy="0" r="4" fill={color} />
      <circle cx="4" cy="0" r="4" fill={color} />
      <circle cx="0" cy="-4" r="4" fill={color} />
      <circle cx="0" cy="4" r="4" fill={color} />
      <circle r="2.5" fill="#f7d98b" />
    </g>
  );
}

function SeasonalDecor({ theme }: { theme: TreeVisualTheme }) {
  if (theme.mode === "spring") {
    return (
      <g className="tree-seasonal-decor tree-seasonal-spring" aria-hidden="true">
        <Blossom x={76} y={74} color="#f3a6b4" />
        <Blossom x={443} y={88} color="#f6c0ca" />
        <Blossom x={92} y={292} color="#f3a6b4" />
        <Blossom x={431} y={286} color="#f6c0ca" />
      </g>
    );
  }

  if (theme.mode === "summer") {
    return (
      <g className="tree-seasonal-decor tree-seasonal-summer" aria-hidden="true">
        <circle cx="66" cy="92" r="3" />
        <circle cx="454" cy="112" r="2.5" />
        <circle cx="90" cy="252" r="2" />
        <circle cx="438" cy="246" r="3" />
        <circle cx="258" cy="20" r="2.5" />
      </g>
    );
  }

  if (theme.mode === "autumn") {
    return (
      <g className="tree-seasonal-decor tree-seasonal-autumn" aria-hidden="true">
        <path d="M 75 84 C 90 70, 101 80, 91 94 C 84 101, 76 96, 75 84 Z" />
        <path d="M 438 96 C 452 81, 465 91, 455 105 C 447 111, 440 106, 438 96 Z" />
        <path d="M 72 252 C 86 239, 98 250, 87 264 C 79 270, 73 265, 72 252 Z" />
        <path d="M 445 260 C 459 246, 471 257, 460 271 C 452 277, 446 271, 445 260 Z" />
      </g>
    );
  }

  if (theme.mode === "winter") {
    return (
      <g className="tree-seasonal-decor tree-seasonal-winter" aria-hidden="true">
        <circle cx="66" cy="80" r="4" />
        <circle cx="455" cy="104" r="3" />
        <circle cx="78" cy="248" r="3" />
        <circle cx="444" cy="268" r="4" />
        <circle cx="258" cy="24" r="3" />
      </g>
    );
  }

  return (
    <g className={`tree-seasonal-decor tree-seasonal-festival occasion-${theme.occasion}`} aria-hidden="true">
      <path className="tree-festival-ribbon" d="M 66 84 C 112 46, 145 47, 176 71" />
      <path className="tree-festival-ribbon" d="M 344 71 C 376 46, 410 48, 454 84" />
      {theme.occasion === "qixi" ? (
        <>
          <path d="M 67 98 l 4 8 9 1 -7 6 2 9 -8 -4 -8 4 2 -9 -7 -6 9 -1 Z" />
          <path d="M 454 98 l 4 8 9 1 -7 6 2 9 -8 -4 -8 4 2 -9 -7 -6 9 -1 Z" />
        </>
      ) : (
        <>
          <path d="M 67 92 C 57 82, 47 96, 67 108 C 87 96, 77 82, 67 92 Z" />
          <path d="M 454 92 C 444 82, 434 96, 454 108 C 474 96, 464 82, 454 92 Z" />
        </>
      )}
    </g>
  );
}

function Crown({ stage, theme }: { stage: GrowthStage; theme: TreeVisualTheme }) {
  const artwork = stageTreeAssets[stage];
  const themeClass = `tree-theme-${theme.mode}${theme.occasion ? ` occasion-${theme.occasion}` : ""}`;

  return (
    <g className="svg-tree-crown-layer" aria-hidden="true">
      <image
        aria-hidden="true"
        className={`svg-tree-asset svg-tree-complete stage-art-${stage} tree-stage-illustration ${themeClass}`}
        href={artwork.src}
        x={artwork.x}
        y={artwork.y}
        width={artwork.width}
        height={artwork.height}
        preserveAspectRatio="none"
        data-asset-label={artwork.label}
      />
    </g>
  );
}

function TreeArtwork({ stage, theme }: { stage: GrowthStage; theme: TreeVisualTheme }) {
  return (
    <g className={`svg-tree-artwork artwork-${stage}`} aria-hidden="true">
      <Crown stage={stage} theme={theme} />
      <SeasonalDecor theme={theme} />
    </g>
  );
}

export function SvgMemoryTree({
  events,
  stage,
  theme,
  hoveredId,
  onHover,
  onSelect,
}: SvgMemoryTreeProps) {
  const titleId = useId();
  const descriptionId = useId();
  const anchors = treeEventAnchorsByStage[stage];
  const variantId = treeStageThemeVariants[stage][theme.mode];
  const visibleEvents = events.slice(0, stageEventLimit[stage]).slice(0, anchors.length);

  return (
    <div
      className={`svg-memory-tree tree-theme-${theme.mode} tree-variant-${variantId}${theme.occasion ? ` occasion-${theme.occasion}` : ""}`}
      data-tree-theme={theme.mode}
      data-tree-occasion={theme.occasion || undefined}
      data-tree-variant={variantId}
    >
      <svg
        viewBox="0 0 520 400"
        role="group"
        aria-labelledby={`${titleId} ${descriptionId}`}
        preserveAspectRatio="xMidYMid meet"
      >
        <title id={titleId}>{stageLabels[stage]}阶段的共同记忆树</title>
        <desc id={descriptionId}>
          最近的互动化作枝头记忆果实。使用 Tab 聚焦果实，按回车或空格查看共同回忆。
        </desc>
        <TreeArtwork stage={stage} theme={theme} />
        <g aria-label="最近的共同互动">
          {visibleEvents.map((event, index) => {
            const anchor = anchors[index];
            const heartAsset = memoryHeartAssets[index];
            const isActive = hoveredId === event.ID;
            const accessibleLabel = `${eventLabels[event.eventType]}：${event.title}，共同成长 ${event.growth} 点`;
            return (
              <g
                key={event.ID}
                className={`svg-memory-fruit ${isActive ? "is-active" : ""}`}
                transform={`translate(${anchor.x} ${anchor.y})`}
                role="button"
                tabIndex={0}
                focusable="true"
                aria-label={accessibleLabel}
                onPointerEnter={() => onHover(event.ID)}
                onPointerLeave={() => onHover(null)}
                onFocus={() => onHover(event.ID)}
                onBlur={() => onHover(null)}
                onClick={() => onSelect(event)}
                onKeyDown={(keyboardEvent) => {
                  if (keyboardEvent.key !== "Enter" && keyboardEvent.key !== " ") return;
                  keyboardEvent.preventDefault();
                  onSelect(event);
                }}
              >
                <title>{accessibleLabel}</title>
                <path className="svg-memory-fruit-stem" d="M 0 -6 C -2 2, 2 8, 0 15" />
                <circle
                  className="svg-memory-fruit-halo"
                  cx="0"
                  cy="31"
                  r={isActive ? 29 : 24}
                  style={{ fill: anchor.glow }}
                />
                <image
                  aria-hidden="true"
                  className="svg-tree-memory-heart"
                  href={heartAsset.src}
                  x="-21"
                  y="12"
                  width="42"
                  height="44"
                  preserveAspectRatio="xMidYMid meet"
                  data-asset-label={heartAsset.label}
                />
                <circle className="svg-memory-fruit-hit" cx="0" cy="29" r="31" />
              </g>
            );
          })}
        </g>
      </svg>
      <span className="svg-memory-tree-keyboard-controls">
        记忆果实可使用 Tab 聚焦，并通过回车或空格打开。
      </span>
    </div>
  );
}
