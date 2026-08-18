import { Icon } from "@iconify/react";
import type { Theme } from "../preferences";

export const themes: { id: Theme; label: string; icon: string }[] = [
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

export function ThemeDecorations({ theme }: { theme: Theme }) {
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

export function ThemePicker({
  theme,
  setTheme,
  compact = false,
}: {
  theme: Theme;
  setTheme: (value: Theme) => void;
  compact?: boolean;
}) {
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
