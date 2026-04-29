import profile from "../data/profile.json";
import AnimatedProfile from "./components/animated-profile";

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

type GvaResponse = {
  code?: number;
  data?: {
    blog_config?: unknown;
  };
};

const fallbackProfile = profile as unknown as Record<string, unknown>;
const fallbackData: ProfileData = {
  ...(profile as Omit<ProfileData, "hobby">),
  hobby: Array.isArray(fallbackProfile.hobby)
    ? fallbackProfile.hobby.filter((item): item is string => typeof item === "string")
    : [],
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

  return {
    siteLabel: data.siteLabel,
    name: data.name,
    title: data.title,
    bio: data.bio,
    hobby: Array.isArray(data.hobby)
      ? data.hobby.filter((item): item is string => typeof item === "string")
      : [],
    tags: data.tags.filter((tag): tag is string => typeof tag === "string"),
    projects,
    contact: Object.fromEntries(contactEntries),
  };
}

async function getProfileData(): Promise<ProfileData> {
  const apiUrl =
    process.env.BLOG_PROFILE_API_URL ||
    "http://127.0.0.1:8888/api/bc/getUserBlog_configPublic";

  try {
    const res = await fetch(apiUrl, { cache: "no-store" });
    if (!res.ok) return fallbackData;

    const payload = (await res.json()) as GvaResponse;
    const raw = payload?.data?.blog_config;
    const parsed =
      typeof raw === "string" ? normalizeProfileData(JSON.parse(raw)) : normalizeProfileData(raw);

    return parsed || fallbackData;
  } catch {
    return fallbackData;
  }
}

export default async function Home() {
  const pageData = await getProfileData();
  return <AnimatedProfile profile={pageData} />;
}
