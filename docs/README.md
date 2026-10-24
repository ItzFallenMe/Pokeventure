# Pokéventure documentation

Everything you need, from a clean machine to a server your friends can play on.

| If you want to… | Read |
|---|---|
| Install everything and put the app on a phone | **[SETUP.md](SETUP.md)** |
| Put the game server online for free | [HOSTING.md](HOSTING.md) |
| Turn on friends, QR codes and social | [SUPABASE.md](SUPABASE.md) |
| Call the server from your own client | [API.md](API.md) |
| Understand the game and product design | [GAME_DESIGN.md](GAME_DESIGN.md) |
| Contribute code or docs | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| Report a vulnerability | [SECURITY.md](../SECURITY.md) |

## Recommended order

1. **[SETUP.md](SETUP.md)** — install the tools, clone, bootstrap, run locally,
   build an APK.
2. **[HOSTING.md](HOSTING.md)** — choose a free host and start the game server.
3. **[SUPABASE.md](SUPABASE.md)** — create the social database (optional).
4. Rebuild the APK with `API_BASE_URL` and the two Supabase values.
5. **[API.md](API.md)** — if you want to script or extend the backend.

## The short version

```bash
git clone --recurse-submodules https://github.com/ItzFallenMe/Pokeventure.git
cd PokeNext
./scripts/bootstrap.sh

# terminal 1
cd server && npm start

# terminal 2
cd app
cp .env.example .env       # set API_BASE_URL (and Supabase keys if wanted)
flutter run --dart-define-from-file=.env
```

Then pick a starter and catch your first Pokémon in **Explore**. Social needs
Supabase; see [SUPABASE.md](SUPABASE.md).

## What each guide covers

| Guide | You will learn |
|---|---|
| [SETUP.md](SETUP.md) | Windows/macOS/Linux install steps, the bootstrap script, running the server and app, emulator vs physical phone, the first-run checklist, getting an APK from CI, troubleshooting |
| [HOSTING.md](HOSTING.md) | Why serverless does not fit, Wispbyte/Render/Koyeb/Northflank/Oracle/Cloudflare Tunnel, ports, Docker, HTTPS |
| [SUPABASE.md](SUPABASE.md) | Creating the project, enabling anonymous sign-ins, running the migration, how row-level security works, reading friend codes |
| [API.md](API.md) | Every endpoint, request and response bodies, the AI battle loop and the friend-battle create → join → poll → choose sequence |
| [GAME_DESIGN.md](GAME_DESIGN.md) | Screens, economy, collection rules, battle rendering, social design, roadmap |

## Repository map

```
app/                     Flutter client (Android/iOS)
server/                  Node + TypeScript game server
vendor/pokemon-showdown  pinned simulator submodule (never edited)
supabase/migrations/     social schema + row-level security
docs/                    this folder
scripts/                 bootstrap and panel-host scripts
Dockerfile               container image for the server
render.yaml              Render blueprint
.github/workflows/       APK and server CI
```

## Where things are

| Topic | File |
|---|---|
| App theme and tokens | `app/lib/ui/theme/`, `app/lib/ui/tokens/` |
| Trainer, collection, quests and persistence | `app/lib/state/trainer_provider.dart` |
| Stats, catch odds, wild spawns and quests | `app/lib/data/game/` |
| Theme, motion and customisation tokens | `app/lib/ui/theme/`, `app/lib/ui/motion/`, `app/lib/ui/tokens/` |
| Battle screens | `app/lib/features/battle/` |
| Social screens and QR | `app/lib/features/social/` |
| Supabase repository | `app/lib/data/social/` |
| Simulator seam | `server/src/battle/engine.ts` |
| Battle sessions and AI | `server/src/battle/session.ts` |
| HTTP routes | `server/src/index.ts` |
| Generated dex/moves data | `tools/gen-dex.mjs` → `app/assets/data/` |

## Conventions

- Node **22.18+** everywhere; the Showdown engine will not run on 18 or 20.
- The app only renders server snapshots; it never simulates a battle.
- The anon Supabase key is public; the `service_role` key is never used in the
  app or committed.
- Documentation changes should keep commands copy-pasteable and mention what a
  successful result looks like.
