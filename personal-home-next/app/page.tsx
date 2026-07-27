import profile from "../data/profile.json";
import AnimatedProfile from "./components/animated-profile";

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
  hint?: string;
  hobby: string[];
  tags: string[];
  projects: Project[];
  play: PlayItem[];
  contact: Record<string, string>;
};

type BlogConfigResponse = {
  code?: number;
  data?: {
    blog_config?: unknown;
  } | null;
};

type MainImageResponse = {
  code?: number;
  data?: Array<{ url?: unknown; enabled?: unknown }>;
};

const fallbackProfile = profile as unknown as Record<string, unknown>;
const fallbackData: ProfileData = {
  ...(profile as Omit<ProfileData, "hobby">),
  hobby: Array.isArray(fallbackProfile.hobby)
    ? fallbackProfile.hobby.filter((item): item is string => typeof item === "string")
    : [],
  hint: typeof fallbackProfile.hint === "string" ? fallbackProfile.hint : undefined,
};

function normalizeProfileData(value: unknown): ProfileData | null {
  if (!value || typeof value !== "object") return null;
  const data = value as Partial<ProfileData>;
  if (
    typeof data.siteLabel !== "string" ||
    typeof data.name !== "string" ||
    typeof data.title !== "string" ||
    typeof data.bio !== "string" ||
    !Array.isArray(data.tags) ||
    !Array.isArray(data.projects) ||
    !data.contact ||
    typeof data.contact !== "object"
  ) {
    return null;
  }

  const contactRaw = data.contact as Record<string, unknown>;
  const contactEntries = Object.entries(contactRaw).filter(
    (entry): entry is [string, string] => typeof entry[0] === "string" && typeof entry[1] === "string"
  );
  if (contactEntries.length === 0) {
    return null;
  }

  const projects = data.projects
    .filter((project): project is Project => {
      if (!project || typeof project !== "object") return false;
      const p = project as Partial<Project>;
      return (
        typeof p.name === "string" &&
        typeof p.description === "string" &&
        typeof p.link === "string"
      );
    })
    .map((project) => ({
      name: project.name,
      description: project.description,
      link: project.link,
    }));

  const play = Array.isArray(data.play)
    ? data.play
        .filter((item): item is PlayItem => {
          if (!item || typeof item !== "object") return false;
          const p = item as Partial<PlayItem>;
          return (
            typeof p.name === "string" &&
            typeof p.description === "string" &&
            typeof p.link === "string"
          );
        })
        .map((item) => ({
          name: item.name,
          description: item.description,
          link: item.link,
        }))
    : [];

  return {
    siteLabel: data.siteLabel,
    name: data.name,
    title: data.title,
    bio: data.bio,
    hint: typeof data.hint === "string" ? data.hint : undefined,
    hobby: Array.isArray(data.hobby)
      ? data.hobby.filter((item): item is string => typeof item === "string")
      : [],
    tags: data.tags.filter((tag): tag is string => typeof tag === "string"),
    projects,
    play,
    contact: Object.fromEntries(contactEntries),
  };
}

function parseBlogConfig(raw: unknown): ProfileData | null {
  if (raw === undefined || raw === null || raw === "") return null;
  if (typeof raw === "string") {
    return normalizeProfileData(JSON.parse(raw));
  }
  return normalizeProfileData(raw);
}

function unwrapBlogConfigResponse(raw: unknown): unknown {
  if (!raw || typeof raw !== "object") return raw;
  const payload = raw as BlogConfigResponse;
  if (payload.data && typeof payload.data === "object" && "blog_config" in payload.data) {
    return payload.data.blog_config;
  }
  return raw;
}

async function getProfileData(): Promise<ProfileData> {
  const apiUrl =
    process.env.BLOG_PROFILE_API_URL ||
    "http://localhost:8000/api/v1/public/profile/active";

  console.log("[getProfileData] API_URL:", apiUrl);

  try {
    const res = await fetch(apiUrl, { cache: "no-store" });
    console.log("[getProfileData] fetch status:", res.status, res.statusText);
    if (!res.ok) {
      console.error("[getProfileData] fetch failed, fallback to local");
      return fallbackData;
    }

    const raw = unwrapBlogConfigResponse(await res.json());

    if (!raw || (typeof raw === "object" && Object.keys(raw).length === 0)) {
      console.warn("[getProfileData] empty content, fallback to local");
      return fallbackData;
    }

    const parsed = parseBlogConfig(raw);

    if (!parsed) {
      console.warn("[getProfileData] invalid blog_config shape, fallback to local");
      return fallbackData;
    }

    console.log("[getProfileData] using cloud data from home-backend");
    return parsed;
  } catch (err) {
    console.error("[getProfileData] exception:", err);
    return fallbackData;
  }
}

async function getMainImages(): Promise<string[]> {
  const profileApiUrl = process.env.BLOG_PROFILE_API_URL;
  const apiUrl = process.env.MAIN_IMAGE_API_URL ||
    (profileApiUrl
      ? profileApiUrl.replace(/\/bc\/getUserBlog_configPublic(?:\?.*)?$/, "/mainImage/public")
      : "http://127.0.0.1:8888/api/mainImage/public");

  try {
    const res = await fetch(apiUrl, { cache: "no-store" });
    if (!res.ok) return [];
    const payload = await res.json() as MainImageResponse;
    if (payload.code !== 0 || !Array.isArray(payload.data)) return [];
    return payload.data
      .filter((item) => item.enabled !== false && typeof item.url === "string" && item.url.trim() !== "")
      .map((item) => {
        const url = (item.url as string).trim();
        return url.startsWith("/") || url.includes("://") || url.startsWith("data:") ? url : `/${url}`;
      });
  } catch (err) {
    console.error("[getMainImages] exception:", err);
    return [];
  }
}

export default async function Home() {
  const [pageData, eggImages] = await Promise.all([getProfileData(), getMainImages()]);
  return <AnimatedProfile profile={pageData} eggImages={eggImages} />;
}
