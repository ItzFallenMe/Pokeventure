import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";

import "./globals.css";

const outfit = localFont({
  src: "./fonts/Outfit-Variable.ttf",
  variable: "--font-outfit",
  display: "swap",
  weight: "100 900",
});

export const metadata: Metadata = {
  title: "Pokéventure — Catch, train and battle on your phone",
  description:
    "A fan-made mobile collection RPG with real Pokémon Showdown battles, 1,025 species, six living zones, daily quests and friend battles.",
  applicationName: "Pokéventure",
  icons: {
    icon: "/icon.png",
    apple: "/icon.png",
  },
  openGraph: {
    title: "Pokéventure",
    description:
      "Catch, train and battle with real Showdown mechanics. Download the latest Android APK.",
    type: "website",
  },
};

export const viewport: Viewport = {
  themeColor: "#000000",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={outfit.variable}>
      <body className="min-h-screen bg-black font-sans text-slate-200 antialiased">
        {children}
      </body>
    </html>
  );
}
