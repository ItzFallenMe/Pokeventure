# Pokéventure website

The public landing and download site for Pokéventure. It is a Next.js app in
the game's visual language: black glass surfaces, aurora backgrounds, Outfit
display type and red Pokéball accents.

## Deploy on Vercel

1. Import `ItzFallenMe/Pokeventure` into Vercel.
2. Set **Root Directory** to `website`.
3. Use the default **Next.js** preset and deploy.
4. Optional: add a `GITHUB_TOKEN` environment variable (a read-only token is
   enough) to raise the GitHub API rate limit. Do **not** prefix it with
   `NEXT_PUBLIC_`.

The download section reads `/api/latest-release`, which fetches the newest
non-draft, non-prerelease release from
`https://github.com/ItzFallenMe/Pokeventure/releases/latest` and caches the
result for five minutes. No release data is committed to the site.

## Local development

```bash
cd website
npm install
npm run dev
# http://localhost:3000
```

Build check:

```bash
npm run build
```

## Release asset names

The APK workflow uploads these assets to every tagged release:

| Asset | Device |
|---|---|
| `pokeventure-universal.apk` | Every Android device |
| `pokeventure-arm64-v8a.apk` | Modern 64-bit phones |
| `pokeventure-armeabi-v7a.apk` | Older 32-bit phones |
| `pokeventure-x86_64.apk` | Emulators and x86 devices |

The download cards match these names. If a release was published before the
split build existed, the missing cards show as unavailable instead of linking
to the wrong file.
