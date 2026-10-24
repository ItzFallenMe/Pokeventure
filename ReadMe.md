# Pokéventure

A mobile collection RPG inspired by Pokétwo, built around the **real Pokémon
Showdown battle engine**. Catch Pokémon, build a party of six, complete the
Pokédex, add friends with a QR code, and play a turn-by-turn battle against
them on two phones.

[![APK](https://github.com/iwannabeyourshere/PokeNext/actions/workflows/apk.yml/badge.svg)](https://github.com/iwannabeyourshere/PokeNext/actions/workflows/apk.yml)
[![Server](https://github.com/iwannabeyourshere/PokeNext/actions/workflows/server.yml/badge.svg)](https://github.com/iwannabeyourshere/PokeNext/actions/workflows/server.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

Flutter app · Node.js + TypeScript server · Supabase social database · PokeAPI
sprites · Pokémon Showdown simulator.

**New here?** Follow the step-by-step
**[Setup guide](docs/SETUP.md)**. It covers Windows, macOS and Linux, from a
clean machine to an APK on your phone.

**Contents:** [Features](#what-the-app-does) ·
[Quick start](#quick-start-local) · [Social setup](#enable-social-supabase) ·
[Hosting](#host-the-server-free) · [APK from GitHub](#build-the-apk-with-github-actions) ·
[Configuration](#configuration) · [Tests](#tests) · [Structure](#project-structure) ·
[API](#api) · [Troubleshooting](#troubleshooting) ·
[Limits](#what-is-not-built-yet) · [Contributing](#contributing) ·
[Docs](#documentation) · [License](#license)

## What the app does

| Area | What works |
|---|---|
| **Home** | Daily hub with a featured spawn, streak, currencies, quests and quick actions. |
| **Catch** | Timing-ring minigame, ball choice, shiny reveal, haptics. A full party offers the PC instead of breaking the six limit. |
| **Party** | Six slots, drag to reorder the lead, heal all, per-Pokémon details (stats, IVs, nature, ability, item, moves), PC storage and swapping. |
| **Pokédex** | All 1,025 species generated from `@pkmn/dex`: search, 18 type filters, caught/missing filters, base stats and abilities. |
| **Bag & shop** | Six item categories and coin purchases that update the bag. |
| **Battle (AI)** | A real Showdown random battle against an AI. Type-coloured moves with live effectiveness, switches, forced replacements, HP, status, party dots and a readable log. |
| **Social** | Anonymous sign-in, trainer card with a unique code, QR display and camera scanning, friend requests, accept/decline, remove, online/last-seen. |
| **Friend battles** | Create an invite, share the code or QR, and play a human-vs-human battle. Both sides poll for the other player's move, so no websocket is needed. |
| **Settings** | Light/dark/system theme, local save summary, reset, licences. |
| **Offline** | Party, PC, coins, gems, bag and theme persist locally. Sprites fall back to type-coloured orbs. The Social tab explains setup instead of faking data. |

Battles run on the actual `smogon/pokemon-showdown` simulator, vendored as a git
submodule and used unmodified. The server only exposes what each player is
allowed to know: their own team and moves, the revealed opponent, turn, log and
result.

## How it fits together

```
┌────────────────────┐        HTTPS/HTTP         ┌─────────────────────────┐
│  Flutter app        │ ────────────────────────▶ │  Node game server        │
│  Android / iOS      │   REST, battle snapshots  │  Express + TypeScript    │
│                     │ ◀──────────────────────── │  Showdown simulator      │
│  local save         │                           │  AI + friend lobbies     │
│                     │                           └─────────────────────────┘
│                     │        HTTPS
│                     │ ────────────────────────▶ ┌─────────────────────────┐
│                     │   trainer cards, friends  │  Supabase               │
└────────────────────┘ ◀──────────────────────── │  Postgres + anonymous auth│
                                                 └─────────────────────────┘
              sprites: PokeAPI over HTTPS (cached by Flutter's image cache)
```

- The **app** never runs the simulator; it renders server snapshots.
- The **server** keeps battles in memory. Invites expire after 30 minutes.
- **Supabase** is only identity and social data, so it can stay on the free tier.
- **Sprites** are fetched from PokeAPI on first view and fall back to orbs when
  offline.

## Requirements

| Tool | Version | Needed for |
|---|---|---|
| Flutter | 3.44+ (Dart 3.12+) | app |
| Node.js | **22.18+** | game server + Showdown engine |
| Java | 17 or 21 | Android build |
| Android SDK | API 24+ | APK / emulator |
| Git | any recent | clone + submodule |

Node 20 or 18 will **not** run current `pokemon-showdown`. Panel hosts often
default to Node 18; pick a Node 22 image (see [Wispbyte](#wispbyte-also-good-for-a-free-always-on-server)).

## Quick start (local)

```bash
git clone --recurse-submodules https://github.com/iwannabeyourshere/PokeNext.git
cd PokeNext
./scripts/bootstrap.sh
```

`bootstrap.sh` checks Node, checks out and builds the Showdown submodule, then
installs server and app dependencies. On Windows use Git Bash (or follow
[docs/SETUP.md](docs/SETUP.md) for the manual PowerShell steps).

Then run two terminals:

```bash
# terminal 1 — game server
cd server
npm start                # http://0.0.0.0:8787

# terminal 2 — app
cd app
flutter run              # choose an emulator or connected phone
```

Check the server:

```bash
curl http://localhost:8787/health
# {"ok":true,"engine":"pokemon-showdown","formats":[...],"activeBattles":0}
```

The app uses `http://10.0.2.2:8787` on the Android emulator (host loopback) and
`http://127.0.0.1:8787` elsewhere. On a physical phone, point it at your
computer's LAN address:

```bash
cd app
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8787
```

> The phone and computer must be on the same network, and port 8787 must not be
> blocked by your firewall.

### Playing against the AI

Open **Battle → Random battle**. The app creates a battle, the server deals two
random teams on the real simulator, and every move round-trips. If the app says
it cannot reach the server, check `API_BASE_URL` and `/health`.

### Playing against a friend

1. Enable Social first (next section).
2. **Social → Battle a friend → Create invite**.
3. Share the six-character code or let your friend scan the QR.
4. Your friend opens **Social → Join code**, types the code, and both land in
   the arena. Each phone polls for the other player's move.

## Enable Social (Supabase)

Social is optional. Without it the Social tab shows a setup card; everything
else works.

1. Create a free project at [supabase.com](https://supabase.com).
2. **Authentication → Providers → Anonymous sign-ins → Enable.**
3. Open **SQL Editor**, paste
   [`supabase/migrations/0001_social.sql`](supabase/migrations/0001_social.sql)
   and run it.
4. From **Project Settings → API**, copy the **Project URL** and **anon public**
   key.
5. Build or run with both values:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

The anon key is designed to be public; row-level security protects the tables.
Never ship the `service_role` key. Full walkthrough and schema explanation:
[docs/SUPABASE.md](docs/SUPABASE.md).

## Host the server free

The game server needs a long-running process and in-memory state, so serverless
platforms (Vercel, Netlify, Lambda, Workers) are not a fit. Options with a real
free tier, checked October 2026:

| Host | Card | Always on | Notes |
|---|---|---|---|
| **Wispbyte** | No | **Yes** | Pterodactyl-style panel, 512 MB, Node 22 image needed |
| **Render** | No | No (sleeps after 15 min) | Blueprint included, easiest |
| **Koyeb** | No | No (scales to zero) | 512 MB, 0.1 vCPU |
| **Northflank Sandbox** | No | No | Two free services |
| **Oracle Cloud Always Free** | Yes (verify) | **Yes** | 2 OCPU / 12 GB ARM VM |
| **Home PC + Cloudflare Tunnel** | No | While it runs | Free public HTTPS |

### Wispbyte (also good for a free always-on server)

The repo has two scripts so a panel console can do everything:

1. Create a server at [wispbyte.com](https://wispbyte.com) with a **Node 22+**
   image. `node -v` must print v22.18 or newer.
2. Upload the repo (GitHub import or SFTP). If the upload skips the
   `vendor/pokemon-showdown` submodule, the setup script clones it.
3. In the console:

   ```bash
   bash scripts/wispbyte-setup.sh
   ```

4. Set the **startup command** to:

   ```bash
   bash scripts/wispbyte-start.sh
   ```

5. Use the allocated port. The server reads `PORT` first, then `SERVER_PORT`
   (the panel variable), then falls back to 8787.
6. Build the APK with `API_BASE_URL=http://HOST:PORT` (or set the repository
   variable and let the workflow build it).

**`EADDRINUSE` on 8787?** An old copy or a manually started `npm start` is still
running. Stop the server, update the files so the server reads `SERVER_PORT`,
and start once. **Node 18 crash?** Switch the image; the engine refuses to run on
18.

Step-by-step for every host: [docs/HOSTING.md](docs/HOSTING.md). A root
`Dockerfile` and `render.yaml` are included for container hosts.

## Build the APK with GitHub Actions

The [APK workflow](.github/workflows/apk.yml) runs `flutter analyze`,
`flutter test`, then builds a release APK. It runs on every push to `main`, on
pull requests, and on demand.

1. Push to GitHub (or use a fork).
2. Either set repository **variables** once under
   **Settings → Secrets and variables → Actions → Variables**…

   | Variable | Example |
   |---|---|
   | `API_BASE_URL` | `http://HOST:PORT` or `https://server.example.com` |
   | `SUPABASE_URL` | `https://YOUR-PROJECT.supabase.co` |
   | `SUPABASE_ANON_KEY` | your public anon key |

   …or type the same three values when starting a **manual run**. Manual
   inputs win over repository variables for that run.

3. Open **Actions → APK → Run workflow**, fill the values if you did not set
   variables, and run it. Pushes to `main` build with the variables/defaults.
4. Download **Artifacts → `pokeventure-apk`**.

Tag a release to attach the APK automatically:

```bash
git tag v0.2.0
git push origin v0.2.0
```

Build it locally instead:

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=http://HOST:PORT \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
# app/build/app/outputs/flutter-apk/app-release.apk
```

Install:

```bash
adb install -r app-release.apk
```

Or copy the APK to the phone and allow "install unknown apps". The release build
is currently signed with the debug key, so updates from a different machine may
require uninstalling first. Cleartext HTTP is allowed so a panel-hosted server
without HTTPS works; use HTTPS in production.

## Configuration

| Build define | Default | Purpose |
|---|---|---|
| `API_BASE_URL` | `10.0.2.2:8787` on Android, `127.0.0.1:8787` elsewhere | Game server |
| `SUPABASE_URL` | empty | Enables Social |
| `SUPABASE_ANON_KEY` | empty | Enables Social |

| Server env | Default | Purpose |
|---|---|---|
| `PORT` | first valid of `PORT`, `SERVER_PORT`, `8787` | Listen port |

## Tests

```bash
cd app && flutter analyze && flutter test        # 34 widget/unit tests
cd server && npm run typecheck && npm test       # 6 tests, real engine
```

App tests cover the party-of-six invariant, PC swaps, reorder, heal, catch and
shop flows, persistence, dex loading, tab navigation at a 390×844 phone
viewport, type effectiveness, move data, QR payloads, social flows and friend
battle polling. Server tests play real AI and friend battles to a winner,
including forced switches and Revival Blessing.

`cd server && npm run smoke` prints a single battle's turn log.

## Project structure

```
docs/                     guides and design
  SETUP.md                start here: clean machine → APK
  HOSTING.md              free server hosting, including Wispbyte
  SUPABASE.md             social setup and schema
  GAME_DESIGN.md          full game and app design
  API.md                  endpoint reference with examples
supabase/migrations/      players + friendships schema and RLS
app/                      Flutter client
  lib/app/                root app + five-tab shell
  lib/features/           home, catch, party/PC, dex, bag, shop, battle, social, more
  lib/data/               models, dex/move loaders, type chart, battle + friend battle APIs
  lib/data/social/        Supabase repository, trainer models, bootstrap
  lib/state/              Riverpod party/PC, shop and theme state (persisted)
  lib/ui/                 theme, tokens, sprites and shared widgets
  assets/data/            generated dex.json (1,025 species) and moves.json
server/                   TypeScript game server
  src/battle/engine.ts    the only seam onto the vendored simulator
  src/battle/session.ts   side-aware sessions, AI opponent, friend snapshots
  src/index.ts            HTTP API and friend lobbies
  test/                   battle integration tests
vendor/pokemon-showdown   pinned Showdown submodule (built, never edited)
tools/gen-dex.mjs         @pkmn/dex → dex + move snapshots
scripts/                  bootstrap + Wispbyte setup/start
Dockerfile                server + engine image
render.yaml               Render blueprint
.github/workflows/        APK build/release and server CI
```

## API

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/health` | Engine, formats, live battle count |
| `GET` | `/api/formats` | Supported formats |
| `POST` | `/api/battles` | Start an AI battle (`{"format":"gen9randombattle"}`) |
| `GET` | `/api/battles/:id` | Snapshot |
| `POST` | `/api/battles/:id/choice` | `move 1`, `switch 2`, `pass` |
| `POST` | `/api/friend-battles` | Create an invite (`{"name":"Aria"}`) |
| `POST` | `/api/friend-battles/join` | Join (`{"code":"ABC123","name":"Kai"}`) |
| `GET` | `/api/friend-battles/:id` | Poll; send `x-battle-token` |
| `POST` | `/api/friend-battles/:id/choice` | Submit a friend-battle choice |

Full request/response examples and the friend-battle
create → join → poll → choose sequence: [docs/API.md](docs/API.md).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Cannot find module .../pokemon-showdown/dist/...` | `git submodule update --init --recursive`, then `cd vendor/pokemon-showdown && npm ci && node build` |
| `Node.js v18` in a crash trace | Install/select Node 22.18+; then rerun `scripts/wispbyte-setup.sh` or `bootstrap.sh` |
| `EADDRINUSE 8787` | Stop the other server. On a panel use the allocated `SERVER_PORT` and one startup command only |
| Battle tab cannot reach the server | Emulator → `10.0.2.2`; phone → LAN IP; rebuild with the right `API_BASE_URL`; check `/health` |
| Social shows a setup card | Rebuild with `SUPABASE_URL` and `SUPABASE_ANON_KEY`; see [docs/SUPABASE.md](docs/SUPABASE.md) |
| "Could not sign in to social" | Enable anonymous sign-ins in Supabase, then pull to refresh |
| Camera will not open | Grant camera permission; the scanner also accepts a typed code |
| Sprites missing | PokeAPI is online-only; the type-coloured orb fallback is expected offline |
| Gradle build fails | Use JDK 17 or 21 (`flutter doctor -v` shows the selected Java) |
| APK updates refuse to install | Uninstall the old APK (release builds use the debug signing key) |

More detail: [docs/SETUP.md](docs/SETUP.md#troubleshooting).

## Security and privacy

- Social uses Supabase **anonymous** accounts. No email, password or contact
  data is collected. A trainer name, friend code and last-seen time are stored.
- Friend codes are lookup keys, not secrets: they can send a request, never act
  as you. Battle tokens are random per lobby and are required to act.
- Row-level security lets players read trainer cards, edit only their own, send
  requests as themselves and answer only requests addressed to them.
- The battle server holds sessions in memory; it has no accounts and no database
  writes. It trusts friend-battle tokens, so use HTTPS for a public deployment.

## What is not built yet

- Full accounts (email/OAuth), server-side collection sync, ranked ladders,
  party-based formats, trading/market, guilds and raids.
- Sprites are fetched at runtime; there is no offline sprite pack.
- Battles and friend invites reset when the server restarts.
- No offline sprite pack, ranked ladder, trading or guild features yet.
- Release APKs are debug-signed; add a keystore before distributing widely.

## Contributing

Issues and pull requests are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md)
for the development loop, the checks both CI workflows run, and the areas where
help is most useful. Small, tested, focused changes are the easiest to review.

- **[Bug report](.github/ISSUE_TEMPLATE/bug_report.yml)** — include the app
  version, Android version and steps.
- **[Feature request](.github/ISSUE_TEMPLATE/feature_request.yml)** — check
  [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) first.
- **[Code of Conduct](CODE_OF_CONDUCT.md)** — applies to every project space.

## Reporting a vulnerability

Please report security problems privately through [SECURITY.md](SECURITY.md),
not in a public issue. Only the Supabase **anon** key is ever shipped; the
`service_role` key, database passwords and personal access tokens never belong
in this repository. Build-time values live in GitHub Actions variables.

## License

[MIT](LICENSE) for the source code. Pokémon and Pokémon character names are
trademarks of Nintendo, Creators, Game Freak and The Pokémon Company; this is a
non-commercial fan project, not affiliated with or endorsed by them. The
vendored Pokémon Showdown submodule keeps its own MIT license, and species,
move and sprite data belongs to PokeAPI and `@pkmn/dex`.

## Documentation

- **[Documentation index](docs/README.md)** — recommended reading order.
- **[Setup guide](docs/SETUP.md)** — clean machine to phone, with OS-specific
  steps.
- **[Hosting](docs/HOSTING.md)** — Wispbyte, Render, Koyeb, Northflank, Oracle,
  Cloudflare Tunnel.
- **[Supabase](docs/SUPABASE.md)** — project, anonymous auth, SQL, QR codes.
- **[API](docs/API.md)** — endpoints, payloads, friend battle flow.
- **[Game design](docs/GAME_DESIGN.md)** — the full product and technical design.

## Credits

Pokémon and Pokémon character names are trademarks of Nintendo, Creators, Game
Freak and The Pokémon Company. This is a non-commercial fan project, not
affiliated with or endorsed by them.

- Species, move and sprite data: [PokeAPI](https://pokeapi.co/) and
  [`@pkmn/dex`](https://github.com/pkmn/ps).
- Battle simulation: [smogon/pokemon-showdown](https://github.com/smogon/pokemon-showdown)
  (MIT), vendored as a submodule and used unmodified.
- Social database and auth: [Supabase](https://supabase.com).
