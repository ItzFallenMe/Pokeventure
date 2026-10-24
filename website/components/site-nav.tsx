import Image from "next/image";
import Link from "next/link";
import { Download, Github } from "lucide-react";

import { REPO_URL } from "@/lib/releases";

export function SiteNav() {
  return (
    <nav className="fixed inset-x-0 top-4 z-50 px-4">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between rounded-full border border-white/10 bg-white/[0.06] px-5 shadow-[0_10px_40px_rgba(0,0,0,0.55),inset_0_1px_0_rgba(255,255,255,0.09)] backdrop-blur-2xl backdrop-saturate-150">
        <Link href="/" className="group flex items-center gap-3 pl-2">
          <span className="relative flex h-9 w-9 items-center justify-center overflow-hidden rounded-xl border border-white/20 shadow-lg shadow-red-500/20 transition-transform duration-500 group-hover:rotate-6 group-hover:scale-110">
            <Image
              src="/logo.png"
              alt=""
              width={36}
              height={36}
              className="h-full w-full object-cover"
              priority
            />
          </span>
          <span className="flex flex-col">
            <span className="font-outfit text-base font-bold leading-none tracking-tight text-white">
              Pokéventure
            </span>
            <span className="mt-0.5 text-[8px] font-black uppercase tracking-[0.25em] text-red-400/90">
              Mobile RPG
            </span>
          </span>
        </Link>

        <div className="hidden items-center gap-8 text-[10px] font-black uppercase tracking-[0.2em] text-slate-500 lg:flex">
          <Link href="/#features" className="transition-colors hover:text-white">
            Features
          </Link>
          <Link href="/#battle" className="transition-colors hover:text-white">
            Battle
          </Link>
          <Link href="/#download" className="transition-colors hover:text-white">
            Download
          </Link>
          <a
            href={REPO_URL}
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-2 transition-colors hover:text-white"
          >
            <Github className="h-3.5 w-3.5" />
            GitHub
          </a>
        </div>

        <Link
          href="/download"
          className="btn-shine flex h-10 items-center gap-2 rounded-full border-none bg-gradient-to-r from-red-500 to-rose-600 px-6 text-[10px] font-black uppercase tracking-widest text-white shadow-lg shadow-red-500/25 transition-transform hover:scale-[1.04] active:scale-95"
        >
          <Download className="h-3.5 w-3.5" />
          <span className="hidden sm:inline">Get the app</span>
          <span className="sm:hidden">APK</span>
        </Link>
      </div>
    </nav>
  );
}
