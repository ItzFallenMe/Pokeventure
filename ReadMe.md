# Pokéventure

A mobile collection RPG inspired by Pokétwo, with battles on the real
[Pokémon Showdown](https://github.com/smogon/pokemon-showdown) engine.

[![APK](https://github.com/iwannabeyourshere/PokeNext/actions/workflows/apk.yml/badge.svg)](https://github.com/iwannabeyourshere/PokeNext/actions/workflows/apk.yml)
[![Server](https://github.com/iwannabeyourshere/PokeNext/actions/workflows/server.yml/badge.svg)](https://github.com/iwannabeyourshere/PokeNext/actions/workflows/server.yml)

Flutter (app) + Node.js/TypeScript (game server) + Supabase (social) + PokeAPI
sprites.
Design and scope → [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md). Free server
hosting → [docs/HOSTING.md](docs/HOSTING.md). Social setup →
[docs/SUPABASE.md](docs/SUPABASE.md).

## What works today

- **Real battles** — queue from the Battle tab, the server creates a Showdown
  battle, and every turn resolves on the actual simulator. Type-coloured move
  buttons show power and effectiveness against the current foe; switches,
  forced replacements, HP, status, party dots and a readable log all come from
  server snapshots.
- **Social** — anonymous Supabase sign-in, a trainer card with a unique
  6-character code, QR display and camera scanning, friend requests with
  accept/decline, removal, and online/last-seen presence. Trainer cards and
  friendships live in Postgres with row-level security.
- **Friend battles** — create an invite, share the code or QR, and play the
  same battle on two phones through the real engine. Both sides poll for the
  opponent’s move, so it works through ordinary HTTP without a websocket.
- **Sprites** — PokeAPI official artwork for battles and sprite avatars in the
  party, PC, home and Pokédex; a type-coloured orb is drawn instantly and stays
  if the network is unavailable.
- **Pokédex** — 1,025 species generated from `@pkmn/dex`, search by name or
  number, 18 type filters, caught/missing filters, base stats and abilities.
- **Party of six** — drag to reorder the lead, heal, per-Pokémon detail sheet
  (stats, IVs, nature, ability, item, moves), and a PC swap that always sends
  one out when one comes in.
- **Catch minigame** — timing ring, ball picker, shiny reveal, and the
  party-full path that offers the PC instead of breaking the six limit.
- **Bag, shop, settings** — six item categories, coin purchases that update the
  bag, persisted theme mode, local save reset, licences.
- **Local save** — party, PC, coins, gems, bag and theme survive restarts.
- **CI** — GitHub Actions analyzes and tests the app, builds a release APK and
  attaches it to tagged releases; a second workflow tests the server against the
  vendored engine.

Not built yet: full accounts (social uses anonymous identity), server-side
collection sync, ranked ladders, party-based formats, trading/market, guilds and
raids. Battles and friend-battle invites live in memory and reset when the
server restarts.

## Requirements

- Flutter 3.44+ / Dart 3.12+
- Node.js **22.18+** (required by current `pokemon-showdown`)
- Android SDK + JDK 17/21 to build an APK
- Git, and a checkout with submodules

## Setup

```bash
git clone --recurse-submodules https://github.com/iwannabeyourshere/PokeNext.git
cd PokeNext
./scripts/bootstrap.sh
```

`bootstrap.sh` checks your Node version, checks out the Showdown submodule,
installs and builds it, then installs server and Flutter dependencies. Social is
optional: to enable it, create a free Supabase project, run
[`supabase/migrations/0001_social.sql`](supabase/migrations/0001_social.sql) in
its SQL editor, enable anonymous sign-ins, and follow
[docs/SUPABASE.md](docs/SUPABASE.md). Without it the Social tab shows a setup
card and every other screen works normally.

On Windows, run the bootstrap from Git Bash, or do the same steps by hand:

```bash
git submodule update --init --recursive
cd vendor/pokemon-showdown && npm ci && node build
cd ../../server && npm ci
cd ../app && flutter pub get
```

Then start the server and the app in two terminals:

```bash
cd server && npm start            # http://0.0.0.0:8787
cd app && flutter run             # pick an emulator or device
```

The app defaults to `http://10.0.2.2:8787` on Android (emulator → host) and
`http://127.0.0.1:8787` elsewhere. For a physical phone, pass your machine's
LAN address:

```bash
cd app
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8787
```

The Showdown engine is a git submodule; `git submodule update --init --recursive`
is what fixes a missing `vendor/pokemon-showdown/dist` after a fresh clone.

## Build an APK

Locally:

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-server.example.com \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
# app/build/app/outputs/flutter-apk/app-release.apk
```

Without `API_BASE_URL` the APK uses the emulator/localhost defaults, which only
work when the server is on the same machine or emulator host. Without the
Supabase values, Social stays disabled. The anon key is public by design; row
level security protects the tables.

### Build the APK with GitHub Actions

The [APK workflow](.github/workflows/apk.yml) runs on every push to `main`, on
pull requests and on demand:

1. **Actions → APK → Run workflow** (or push to `main`).
2. It runs `flutter analyze` and `flutter test`, then builds the release APK.
3. Download `pokeventure-apk` from the run's **Artifacts** section.

To bake in real endpoints, add repository **variables** under
**Settings → Secrets and variables → Actions → Variables**:

| Variable | Value |
|---|---|
| `API_BASE_URL` | Public game server, e.g. `https://pokeventure-server.onrender.com` |
| `SUPABASE_URL` | `https://YOUR-PROJECT.supabase.co` |
| `SUPABASE_ANON_KEY` | The public anon/publishable key |

Leaving them unset produces an APK with the local development defaults and
Social disabled.

Pushing a tag such as `v0.2.0` also attaches the APK to a GitHub Release:

```bash
git tag v0.2.0
git push origin v0.2.0
```

The workflow pins Flutter `3.44.0` via `env.FLUTTER_VERSION`; bump it together
with `app/pubspec.yaml`'s SDK constraint when upgrading.

### Install the APK

```bash
adb install -r app-release.apk
```

Or copy the APK to the phone and open it, allowing "install unknown apps" for
the file manager. Android blocks cleartext HTTP for apps by default; this build
opts in so a local server works, and it requests the INTERNET permission in the
release manifest.

## Hosting the server free

The server needs a long-running process, not a serverless function. Options that
still have a free tier (checked October 2026), with step-by-step instructions,
are in **[docs/HOSTING.md](docs/HOSTING.md)**:

- **Wispbyte** — free, always-on panel host with a Node 22 image; run
  `scripts/wispbyte-setup.sh` once, then set the startup command to
  `scripts/wispbyte-start.sh`.
- **Render free** — easiest, no card; blueprint in `render.yaml`, sleeps after
  15 minutes idle.
- **Koyeb / Northflank free** — one small always-container per project, also
  scale to zero.
- **Oracle Cloud Always Free** — 2 OCPU / 12 GB ARM VM that stays up; the best
  free choice for real play, requires card verification.
- **Home PC + Cloudflare Tunnel** — free public HTTPS URL without port
  forwarding.

A root `Dockerfile` builds the server and the Showdown engine, and
`.dockerignore` keeps the context small. Set the app's `API_BASE_URL` to the
HTTPS URL the host gives you.

## Checks

```bash
cd app && flutter analyze && flutter test       # 33 tests
cd server && npm run typecheck && npm test      # 6 tests, real engine
```

The server tests play full Showdown battles, so they need the submodule built.
`npm run smoke` in `server/` runs a single battle and prints the turn log.

## Project layout

```
docs/GAME_DESIGN.md      full game and app design
docs/HOSTING.md          free deployment options and steps
docs/SUPABASE.md         social setup (anonymous auth, SQL, QR)
supabase/migrations/     players + friendships schema with RLS
app/                     Flutter client
  lib/app/               root app + five-tab shell
  lib/features/          home, catch, party/PC, dex, bag, shop, battle, social, more
  lib/data/              models, loaders, type chart, battle + friend-battle APIs, storage
  lib/data/social/       Supabase repository, trainer models, bootstrap
  lib/state/             Riverpod party/PC, shop and theme state (persisted)
  lib/ui/                theme, tokens, sprites and shared widgets
  assets/data/           generated dex.json (1,025 species) and moves.json
server/                  TypeScript game server
  src/battle/engine.ts   the only seam onto the vendored simulator
  src/battle/session.ts  authoritative sessions, AI opponent, player snapshots
  src/index.ts           HTTP API
  test/                  battle integration tests
vendor/pokemon-showdown  pinned Showdown submodule (built, never edited)
tools/gen-dex.mjs        @pkmn/dex → dex + move snapshots
scripts/bootstrap.sh     one-command local setup
scripts/wispbyte-*.sh    setup/start for Wispbyte and similar panels
Dockerfile               server + engine image for free hosts
render.yaml              Render blueprint
.github/workflows/       APK build/release and server CI
```

## API

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/health` | Engine, formats, active battle count |
| `GET` | `/api/formats` | Supported battle formats |
| `POST` | `/api/battles` | Start a battle (`{"format":"gen9randombattle"}`) |
| `GET` | `/api/battles/:id` | Current snapshot |
| `POST` | `/api/battles/:id/choice` | Submit `move 1`, `switch 2`, etc. |
| `POST` | `/api/friend-battles` | Create an invite (`{"name":"Aria"}`) |
| `POST` | `/api/friend-battles/join` | Join with `{"code":"ABC123","name":"Kai"}` |
| `GET` | `/api/friend-battles/:id` | Poll; send `x-battle-token` |
| `POST` | `/api/friend-battles/:id/choice` | Your move or switch, with the token |

Snapshots expose only what a player may know: their own team and moves, the
revealed opponent, turn, log and result. Friend battle tokens are random and
scoped to one lobby, so a code alone can join but cannot act for someone else.
`PORT` defaults to `8787`.

## Troubleshooting

- **`Cannot find module .../pokemon-showdown/dist/...`** — the submodule is not
  built: `git submodule update --init --recursive` then
  `cd vendor/pokemon-showdown && npm ci && node build`.
- **Node version errors** — `pokemon-showdown` requires Node 22.18+; check with
  `node -v`.
- **Battle tab can't reach the server** — on an emulator use `10.0.2.2`, on a
  phone use the host's LAN IP, and make sure port 8787 is reachable. Rebuild the
  APK with `--dart-define=API_BASE_URL=...` after changing it.
- **Sprites do not appear** — PokeAPI artwork is fetched over HTTPS on first
  view; offline, the type-coloured orb fallback is expected.
- **Social shows a setup card** — the build has no Supabase credentials. Follow
  [docs/SUPABASE.md](docs/SUPABASE.md) and rebuild with the two defines.
- **“Could not sign in to social”** — enable anonymous sign-ins in Supabase
  (*Authentication → Providers*), then pull to refresh the Social tab.
- **Camera does not open** — the scanner needs camera permission; on Android
  it is merged from the plugin manifest, on iOS it is `NSCameraUsageDescription`.
  Typing the code always works as a fallback.
- **Gradle build fails** — use JDK 17 or 21 (`flutter doctor -v` shows the Java
  it picked).
- **Free host slept** — the first request takes up to a minute; an in-progress
  battle is lost and can be queued again.

## Data and attribution

Pokémon and Pokémon character names are trademarks of Nintendo, Creators,
Game Freak and The Pokémon Company. This is a non-commercial fan project, not
affiliated with or endorsed by them.

- Species, move and sprite data: [PokeAPI](https://pokeapi.co/) and
  [`@pkmn/dex`](https://github.com/pkmn/ps).
- Social database, auth and row-level security: [Supabase](https://supabase.com).
- Battle simulation: [smogon/pokemon-showdown](https://github.com/smogon/pokemon-showdown)
  (MIT), vendored as a submodule and used unmodified.
