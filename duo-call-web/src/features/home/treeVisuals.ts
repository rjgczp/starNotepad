import type { Anniversary, TreeState } from "../../domain";

export type GrowthStageId = TreeState["stage"]["id"];
export type TreeSeason = "spring" | "summer" | "autumn" | "winter";
export type TreeFestival = "anniversary" | "valentine" | "qixi";

export type TreeVisualTheme =
  | { mode: TreeSeason; label: string; occasion: null }
  | { mode: "festival"; label: string; occasion: TreeFestival };

export type TreeEventAnchor = { x: number; y: number; glow: string };

export const treeThemeModes = ["spring", "summer", "autumn", "winter", "festival"] as const;

export const treeEventAnchorsByStage: Record<GrowthStageId, readonly TreeEventAnchor[]> = {
  seed: [],
  sprout: [{ x: 360, y: 205, glow: "#a5d96e" }],
  sapling: [
    { x: 72, y: 122, glow: "#91c85b" },
    { x: 448, y: 146, glow: "#f197aa" },
    { x: 258, y: 34, glow: "#f2c36d" },
  ],
  bloom: [
    { x: 66, y: 108, glow: "#91c85b" },
    { x: 454, y: 132, glow: "#f197aa" },
    { x: 76, y: 270, glow: "#eb596c" },
    { x: 444, y: 266, glow: "#f2c36d" },
  ],
  canopy: [
    { x: 58, y: 104, glow: "#91c85b" },
    { x: 462, y: 122, glow: "#f197aa" },
    { x: 64, y: 268, glow: "#eb596c" },
    { x: 456, y: 274, glow: "#f2c36d" },
    { x: 258, y: 28, glow: "#e58bb7" },
  ],
};

const qixiDates: Record<number, string> = {
  2024: "08-10",
  2025: "08-29",
  2026: "08-19",
  2027: "08-08",
  2028: "08-26",
  2029: "08-16",
  2030: "08-07",
};

function monthDay(date: Date) {
  return `${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

function sameMonthDay(left: Date, right: Date) {
  return left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
}

function seasonForMonth(month: number): TreeSeason {
  if (month >= 2 && month <= 4) return "spring";
  if (month >= 5 && month <= 7) return "summer";
  if (month >= 8 && month <= 10) return "autumn";
  return "winter";
}

export function treeVisualThemeForDate(
  date: Date,
  anniversaries: Pick<Anniversary, "date" | "enabled" | "title">[] = [],
): TreeVisualTheme {
  const anniversary = anniversaries.find((item) => {
    if (!item.enabled) return false;
    const anniversaryDate = new Date(item.date);
    return !Number.isNaN(anniversaryDate.getTime()) && sameMonthDay(date, anniversaryDate);
  });
  if (anniversary) {
    return { mode: "festival", occasion: "anniversary", label: anniversary.title || "纪念日" };
  }

  if (monthDay(date) === "02-14") {
    return { mode: "festival", occasion: "valentine", label: "情人节" };
  }

  const qixiDay = qixiDates[date.getFullYear()] || "08-07";
  if (monthDay(date) === qixiDay) {
    return { mode: "festival", occasion: "qixi", label: "七夕" };
  }

  const season = seasonForMonth(date.getMonth());
  return {
    mode: season,
    occasion: null,
    label: { spring: "春日", summer: "盛夏", autumn: "秋日", winter: "冬日" }[season],
  };
}

export const treeStageThemeVariants: Record<GrowthStageId, Record<(typeof treeThemeModes)[number], string>> = {
  seed: {
    spring: "seed-spring",
    summer: "seed-summer",
    autumn: "seed-autumn",
    winter: "seed-winter",
    festival: "seed-festival",
  },
  sprout: {
    spring: "sprout-spring",
    summer: "sprout-summer",
    autumn: "sprout-autumn",
    winter: "sprout-winter",
    festival: "sprout-festival",
  },
  sapling: {
    spring: "sapling-spring",
    summer: "sapling-summer",
    autumn: "sapling-autumn",
    winter: "sapling-winter",
    festival: "sapling-festival",
  },
  bloom: {
    spring: "bloom-spring",
    summer: "bloom-summer",
    autumn: "bloom-autumn",
    winter: "bloom-winter",
    festival: "bloom-festival",
  },
  canopy: {
    spring: "canopy-spring",
    summer: "canopy-summer",
    autumn: "canopy-autumn",
    winter: "canopy-winter",
    festival: "canopy-festival",
  },
};
