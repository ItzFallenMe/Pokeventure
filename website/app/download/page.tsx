import Link from "next/link";
import { ArrowLeft, ShieldCheck, Smartphone, Sparkles } from "lucide-react";

import { DownloadRelease } from "@/components/download-release";
import { SiteFooter } from "@/components/site-footer";
import { SiteNav } from "@/components/site-nav";

const INSTALL_STEPS = [
  "Download the APK that matches your phone.",
  "Open the file and allow installs from your browser when Android asks.",
  "Launch Pokéventure, pick a starter and begin.",
];

export default function DownloadPage() {
  return (
    <div className="relative min-h-screen overflow-x-hidden bg-black text-slate-200 selection:bg-red-500/30">
      <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden">
        <div className="silk-layer absolute inset-0" />
        <div className="absolute inset-0 bg-grid-animated opacity-50" />
        <div className="aurora-a absolute -left-40 top-10 h-[34rem] w-[34rem] rounded-full bg-red-600/15 blur-[130px]" />
        <div className="aurora-b absolute -right-40 top-40 h-[30rem] w-[30rem] rounded-full bg-rose-500/10 blur-[130px]" />
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-black" />
      </div>

      <SiteNav />

      <main className="relative z-10 px-6 pb-12 pt-40">
        <div className="mx-auto max-w-5xl">
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.2em] text-slate-500 transition-colors hover:text-white"
          >
            <ArrowLeft className="h-3.5 w-3.5" />
            Back to Pokéventure
          </Link>

          <div className="mt-8 flex flex-col gap-5 border-b border-white/[0.07] pb-9 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full border border-red-400/20 bg-red-400/10 px-3 py-1 text-[9px] font-black uppercase tracking-[0.2em] text-red-300">
                <Sparkles className="h-3 w-3" />
                Android build
              </div>
              <h1 className="mt-4 font-outfit text-5xl font-bold tracking-tight text-white sm:text-6xl">
                Download.
              </h1>
              <p className="mt-3 max-w-xl text-sm leading-relaxed text-slate-400 sm:text-base">
                Every APK below comes from the latest GitHub release. Choose the
                universal build if you are not sure which one your phone needs.
              </p>
            </div>
            <div className="flex items-center gap-2 text-[10px] font-bold uppercase tracking-[0.16em] text-slate-500">
              <ShieldCheck className="h-4 w-4 text-emerald-400" />
              Latest release · Free fan project
            </div>
          </div>

          <div className="mt-9">
            <DownloadRelease />
          </div>

          <div className="mt-12 grid gap-4 sm:grid-cols-3">
            {INSTALL_STEPS.map((step, index) => (
              <div
                key={step}
                className="rounded-2xl border border-white/[0.08] bg-white/[0.025] p-5"
              >
                <div className="flex items-center gap-3">
                  <span className="flex h-8 w-8 items-center justify-center rounded-lg border border-white/10 bg-white/[0.04] font-outfit text-xs font-black text-red-300">
                    {index + 1}
                  </span>
                  <Smartphone className="h-4 w-4 text-slate-500" />
                </div>
                <p className="mt-4 text-xs leading-relaxed text-slate-400">
                  {step}
                </p>
              </div>
            ))}
          </div>

          <p className="mt-6 rounded-2xl border border-amber-400/15 bg-amber-400/[0.04] px-5 py-4 text-[11px] leading-relaxed text-amber-100/70">
            These builds currently use the debug signing key, so switching from
            a locally built APK may require uninstalling the old copy first.
            Your save stays on the device; back it up before switching builds.
          </p>
        </div>
      </main>

      <SiteFooter />
    </div>
  );
}
