"use client";

import { useEffect, useState } from "react";
import type { LucideIcon } from "lucide-react";
import {
  Cpu,
  Download,
  ExternalLink,
  Monitor,
  Package,
  Smartphone,
} from "lucide-react";

import { cn } from "@/lib/utils";
import {
  APK_VARIANTS,
  formatBytes,
  formatDate,
  RELEASES_URL,
  type LatestRelease,
} from "@/lib/releases";

type DownloadState =
  | { status: "loading" }
  | { status: "ready"; release: LatestRelease }
  | { status: "empty" }
  | { status: "error" };

const ICONS: LucideIcon[] = [Package, Smartphone, Cpu, Monitor];

export function DownloadRelease() {
  const [state, setState] = useState<DownloadState>({ status: "loading" });

  useEffect(() => {
    const controller = new AbortController();

    async function load() {
      try {
        const response = await fetch("/api/latest-release", {
          signal: controller.signal,
          cache: "no-store",
        });
        if (!response.ok) throw new Error("Release lookup failed");
        const data = (await response.json()) as {
          release: LatestRelease | null;
        };
        if (data.release) {
          setState({ status: "ready", release: data.release });
        } else {
          setState({ status: "empty" });
        }
      } catch (error) {
        if ((error as Error).name === "AbortError") return;
        setState({ status: "error" });
      }
    }

    load();
    return () => controller.abort();
  }, []);

  if (state.status === "loading") {
    return (
      <div className="grid gap-4 sm:grid-cols-2">
        {APK_VARIANTS.map((variant) => (
          <div
            key={variant.asset}
            className="h-44 animate-pulse rounded-[1.5rem] border border-white/10 bg-white/[0.03]"
          />
        ))}
      </div>
    );
  }

  if (state.status === "error" || state.status === "empty") {
    return (
      <div className="rounded-[1.5rem] border border-white/10 bg-white/[0.03] p-8 text-center">
        <Package className="mx-auto h-8 w-8 text-red-400" />
        <h3 className="mt-4 font-outfit text-xl font-bold text-white">
          {state.status === "empty"
            ? "The first release is being prepared"
            : "Could not load the latest release"}
        </h3>
        <p className="mx-auto mt-2 max-w-md text-sm leading-relaxed text-slate-400">
          {state.status === "empty"
            ? "The APK will appear here as soon as the first GitHub release is published."
            : "GitHub did not answer the release lookup. You can still download any published build directly."}
        </p>
        <a
          href={RELEASES_URL}
          target="_blank"
          rel="noreferrer"
          className="mt-6 inline-flex items-center gap-2 rounded-full border border-white/15 px-5 py-2.5 text-xs font-black uppercase tracking-[0.16em] text-white transition-colors hover:bg-white/10"
        >
          Open GitHub releases
          <ExternalLink className="h-3.5 w-3.5" />
        </a>
      </div>
    );
  }

  const { release } = state;

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <span className="rounded-full border border-emerald-400/20 bg-emerald-400/10 px-3 py-1 text-[9px] font-black uppercase tracking-[0.2em] text-emerald-300">
            Latest release
          </span>
          <span className="font-outfit text-sm font-bold text-white">
            {release.tag_name}
          </span>
          <span className="text-xs text-slate-500">
            {formatDate(release.published_at)}
          </span>
        </div>
        <a
          href={release.html_url}
          target="_blank"
          rel="noreferrer"
          className="flex items-center gap-1.5 text-[10px] font-black uppercase tracking-[0.18em] text-slate-500 transition-colors hover:text-white"
        >
          Release notes
          <ExternalLink className="h-3 w-3" />
        </a>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        {APK_VARIANTS.map((variant, index) => {
          const asset = release.assets.find(
            (candidate) => candidate.name === variant.asset
          );
          const Icon = ICONS[index] ?? Package;

          if (!asset) {
            return (
              <div
                key={variant.asset}
                className="rounded-[1.5rem] border border-white/[0.06] bg-white/[0.015] p-5 opacity-55"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/10 bg-white/[0.04]">
                      <Icon className="h-5 w-5 text-slate-400" />
                    </span>
                    <div>
                      <p className="font-outfit text-base font-bold text-white">
                        {variant.title}
                      </p>
                      <p className="text-[10px] uppercase tracking-[0.16em] text-slate-500">
                        {variant.tag}
                      </p>
                    </div>
                  </div>
                  <span className="rounded-full bg-white/[0.04] px-2.5 py-1 text-[9px] font-bold uppercase tracking-wider text-slate-500">
                    Missing
                  </span>
                </div>
                <p className="mt-4 text-xs leading-relaxed text-slate-500">
                  Not included in this release.
                </p>
              </div>
            );
          }

          return (
            <a
              key={variant.asset}
              href={asset.browser_download_url}
              className="group relative overflow-hidden rounded-[1.5rem] border border-white/10 bg-white/[0.03] p-5 transition-all duration-300 hover:-translate-y-0.5 hover:border-red-400/40 hover:bg-white/[0.055]"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-center gap-3">
                  <span className="flex h-10 w-10 items-center justify-center rounded-xl border border-red-400/20 bg-red-500/10">
                    <Icon className="h-5 w-5 text-red-300" />
                  </span>
                  <div>
                    <p className="font-outfit text-base font-bold text-white">
                      {variant.title}
                    </p>
                    <p className="text-[10px] uppercase tracking-[0.16em] text-slate-500">
                      {variant.tag}
                    </p>
                  </div>
                </div>
                <span className="rounded-full border border-white/10 bg-white/[0.04] px-2.5 py-1 text-[9px] font-bold uppercase tracking-wider text-slate-400">
                  {variant.note}
                </span>
              </div>

              <p className="mt-4 text-xs leading-relaxed text-slate-400">
                {variant.description}
              </p>

              <div className="mt-5 flex items-center justify-between border-t border-white/[0.07] pt-3">
                <span className="font-mono text-[10px] text-slate-500">
                  {asset.name} · {formatBytes(asset.size)}
                </span>
                <span className="flex items-center gap-1.5 text-[10px] font-black uppercase tracking-[0.16em] text-red-300 transition-transform group-hover:translate-x-0.5">
                  Download
                  <Download className="h-3.5 w-3.5" />
                </span>
              </div>
            </a>
          );
        })}
      </div>

      <p
        className={cn(
          "mt-5 text-center text-[11px] leading-relaxed text-slate-500"
        )}
      >
        Allow installs from your browser when Android asks. The current APKs
        are debug-signed; back up local progress before switching builds.
      </p>
    </div>
  );
}
