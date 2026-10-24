import Image from "next/image";
import Link from "next/link";
import type { LucideIcon } from "lucide-react";
import {
  ArrowRight,
  BookOpen,
  ChevronDown,
  Coins,
  Download,
  Github,
  QrCode,
  ShieldCheck,
  Sparkles,
  Swords,
  Trophy,
  Users,
  Zap,
} from "lucide-react";

import { DownloadRelease } from "@/components/download-release";
import { Reveal } from "@/components/reveal";
import { SiteFooter } from "@/components/site-footer";
import { SiteNav } from "@/components/site-nav";
import { REPO_URL } from "@/lib/releases";

const TICKER = [
  "1,025 species",
  "Six living zones",
  "Real Showdown battles",
  "Shiny hunting",
  "Daily quests",
  "Friend battles",
  "Pokédex",
  "PC boxes",
  "Type effectiveness",
  "Original soundtrack",
];

const STATS = [
  { value: "1,025", label: "Species" },
  { value: "6", label: "Zones" },
  { value: "18", label: "Types" },
  { value: "1 / 2,048", label: "Shiny odds" },
];

const FEATURES: {
  title: string;
  description: string;
  icon: LucideIcon;
}[] = [
  {
    title: "Catch in the wild",
    description:
      "Six living zones with real species pools, catch rates, five ball types, berries and a timing ring that rewards patience.",
    icon: Sparkles,
  },
  {
    title: "Real battles",
    description:
      "Every fight runs on the actual Pokémon Showdown engine — abilities, items, status, switches and type effectiveness included.",
    icon: Swords,
  },
  {
    title: "Raise a team",
    description:
      "IVs, natures, EVs, XP, move learning and evolutions. Build a party of six and keep the rest in your PC boxes.",
    icon: Trophy,
  },
  {
    title: "Complete the Dex",
    description:
      "All 1,025 species with stats, abilities, evolutions, learnsets, flavour text and a caught/missing tracker.",
    icon: BookOpen,
  },
  {
    title: "Daily reasons to return",
    description:
      "Rotating quests, streaks, a daily gift, shop stock and a date-stable featured Pokémon.",
    icon: Coins,
  },
  {
    title: "Play with friends",
    description:
      "Share a trainer card or QR code, add friends and battle them from two phones with private invite codes.",
    icon: QrCode,
  },
];

const STEPS = [
  {
    number: "01",
    title: "Install the APK",
    body: "Download the universal build or the smaller APK for your phone's architecture.",
    icon: Download,
  },
  {
    number: "02",
    title: "Pick a starter",
    body: "Name your trainer and choose Bulbasaur, Charmander or Squirtle. Your journey starts at level 5.",
    icon: Sparkles,
  },
  {
    number: "03",
    title: "Catch and battle",
    body: "Explore, build a party and take on the AI or a friend on the real Showdown engine.",
    icon: Swords,
  },
];

const FAQS = [
  {
    question: "Is Pokéventure free?",
    answer:
      "Yes. The app is a free, non-commercial fan project. There are no ads, purchases or paid advantages.",
  },
  {
    question: "Which APK should I download?",
    answer:
      "Choose ARM64 for almost every modern Android phone. Use ARMv7 only on older 32-bit devices, x86_64 for emulators, or Universal if you are unsure.",
  },
  {
    question: "Do I need an account?",
    answer:
      "No account is needed for the single-player game. Optional Supabase-backed social features use a lightweight anonymous session for trainer cards and friend battles.",
  },
  {
    question: "Does it work offline?",
    answer:
      "Your party, PC, bag, coins, Pokédex and quests are stored on-device. Battles and friend features need the game server, and sprites need a connection.",
  },
];

const MOVES = [
  {
    name: "Surf",
    type: "Water",
    className: "border-sky-400/20 bg-sky-400/10 text-sky-200",
  },
  {
    name: "Ice Beam",
    type: "Ice",
    className: "border-cyan-300/20 bg-cyan-300/10 text-cyan-100",
  },
  {
    name: "Rapid Spin",
    type: "Normal",
    className: "border-slate-300/20 bg-slate-300/10 text-slate-200",
  },
  {
    name: "Protect",
    type: "Normal",
    className: "border-slate-300/20 bg-slate-300/10 text-slate-200",
  },
];

export default function HomePage() {
  return (
    <div className="relative min-h-screen overflow-x-hidden bg-black text-slate-200 selection:bg-red-500/30">
      <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden">
        <div className="silk-layer absolute inset-0" />
        <div className="absolute inset-0 bg-grid-animated opacity-60" />
        <div className="aurora-a absolute -left-40 top-10 h-[34rem] w-[34rem] rounded-full bg-red-600/15 blur-[130px]" />
        <div className="aurora-b absolute -right-40 top-40 h-[30rem] w-[30rem] rounded-full bg-rose-500/10 blur-[130px]" />
        <div className="aurora-c absolute left-1/3 top-[38rem] h-[28rem] w-[28rem] rounded-full bg-sky-500/10 blur-[140px]" />
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-black" />
      </div>

      <SiteNav />

      <main className="relative z-10">
        <section className="px-6 pb-16 pt-44 sm:pt-48">
          <div className="mx-auto max-w-7xl text-center">
            <Reveal>
              <Image
                src="/logo.png"
                alt="Pokéventure"
                width={88}
                height={88}
                priority
                className="float-y mx-auto h-20 w-20 rounded-[1.6rem] border border-white/15 shadow-[0_20px_60px_rgba(239,68,68,0.25)] sm:h-24 sm:w-24"
              />
            </Reveal>

            <Reveal delay={80}>
              <div className="mt-8 inline-flex items-center gap-3 rounded-full border border-white/15 bg-white/[0.06] px-5 py-2 text-[10px] font-black uppercase tracking-[0.28em] text-white backdrop-blur-md">
                <span className="dot-live h-2 w-2 rounded-full bg-red-400" />
                Fan-made · Real Showdown engine
              </div>
            </Reveal>

            <Reveal delay={160}>
              <h1 className="mt-8 font-outfit text-6xl font-bold uppercase leading-[0.86] tracking-tighter text-white sm:text-8xl md:text-[8.5rem]">
                Catch them.
                <br />
                <span className="text-shimmer-red bg-gradient-to-r from-red-400 via-rose-300 to-red-500 bg-clip-text text-transparent">
                  Battle for real.
                </span>
              </h1>
            </Reveal>

            <Reveal delay={260}>
              <p className="mx-auto mt-8 max-w-3xl text-base font-medium leading-relaxed text-slate-400 sm:text-xl md:text-2xl">
                Pokéventure is a mobile collection RPG built on the actual
                Pokémon Showdown battle engine. Pick a starter, explore six
                living zones and battle friends from your phone.
              </p>
            </Reveal>

            <Reveal delay={360}>
              <div className="mt-11 flex flex-col items-center justify-center gap-4 sm:flex-row">
                <Link
                  href="/download"
                  className="btn-shine group flex w-full items-center justify-center gap-3 rounded-2xl bg-white px-10 py-5 text-base font-black uppercase tracking-wide text-black shadow-[0_0_60px_rgba(255,255,255,0.2)] transition-all hover:scale-[1.03] hover:bg-slate-100 active:scale-95 sm:w-auto"
                >
                  <Download className="h-5 w-5 transition-transform group-hover:translate-y-0.5" />
                  Download APK
                </Link>
                <a
                  href={REPO_URL}
                  target="_blank"
                  rel="noreferrer"
                  className="group flex w-full items-center justify-center gap-3 rounded-2xl border border-white/10 bg-white/[0.02] px-10 py-5 text-base font-bold text-white backdrop-blur-3xl transition-all hover:border-white/20 hover:bg-white/[0.06] sm:w-auto"
                >
                  <Github className="h-5 w-5" />
                  View source
                  <ArrowRight className="h-4 w-4 opacity-40 transition-all group-hover:translate-x-1 group-hover:opacity-100" />
                </a>
              </div>
              <p className="mt-5 text-[10px] font-bold uppercase tracking-[0.24em] text-slate-600">
                Android 7+ · Free · No ads
              </p>
            </Reveal>

            <Reveal delay={480}>
              <div className="mt-16 flex flex-wrap items-center justify-center gap-x-12 gap-y-7 border-y border-white/[0.06] py-8">
                {STATS.map((stat) => (
                  <div key={stat.label} className="text-center">
                    <p className="font-outfit text-3xl font-black tabular-nums text-white sm:text-4xl">
                      {stat.value}
                    </p>
                    <p className="mt-1.5 text-[9px] font-black uppercase tracking-[0.28em] text-slate-500">
                      {stat.label}
                    </p>
                  </div>
                ))}
              </div>
            </Reveal>
          </div>
        </section>

        <Reveal className="mx-auto mt-4 max-w-7xl px-6">
          <div className="overflow-hidden rounded-full border border-white/[0.05] bg-white/[0.01] py-4 backdrop-blur-xl [mask-image:linear-gradient(90deg,transparent,black_10%,black_90%,transparent)]">
            <div className="marquee-track flex w-max items-center gap-10 pr-10">
              {[...TICKER, ...TICKER].map((item, index) => (
                <span
                  key={`${item}-${index}`}
                  className="flex items-center gap-10 whitespace-nowrap text-[11px] font-black uppercase tracking-[0.28em] text-slate-500"
                >
                  {item}
                  <span className="h-1.5 w-1.5 rounded-full bg-red-500/70" />
                </span>
              ))}
            </div>
          </div>
        </Reveal>

        <section id="battle" className="scroll-mt-28 px-6 pb-10 pt-24">
          <div className="mx-auto grid max-w-6xl items-center gap-12 lg:grid-cols-[0.9fr_1.1fr]">
            <Reveal>
              <p className="text-[10px] font-black uppercase tracking-[0.3em] text-red-400">
                Not a simplified clone
              </p>
              <h2 className="mt-4 font-outfit text-4xl font-bold tracking-tight text-white sm:text-5xl">
                A real battle engine,
                <br />
                in your pocket.
              </h2>
              <p className="mt-6 text-base leading-relaxed text-slate-400">
                The app never guesses an outcome. Every turn is simulated by the
                same Pokémon Showdown engine competitive players use, then sent
                back as a side-aware snapshot.
              </p>
              <div className="mt-8 space-y-3">
                {[
                  "Type chart, abilities, items and status effects",
                  "Switches, forced replacements and PP",
                  "Private friend battles with invite codes",
                  "Server snapshots hide the opponent's hidden info",
                ].map((line) => (
                  <div key={line} className="flex items-start gap-3">
                    <ShieldCheck className="mt-0.5 h-4 w-4 shrink-0 text-emerald-400" />
                    <span className="text-sm leading-relaxed text-slate-300">
                      {line}
                    </span>
                  </div>
                ))}
              </div>
            </Reveal>

            <Reveal delay={120}>
              <div className="tilt-stage">
                <div className="tilt-inner relative overflow-hidden rounded-[2rem] border border-white/10 bg-[#08080a]/90 p-5 shadow-[0_40px_120px_rgba(0,0,0,0.85)] backdrop-blur-xl sm:p-6">
                  <div className="mb-5 flex items-center justify-between border-b border-white/[0.07] pb-4">
                    <div className="flex items-center gap-2">
                      <span className="dot-live h-2 w-2 rounded-full bg-red-400" />
                      <span className="text-[9px] font-black uppercase tracking-[0.22em] text-slate-400">
                        Friend battle
                      </span>
                    </div>
                    <span className="font-mono text-[10px] text-slate-500">
                      Turn 03
                    </span>
                  </div>

                  <div className="flex items-center justify-between rounded-2xl border border-white/[0.06] bg-white/[0.025] p-3.5">
                    <div className="flex items-center gap-3">
                      <span className="flex h-12 w-12 items-center justify-center rounded-full border border-orange-400/30 bg-gradient-to-br from-orange-500/40 to-red-700/40 font-outfit text-lg font-black text-orange-100">
                        C
                      </span>
                      <div>
                        <p className="font-outfit text-sm font-bold text-white">
                          Charizard
                        </p>
                        <p className="text-[9px] uppercase tracking-[0.18em] text-slate-500">
                          Lv. 50 · Fire / Flying
                        </p>
                      </div>
                    </div>
                    <span className="font-mono text-[10px] text-slate-400">
                      62%
                    </span>
                  </div>
                  <div className="mx-2 mt-1.5 h-1.5 overflow-hidden rounded-full bg-white/[0.07]">
                    <div className="h-full w-[62%] rounded-full bg-gradient-to-r from-amber-400 to-orange-500" />
                  </div>

                  <div className="my-5 flex items-center gap-3">
                    <div className="h-px flex-1 bg-white/[0.06]" />
                    <Zap className="h-4 w-4 text-red-400" />
                    <div className="h-px flex-1 bg-white/[0.06]" />
                  </div>

                  <div className="rounded-2xl border border-sky-400/15 bg-sky-500/[0.04] p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <span className="flex h-14 w-14 items-center justify-center rounded-full border border-sky-300/30 bg-gradient-to-br from-sky-400/35 to-blue-700/40 font-outfit text-xl font-black text-sky-100">
                          B
                        </span>
                        <div>
                          <p className="font-outfit text-base font-bold text-white">
                            Blastoise
                          </p>
                          <p className="text-[9px] uppercase tracking-[0.18em] text-slate-500">
                            Lv. 50 · Water
                          </p>
                        </div>
                      </div>
                      <span className="font-mono text-[10px] text-emerald-300">
                        88 / 100
                      </span>
                    </div>
                    <div className="mt-3 h-2 overflow-hidden rounded-full bg-white/[0.08]">
                      <div className="h-full w-[88%] rounded-full bg-gradient-to-r from-emerald-400 to-teal-500" />
                    </div>
                  </div>

                  <div className="mt-4 grid grid-cols-2 gap-2">
                    {MOVES.map((move) => (
                      <div
                        key={move.name}
                        className={`rounded-xl border px-3 py-2.5 ${move.className}`}
                      >
                        <p className="font-outfit text-xs font-bold">
                          {move.name}
                        </p>
                        <p className="mt-0.5 text-[8px] font-black uppercase tracking-[0.16em] opacity-60">
                          {move.type}
                        </p>
                      </div>
                    ))}
                  </div>

                  <div className="mt-4 rounded-xl border border-emerald-400/15 bg-emerald-400/[0.06] px-3.5 py-3 font-mono text-[10px] leading-relaxed text-emerald-200/80">
                    Blastoise used Surf.
                    <br />
                    It&apos;s super effective! Charizard lost 38 HP.
                  </div>
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        <section id="features" className="scroll-mt-28 px-6 pt-24">
          <div className="mx-auto max-w-6xl">
            <Reveal>
              <div className="max-w-3xl">
                <p className="text-[10px] font-black uppercase tracking-[0.3em] text-red-400">
                  The whole loop
                </p>
                <h2 className="mt-4 font-outfit text-4xl font-bold tracking-tight text-white sm:text-5xl">
                  Catch. Train. Evolve. Repeat.
                </h2>
                <p className="mt-5 text-base leading-relaxed text-slate-400">
                  A complete collection RPG, not a demo. Everything below is in
                  the current build.
                </p>
              </div>
            </Reveal>

            <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {FEATURES.map((feature, index) => {
                const Icon = feature.icon;
                return (
                  <Reveal key={feature.title} delay={index * 60}>
                    <div className="spotlight group h-full rounded-[1.5rem] border border-white/10 bg-white/[0.025] p-6 transition-all duration-300 hover:border-white/20 hover:bg-white/[0.045]">
                      <span className="flex h-11 w-11 items-center justify-center rounded-xl border border-red-400/20 bg-red-500/10">
                        <Icon className="h-5 w-5 text-red-300" />
                      </span>
                      <h3 className="mt-5 font-outfit text-lg font-bold text-white">
                        {feature.title}
                      </h3>
                      <p className="mt-2.5 text-sm leading-relaxed text-slate-400">
                        {feature.description}
                      </p>
                    </div>
                  </Reveal>
                );
              })}
            </div>
          </div>
        </section>

        <section className="px-6 pt-24">
          <div className="mx-auto max-w-6xl">
            <Reveal>
              <div className="rounded-[2rem] border border-white/10 bg-white/[0.025] p-7 sm:p-10">
                <div className="grid gap-8 lg:grid-cols-[0.8fr_1.2fr] lg:items-center">
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-[0.3em] text-red-400">
                      Start in under a minute
                    </p>
                    <h2 className="mt-4 font-outfit text-3xl font-bold text-white sm:text-4xl">
                      From download
                      <br />
                      to first battle.
                    </h2>
                    <p className="mt-4 text-sm leading-relaxed text-slate-400">
                      No account, no tutorial maze. Install, choose your partner
                      and start exploring.
                    </p>
                    <Link
                      href="/download"
                      className="mt-6 inline-flex items-center gap-2 text-sm font-bold text-white transition-colors hover:text-red-300"
                    >
                      Get the latest APK
                      <ArrowRight className="h-4 w-4" />
                    </Link>
                  </div>
                  <div className="space-y-3">
                    {STEPS.map((step) => {
                      const Icon = step.icon;
                      return (
                        <div
                          key={step.number}
                          className="flex items-start gap-4 rounded-2xl border border-white/[0.07] bg-black/30 p-4"
                        >
                          <span className="font-outfit text-lg font-black text-red-400">
                            {step.number}
                          </span>
                          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-white/10 bg-white/[0.04]">
                            <Icon className="h-4 w-4 text-slate-300" />
                          </span>
                          <div>
                            <p className="font-outfit text-sm font-bold text-white">
                              {step.title}
                            </p>
                            <p className="mt-1 text-xs leading-relaxed text-slate-400">
                              {step.body}
                            </p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        <section id="download" className="scroll-mt-28 px-6 pt-24">
          <div className="mx-auto max-w-5xl">
            <Reveal>
              <div className="text-center">
                <p className="text-[10px] font-black uppercase tracking-[0.3em] text-red-400">
                  Latest build
                </p>
                <h2 className="mt-4 font-outfit text-4xl font-bold tracking-tight text-white sm:text-5xl">
                  Download Pokéventure.
                </h2>
                <p className="mx-auto mt-4 max-w-2xl text-base leading-relaxed text-slate-400">
                  These buttons always point at the newest GitHub release. Pick
                  the build that matches your device.
                </p>
              </div>
            </Reveal>
            <Reveal delay={100} className="mt-9">
              <DownloadRelease />
            </Reveal>
          </div>
        </section>

        <section className="px-6 pt-24">
          <div className="mx-auto max-w-4xl">
            <Reveal>
              <h2 className="text-center font-outfit text-3xl font-bold text-white sm:text-4xl">
                Questions, answered.
              </h2>
            </Reveal>
            <div className="mt-8 space-y-2.5">
              {FAQS.map((faq, index) => (
                <Reveal key={faq.question} delay={index * 50}>
                  <details className="group rounded-2xl border border-white/10 bg-white/[0.025] px-5 py-4 open:bg-white/[0.04]">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-outfit text-sm font-bold text-white marker:hidden">
                      {faq.question}
                      <ChevronDown className="h-4 w-4 shrink-0 text-slate-500 transition-transform duration-300 group-open:rotate-180" />
                    </summary>
                    <p className="mt-3 text-sm leading-relaxed text-slate-400">
                      {faq.answer}
                    </p>
                  </details>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

        <section className="px-6 pt-24">
          <div className="conic-border mx-auto max-w-5xl rounded-[2rem]">
            <div className="relative overflow-hidden rounded-[2rem] bg-[#09090b] px-7 py-12 text-center sm:px-12">
              <div className="absolute -left-20 -top-20 h-64 w-64 rounded-full bg-red-600/15 blur-[90px]" />
              <div className="absolute -bottom-24 -right-20 h-64 w-64 rounded-full bg-sky-600/10 blur-[90px]" />
              <Users className="relative mx-auto h-8 w-8 text-red-400" />
              <h2 className="relative mt-5 font-outfit text-4xl font-bold tracking-tight text-white sm:text-5xl">
                Your first partner is waiting.
              </h2>
              <p className="relative mx-auto mt-4 max-w-xl text-sm leading-relaxed text-slate-400 sm:text-base">
                Download the latest build and start in the Verdant Route. The
                rest of the Pokédex is out there.
              </p>
              <div className="relative mt-7 flex flex-col items-center justify-center gap-3 sm:flex-row">
                <Link
                  href="/download"
                  className="btn-shine flex w-full items-center justify-center gap-2 rounded-xl bg-red-500 px-7 py-4 text-sm font-black uppercase tracking-wider text-white shadow-lg shadow-red-500/25 transition-all hover:scale-[1.03] hover:bg-red-400 active:scale-95 sm:w-auto"
                >
                  <Download className="h-4 w-4" />
                  Download APK
                </Link>
                <a
                  href={REPO_URL}
                  target="_blank"
                  rel="noreferrer"
                  className="flex w-full items-center justify-center gap-2 rounded-xl border border-white/10 px-7 py-4 text-sm font-bold text-white transition-colors hover:bg-white/[0.06] sm:w-auto"
                >
                  <Github className="h-4 w-4" />
                  Star on GitHub
                </a>
              </div>
            </div>
          </div>
        </section>
      </main>

      <SiteFooter />
    </div>
  );
}
