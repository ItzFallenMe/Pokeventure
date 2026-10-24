import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
        primary: {
          DEFAULT: "#ffffff",
          hover: "#d4d4d4",
          glow: "rgba(255, 255, 255, 0.5)",
        },
        secondary: {
          DEFAULT: "#000000",
          light: "#0a0a0a",
        },
        accent: {
          red: "rgba(239, 68, 68, 0.12)",
          glass: "rgba(255, 255, 255, 0.03)",
        },
      },
      fontFamily: {
        sans: [
          "var(--font-outfit)",
          "ui-sans-serif",
          "system-ui",
          "sans-serif",
        ],
        outfit: ["var(--font-outfit)", "sans-serif"],
      },
      backgroundImage: {
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        "gradient-conic":
          "conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))",
      },
    },
  },
  plugins: [],
};

export default config;
