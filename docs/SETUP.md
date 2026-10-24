# Setup guide — clean machine to phone

This guide takes you from nothing installed to Pokéventure running on a phone.
Follow it in order; each section ends with something you can check.

There are two ways to play:

- **Fastest:** install the APK built by GitHub Actions, and point it at a server
  someone already hosts. You only need the [APK](#7-get-an-apk) and a server URL.
- **Full local build:** install Flutter, Node and Android Studio, run the server,
  run the app, and optionally create your own Supabase project for Social.

Estimated time: 20 minutes for the APK route, 45–90 minutes for a full local
build on a fresh machine.

---

## 1. What you need

| Thing | Why | Version |
|---|---|---|
| Git | clone the repo and its Showdown submodule | any recent |
| Node.js | game server + battle simulator | **22.18+** |
| Flutter | build and run the app | 3.44+ / Dart 3.12+ |
| Java + Android SDK | Android builds | JDK 17 or 21, SDK 24+ |
| A terminal | all commands below | Git Bash on Windows is fine |

Optional:

- A [Supabase](https://supabase.com) project for the Social tab.
- A free host such as [Wispbyte](https://wispbyte.com) for a 24/7 server.
- A GitHub account for the APK workflow.

---

## 2. Install the tools

### Windows

1. **Git for Windows** — <https://git-scm.com/download/win>. Choose "Git Bash"
   during install; this guide's commands use Bash syntax.
2. **Node 22** — either the installer from <https://nodejs.org> (pick the LTS
   that is 22.18 or newer) or `nvm-windows`:
   ```bash
   nvm install 22.18.0
   nvm use 22.18.0
   ```
3. **Flutter** — follow <https://docs.flutter.dev/get-started/install/windows>.
   Put Flutter's `bin` folder on `PATH`.
4. **Android Studio** — install it, then in **Settings → SDK Manager** install
   an Android SDK platform (API 35 is fine) and the Android SDK command-line
   tools. Use the bundled JDK 21.
5. Verify in a **new** Git Bash window:
   ```bash
   git --version
   node -v          # must be v22.18.0 or newer
   flutter --version
   flutter doctor
   ```

If `flutter doctor` complains about Android licences:

```bash
flutter doctor --android-licenses
```

### macOS

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install --cask flutter android-studio
brew install node@22 git
flutter doctor
```

Use Android Studio's SDK Manager for the Android SDK. For an iOS build you also
need Xcode and CocoaPods; this guide targets Android.

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y git curl unzip xz-utils zip libglu1-mesa openjdk-21-jdk
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

Install Flutter from <https://docs.flutter.dev/get-started/install/linux>, add
it to `PATH`, then install Android Studio (or just the SDK + command-line
tools) and run:

```bash
flutter doctor --android-licenses
flutter doctor
```

**Checkpoint:** `node -v` prints v22.18 or newer and `flutter doctor` shows no
red errors for Android tooling. Warnings about Chrome/iOS are fine.

---

## 3. Get the code

The Showdown engine is a git submodule, so ask Git to fetch it too:

```bash
git clone --recurse-submodules https://github.com/ItzFallenMe/Pokeventure.git
cd PokeNext
```

Already cloned without the flag? Fix it with:

```bash
git submodule update --init --recursive
```

You should now have `vendor/pokemon-showdown/package.json`.

---

## 4. One-command bootstrap

```bash
./scripts/bootstrap.sh
```

What it does:

1. Refuses to continue on Node older than 22.
2. Initialises the submodule.
3. `npm ci` and `node build` inside `vendor/pokemon-showdown`.
4. `npm ci` in `server/`.
5. `flutter pub get` in `app/`.

The Showdown build takes a few minutes the first time. If you prefer to do it by
hand:

```bash
git submodule update --init --recursive
cd vendor/pokemon-showdown
npm ci
node build
cd ../../server
npm ci
cd ../app
flutter pub get
```

**Checkpoint:** `ls vendor/pokemon-showdown/dist/sim/index.js` exists and
`server/node_modules` exists.

---

## 5. Start the server

```bash
cd server
npm start
```

It prints:

```
Pokéventure server on http://0.0.0.0:8787 · formats: gen9randombattle, gen8randombattle
```

In another terminal:

```bash
curl http://localhost:8787/health
```

Expected response:

```json
{"ok":true,"engine":"pokemon-showdown","formats":["gen9randombattle","gen8randombattle"],"activeBattles":0}
```

Keep this terminal open. `Ctrl+C` stops the server.

---

## 6. Run the app

### Configure it with an env file (recommended)

The app reads its settings from `--dart-define` values, which you can keep in a
local `.env` file instead of typing them on every build:

```bash
cd app
cp .env.example .env
```

Open `.env` and set at least `API_BASE_URL`. Add `SUPABASE_URL` and
`SUPABASE_ANON_KEY` if you want Social. Then:

```bash
flutter run --dart-define-from-file=.env
```

`.env` is git-ignored, so keys never end up in the repository. The anon key is
public by design; never paste a Supabase **service-role** key into the app.
Without a `.env` file the app falls back to the emulator/localhost server
addresses below.

### Android emulator

1. Open Android Studio → **Device Manager** → create a Pixel device with a
   current system image.
2. Start it, then:
   ```bash
   cd app
   flutter devices       # the emulator should be listed
   flutter run
   ```

The app automatically uses `http://10.0.2.2:8787`, the emulator's alias for your
computer.

### Physical Android phone

1. Enable **Developer options → USB debugging** and connect the phone.
2. Accept the debugging prompt; `flutter devices` should list it.
3. Find your computer's LAN IP:
   - Windows: `ipconfig` → IPv4 address
   - macOS/Linux: `ifconfig` or `ip addr`
4. Set `API_BASE_URL=http://192.168.1.50:8787` in `.env`, then:
   ```bash
   cd app
   flutter run --dart-define-from-file=.env
   ```
   (or pass it directly: `flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8787`).

The phone and computer must be on the same Wi-Fi. If the Battle tab cannot
connect, open `http://192.168.1.50:8787/health` in the phone's browser; if that
fails, fix the firewall or network first.

### First run checklist in the app

1. **Welcome** asks for a trainer name and a starter. Pick one — you land on
   Home with a real level-5 partner.
2. **Home** shows the daily Pokémon, daily gift, quests and your party.
3. **Explore the zones → Catch now** rolls a real catch; the ball is consumed,
   the Pokémon joins the party or PC, and the Pokédex updates.
4. **Party** shows your collection; the PC starts empty and fills when the
   party is full.
5. **Pokédex** contains 1,025 species with descriptions, catch rates and
   evolutions.
6. **Battle → Battle AI** creates a real Showdown battle and shows four moves;
   finishing it pays coins and XP.
7. **Shop** buys a Poké Ball and the **Bag** count goes up.
8. **More → Settings** changes accent, avatar, title, theme, music and sound.
9. Force-quit and reopen: trainer, party, coins, bag, quests and settings
   persist.

---

## 7. Get an APK

### From GitHub Actions (recommended)

1. Fork or push the repo to GitHub.
2. You can set the build values once under
   **Settings → Secrets and variables → Actions → Variables**
   (`API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`), **or** type them
   directly into the manual run form. Use the Wispbyte address for
   `API_BASE_URL`, e.g. `http://203.0.113.10:25565`.
3. Open **Actions → APK → Run workflow** (fill the three optional fields if you
   did not set variables).
4. When it turns green, open the run and download **Artifacts →
   `pokeventure-apk`**.
5. Install on the phone:
   ```bash
   adb install -r pokeventure-main.apk
   ```
   or copy it to the phone and open it, allowing "install unknown apps" for your
   file manager.

The workflow runs the analyzer, all app tests and a release build. A tag such as
`v1.0.0` also attaches the APK to a GitHub Release.

### Locally

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=http://192.168.1.50:8787
```

Output: `app/build/app/outputs/flutter-apk/app-release.apk`.

Release builds currently use the debug signing key, which is fine for testing.
Updates built on another machine may require uninstalling the old app first.

---

## 8. Enable Social (optional)

1. Create a free project at <https://supabase.com>.
2. **Authentication → Providers → Anonymous sign-ins → Enable.**
3. **SQL Editor → New query**, paste the contents of
   [`supabase/migrations/0001_social.sql`](../supabase/migrations/0001_social.sql),
   run it.
4. **Project Settings → API**: copy **Project URL** and **anon public** key.
5. Build/run with:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

**Checkpoint:** the Social tab shows a trainer card with a name and a
six-character code. Tap **Show my QR** to see it. Add a second device or a
second install, enter the code, and accept the request on the first device.

If you see "Could not sign in to social", anonymous sign-ins are still off.
If you see the setup card, the build did not receive the two defines.

More: [SUPABASE.md](SUPABASE.md).

---

## 9. Host the server (optional)

The app needs a reachable server for battles. For a free always-on host:

1. Create a **Node 22** server at [Wispbyte](https://wispbyte.com).
2. Upload the repo, or clone it in the panel console.
3. Run once:
   ```bash
   bash scripts/wispbyte-setup.sh
   ```
4. Set the startup command:
   ```bash
   bash scripts/wispbyte-start.sh
   ```
5. Note the allocated port, and check
   `http://HOST:PORT/health` from your phone.
6. Build the APK with `API_BASE_URL=http://HOST:PORT` (or set the GitHub
   variable).

Other free options, including Render, Koyeb and Oracle Cloud, are covered in
[HOSTING.md](HOSTING.md).

---

## 10. Update the app later

```bash
git pull
git submodule update --init --recursive
cd app && flutter pub get
cd ../server && npm ci
```

Rebuild the APK or rerun `flutter run`. If the database schema changes,
re-running `supabase/migrations/0001_social.sql` is safe (it is idempotent).
New migrations, when added, live in the same folder and run in order.

---

## Troubleshooting

### The server crashes immediately

| Error | Cause | Fix |
|---|---|---|
| `Cannot find module .../pokemon-showdown/dist/sim/index.js` | Submodule not built | `git submodule update --init --recursive`, then `cd vendor/pokemon-showdown && npm ci && node build` |
| `EADDRINUSE 0.0.0.0:8787` | Another process owns the port | Stop the other server; on a panel use its allocated `SERVER_PORT` and do not run `npm start` manually next to the startup command |
| Crash mentions Node 18 | Panel image is too old | Select a Node 22 image; rerun the setup script |
| `npm ci` fails in Showdown | Node/npm mismatch or partial download | `rm -rf vendor/pokemon-showdown/node_modules` and retry |

### The app cannot reach the server

1. From the computer: `curl http://localhost:8787/health`.
2. From the phone's browser: `http://COMPUTER_IP:8787/health`.
3. Emulator uses `10.0.2.2`, a real phone uses the LAN IP. Rebuild after
   changing `API_BASE_URL`.
4. Allow port 8787 through the OS firewall.
5. Some networks isolate devices from each other (guest Wi-Fi). Use a hotspot or
   host the server publicly.

### Flutter problems

| Error | Fix |
|---|---|
| `flutter: command not found` | Add Flutter's `bin` to `PATH`, open a new terminal |
| `No Android SDK found` | Install the SDK via Android Studio, accept licences |
| Gradle/Java error | Use JDK 17 or 21; `flutter doctor -v` shows which Java is used |
| Emulator is very slow | Enable hardware acceleration; a physical phone is faster |
| `CocoaPods` error on macOS/iOS | `sudo gem install cocoapods`, then `pod install` in `app/ios` |

### Social problems

| Symptom | Fix |
|---|---|
| Setup card | Rebuild with `SUPABASE_URL` and `SUPABASE_ANON_KEY` |
| "Could not sign in" | Enable anonymous sign-ins in Supabase |
| `permission denied for table players` | The migration did not run, or ran in the wrong project |
| Friend code says "No trainer uses that code" | Check the six characters; codes exclude `0/O/1/I` |
| QR camera does not open | Grant camera permission; type the code as a fallback |

### APK problems

| Symptom | Fix |
|---|---|
| Workflow fails on `flutter test` | Run `flutter test` locally first; the workflow uses the same command |
| Workflow fails on Gradle | Check the pinned Flutter version in `.github/workflows/apk.yml` |
| APK installs but battles fail | `API_BASE_URL` was not baked in, or points at localhost |
| "App not installed" | Uninstall the previous copy; signatures or versions differ |

---

## Clean reinstall

```bash
# stop the server, then:
cd app
flutter clean
cd ../server
rm -rf node_modules
cd ../vendor/pokemon-showdown
rm -rf node_modules dist
cd ../..
./scripts/bootstrap.sh
```

This keeps your local save on the phone. To reset game progress use
**More → Settings → New game** (it clears the save and returns to starter
selection).
