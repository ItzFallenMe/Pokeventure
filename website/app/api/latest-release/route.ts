import { NextResponse } from "next/server";

import { LATEST_RELEASE_API } from "@/lib/releases";

export const revalidate = 300;

type GitHubAsset = {
  name: string;
  size: number;
  browser_download_url: string;
};

export async function GET() {
  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "User-Agent": "pokeventure-website",
  };
  if (process.env.GITHUB_TOKEN) {
    headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
  }

  try {
    const response = await fetch(LATEST_RELEASE_API, {
      headers,
      next: { revalidate: 300 },
    });

    if (response.status === 404) {
      return NextResponse.json({ release: null });
    }
    if (!response.ok) {
      return NextResponse.json(
        { error: "github_unavailable" },
        { status: 502 }
      );
    }

    const data = (await response.json()) as {
      tag_name: string;
      published_at: string;
      html_url: string;
      assets: GitHubAsset[];
    };

    return NextResponse.json(
      {
        release: {
          tag_name: data.tag_name,
          published_at: data.published_at,
          html_url: data.html_url,
          assets: data.assets
            .filter((asset) => asset.name.endsWith(".apk"))
            .map((asset) => ({
              name: asset.name,
              size: asset.size,
              browser_download_url: asset.browser_download_url,
            })),
        },
      },
      {
        headers: {
          "Cache-Control": "s-maxage=300, stale-while-revalidate=600",
        },
      }
    );
  } catch {
    return NextResponse.json(
      { error: "github_unavailable" },
      { status: 502 }
    );
  }
}
