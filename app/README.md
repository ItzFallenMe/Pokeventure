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
`http://127.0.0.1:8787` elsewhere. Point it somewhere else with:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8787
```

Social is optional and only turns on when built with both Supabase values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

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
| `lib/features/` | home, catch, party/PC, dex, bag, shop, battle, social, more |
| `lib/data/` | models, dex and move loaders, type chart, battle and friend-battle APIs |
| `lib/data/social/` | Supabase repository, trainer models, startup bootstrap |
| `lib/state/` | Riverpod party/PC, shop and theme state, persisted locally |
| `lib/ui/` | theme, spacing and type tokens, sprites, shared widgets |
| `assets/data/` | generated `dex.json` and `moves.json` |

Full documentation: [setup](../docs/SETUP.md) ·
[hosting](../docs/HOSTING.md) · [Supabase](../docs/SUPABASE.md) ·
[API](../docs/API.md) · [design](../docs/GAME_DESIGN.md).
