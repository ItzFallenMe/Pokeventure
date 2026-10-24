import Image from "next/image";
import Link from "next/link";
import { Github, Heart } from "lucide-react";

import { RELEASES_URL, REPO_URL } from "@/lib/releases";

export function SiteFooter() {
  return (
    <footer className="relative z-10 mt-24 border-t border-white/[0.06] px-6 py-12">
      <div className="mx-auto flex max-w-6xl flex-col gap-8">
        <div className="flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
          <Link href="/" className="flex items-center gap-3">
            <span className="h-10 w-10 overflow-hidden rounded-full border border-white/15">
              <Image
                src="/logo.png"
                alt="Pokéventure"
                width={40}
                height={40}
                className="h-full w-full object-cover"
              />
            </span>
            <span>
              <span className="block font-outfit text-lg font-bold text-white">
                Pokéventure
              </span>
              <span className="block text-[9px] font-black uppercase tracking-[0.24em] text-slate-500">
                A fan-made mobile RPG
              </span>
            </span>
          </Link>

          <div className="flex flex-wrap items-center gap-5 text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">
            <Link href="/download" className="transition-colors hover:text-white">
              Download
            </Link>
            <a
              href={REPO_URL}
              target="_blank"
              rel="noreferrer"
              className="flex items-center gap-2 transition-colors hover:text-white"
            >
              <Github className="h-3.5 w-3.5" />
              Source
            </a>
            <a
              href={RELEASES_URL}
              target="_blank"
              rel="noreferrer"
              className="transition-colors hover:text-white"
            >
              Releases
            </a>
          </div>
        </div>

        <div className="flex flex-col gap-3 border-t border-white/[0.06] pt-6 text-[11px] leading-relaxed text-slate-500 sm:flex-row sm:items-start sm:justify-between">
          <p className="max-w-2xl">
            Pokémon and Pokémon character names are trademarks of Nintendo,
            Creators, Game Freak and The Pokémon Company. Pokéventure is a
            non-commercial fan project, not affiliated with or endorsed by them.
          </p>
          <p className="flex shrink-0 items-center gap-1.5">
            Built with <Heart className="h-3 w-3 text-red-400" /> by{" "}
            <a
              href="https://github.com/ItzFallenMe"
              target="_blank"
              rel="noreferrer"
              className="text-slate-300 transition-colors hover:text-white"
            >
              ItzFallenMe
            </a>
          </p>
        </div>
      </div>
    </footer>
  );
}
