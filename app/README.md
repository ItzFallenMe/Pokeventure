# Pokéventure — Flutter app

The Android/iOS client for [Pokéventure](../ReadMe.md). It renders server battle
snapshots, keeps the party, PC, bag and settings locally, and talks to Supabase
for the Social tab.

## Run it

From this folder:

```bash
flutter pub get
flutter run
```

The app expects the game server on `http://10.0.2.2:8787` (Android emulator) or
`http://127.0.0.1:8787` elsewhere. Put your own values in an env file:

```bash
cp .env.example .env
# edit API_BASE_URL, and optionally SUPABASE_URL / SUPABASE_ANON_KEY
flutter run --dart-define-from-file=.env
```

`.env` is git-ignored. Plain `--dart-define=API_BASE_URL=...` also works.
Without Supabase values the Social tab shows its setup card and everything else
keeps working.

## Regenerate the data

The 1,025-species dex, moves and zone tables are generated from real sources:

```bash
cd ../tools
npm install
npm run gen-data     # writes ../app/assets/data/{dex,moves,zones}.json
```

The script caches downloads in `tools/.cache/` and merges Pokémon Showdown
(`@pkmn/dex`), PokeAPI CSV dumps and
[ItzFallenMe/pokemon-data.json](https://github.com/ItzFallenMe/pokemon-data.json).
The app never calls a species API at runtime.

## Sound and sprites

- Music, UI cues and celebration sounds are original assets in
  `assets/audio/`.
- Pokémon cries stream from Showdown's audio pack; sprites and official
  artwork come from the PokeAPI sprites repository. Both need a connection and
  fall back gracefully (type-coloured orbs) when offline.
- The display font is Outfit (SIL OFL, licence in `assets/fonts/OFL.txt`).

## Check it

```bash
flutter analyze
flutter test
flutter build apk --release
```

## Where things live

| Folder | Contents |
|---|---|
| `lib/app/` | root app widget and the five-tab shell |
| `lib/features/` | onboarding, home, explore/catch, party/PC, dex, bag, shop, battle, social, more/settings |
| `lib/data/game/` | stat/nature math, catch formula, wild spawns, daily quests |
| `lib/data/` | models, catalog loader, type chart, battle and friend-battle APIs |
| `lib/data/social/` | Supabase repository, trainer models, startup bootstrap |
| `lib/data/audio/` | music, SFX and cry playback |
| `lib/state/` | Riverpod trainer/collection, settings and persistence |
| `lib/ui/` | theme, motion kit, spacing/type tokens, sprites, shared widgets |
| `assets/data/` | generated `dex.json`, `moves.json` and `zones.json` |
| `assets/audio/` | generated theme and sound cues |

Full documentation: [setup](../docs/SETUP.md) ·
[hosting](../docs/HOSTING.md) · [Supabase](../docs/SUPABASE.md) ·
[API](../docs/API.md) · [design](../docs/GAME_DESIGN.md).
