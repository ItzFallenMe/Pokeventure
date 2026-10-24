# Pokéventure documentation

Start with the guide that matches what you want to do.

| If you want to… | Read |
|---|---|
| Install everything and put the app on a phone | **[SETUP.md](SETUP.md)** |
| Understand the game and product design | [GAME_DESIGN.md](GAME_DESIGN.md) |
| Put the game server online for free | [HOSTING.md](HOSTING.md) |
| Turn on friends, QR codes and social | [SUPABASE.md](SUPABASE.md) |
| Call the server from your own client | [API.md](API.md) |

## Recommended order

1. **[SETUP.md](SETUP.md)** — tools, clone, bootstrap, run locally, build an APK.
2. **[HOSTING.md](HOSTING.md)** — choose a free host and start the game server.
3. **[SUPABASE.md](SUPABASE.md)** — create the social database (optional).
4. Rebuild the APK with `API_BASE_URL` and the two Supabase values.
5. **[API.md](API.md)** — if you want to script or extend the backend.

## The short version

```bash
git clone --recurse-submodules https://github.com/iwannabeyourshere/PokeNext.git
cd PokeNext
./scripts/bootstrap.sh

# terminal 1
cd server && npm start

# terminal 2
cd app && flutter run
```

Then open **Battle → Random battle**. Social needs Supabase; see
[SUPABASE.md](SUPABASE.md).

## Repository map

```
app/                 Flutter client (Android/iOS)
server/              Node + TypeScript game server
vendor/pokemon-showdown  pinned simulator submodule
supabase/migrations/ social schema + row-level security
docs/                this folder
scripts/             bootstrap and panel-host scripts
Dockerfile           container image for the server
render.yaml           Render blueprint
.github/workflows/   APK and server CI
```

## Where things are

| Topic | File |
|---|---|
| App theme and tokens | `app/lib/ui/theme/`, `app/lib/ui/tokens/` |
| Party/PC rules and persistence | `app/lib/state/party_provider.dart` |
| Battle screens | `app/lib/features/battle/` |
| Social screens and QR | `app/lib/features/social/` |
| Supabase repository | `app/lib/data/social/` |
| Simulator seam | `server/src/battle/engine.ts` |
| Battle sessions and AI | `server/src/battle/session.ts` |
| HTTP routes | `server/src/index.ts` |
| Generated dex/moves data | `tools/gen-dex.mjs` → `app/assets/data/` |
