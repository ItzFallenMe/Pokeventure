export const REPO_OWNER = "ItzFallenMe";
export const REPO_NAME = "Pokeventure";
export const REPO_URL = `https://github.com/${REPO_OWNER}/${REPO_NAME}`;
export const RELEASES_URL = `${REPO_URL}/releases`;
export const LATEST_RELEASE_API = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest`;

export type ReleaseAsset = {
  name: string;
  size: number;
  browser_download_url: string;
};

export type LatestRelease = {
  tag_name: string;
  published_at: string;
  html_url: string;
  assets: ReleaseAsset[];
};

export const APK_VARIANTS = [
  {
    asset: "pokeventure-universal.apk",
    title: "Universal",
    tag: "All devices",
    description: "One APK that works on every Android phone and tablet.",
    note: "Largest file",
  },
  {
    asset: "pokeventure-arm64-v8a.apk",
    title: "ARM64",
    tag: "arm64-v8a · armv8",
    description: "For most modern Android phones.",
    note: "Recommended",
  },
  {
    asset: "pokeventure-armeabi-v7a.apk",
    title: "ARMv7",
    tag: "armeabi-v7a · arm7",
    description: "For older 32-bit Android phones.",
    note: "Smaller",
  },
  {
    asset: "pokeventure-x86_64.apk",
    title: "x86_64",
    tag: "Emulators",
    description: "For Android emulators, Chromebooks and x86 tablets.",
    note: "Desktop-class",
  },
] as const;

export function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return "—";
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function formatDate(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}
