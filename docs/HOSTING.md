# Hosting the game server

> Part of the [documentation index](README.md). New to the project? Do the
> [local setup](SETUP.md) first, then host the server and rebuild the APK with
> your public `API_BASE_URL`.

The server is a long-running Node process that keeps battle sessions in memory,
so serverless platforms (Vercel, Netlify, Lambda, Cloudflare Workers) are the
wrong fit. You need a container or VM that stays alive.

**Jump to:** [Wispbyte](#wispbyte-no-sleep-panel-console) ·
[Fixed-startup panel](#node-panel-with-a-fixed-startup-command) ·
[Render](#render-easiest) · [Koyeb](#koyeb) ·
[Northflank](#northflank-sandbox) ·
[Oracle](#oracle-cloud-always-free-always-on) ·
[Home + tunnel](#home-machine--cloudflare-tunnel) ·
[Notes](#notes-for-any-host)

Free tiers change often — the limits below were checked in October 2026. Re-read
the provider's pricing page before relying on one.

## The short version

| Option | Card needed | Always awake | Effort | Good for |
|---|---|---|---|---|
| **Wispbyte** | No | **Yes** — free 24/7 | Medium | A panel-based Node host that never sleeps; scripts included |
| **Any Node panel** | No | Depends on the plan | Low | Hosts with a fixed `MAIN_FILE` startup; root `index.js` bootstraps everything |
| **Render free** | No | No — sleeps after 15 min idle | Low | Trying the app with friends; blueprint included |
| **Koyeb free** | No | No — scales to zero | Low | One small web service in the EU/US |
| **Northflank Sandbox** | No | No — sandbox service | Low | A second free container |
| **Oracle Cloud Always Free** | Yes (verification) | **Yes** | Medium | 24/7 play, later a database |
| **Home PC + Cloudflare Tunnel** | No | As long as it runs | Medium | Zero monthly cost, full control |

Fly.io and Heroku no longer have a free tier for new accounts. Render, Koyeb and
Northflank all sleep idle services: the first request after a nap takes roughly
30–60 seconds, and any battle in progress is lost. Battles are short and are
created per queue, so this is survivable for testing.

## Wispbyte (no sleep, panel console)

Wispbyte is a free Pterodactyl-style host: Node 22+ images, SFTP/GitHub upload,
a console and an always-on 512 MB container. Because it is not a Dockerfile
builder, the Showdown engine has to be built once from the console. Two scripts
in this repo do that.

1. **Create a server** at [wispbyte.com](https://wispbyte.com) and pick a
   **Node.js** image (Node 22 or newer). Many panel eggs default to Node 18,
   which the engine cannot run — change the image in **Startup → Docker image /
   Node version** before doing anything else. `node -v` must print v22.18+.
2. **Get the code in.** Use the panel's GitHub import if it is offered, or
   upload the repo over SFTP. The `vendor/pokemon-showdown` folder is a
   submodule; if your upload skips submodules, the setup script clones the
   engine for you.
3. In the **console**, run:

   ```bash
   bash scripts/wispbyte-setup.sh
   ```

   It clones/builds Showdown if needed and installs `server/node_modules`.
   This takes a few minutes the first time.
4. Set the **startup command** to:

   ```bash
   bash scripts/wispbyte-start.sh
   ```

   On later boots the script skips setup and starts `npm start`.
5. Note the **allocated port**. Pterodactyl exposes it as `SERVER_PORT`, which
   the server reads automatically (`PORT` also works). Start the server, then
   check `http://HOST:PORT/health`.
6. Build the APK with that address:

   ```bash
   flutter build apk --release \
     --dart-define=API_BASE_URL=http://HOST:PORT
   ```

   Or set the `API_BASE_URL` repository variable for the GitHub workflow. If
   the host gives you an HTTPS domain, use that instead.

512 MB is the tight part. The engine with a couple of battles fits, but avoid
running other bots on the same server. Wispbyte asks for a login every two
weeks to keep the server; that is enough to keep a hobby server alive.

### Common Wispbyte errors

- **`EADDRINUSE: address already in use 0.0.0.0:8787`** — two things are trying
  to listen. Usually a manually started `npm start` is still running next to
  the panel's startup command, or an older copy that did not read
  `SERVER_PORT` is running. Press **Stop**, update the files (the current
  server reads `PORT`, then `SERVER_PORT`, then 8787), and start once. Never
  run `npm start` by hand while the startup command is active.
- **`Node.js v18.19.1` in a crash trace** — the panel is on Node 18.
  `pokemon-showdown` needs 22.18+. Switch the Node image and rerun
  `bash scripts/wispbyte-setup.sh`; the script refuses to continue on Node 18.
- **`Cannot find module .../pokemon-showdown/dist/...`** — Showdown was not
  built on the panel. Run `bash scripts/wispbyte-setup.sh` once from the
  console; it clones and builds the engine when the uploaded files lack it.

## Node panel with a fixed startup command

Many Pterodactyl-style Node eggs cannot change their startup command. They run
something like:

```bash
if [ -f /home/container/package.json ]; then /usr/local/bin/npm install; fi
/usr/local/bin/node "/home/container/${MAIN_FILE}" ${NODE_ARGS}
```

The repository root now contains `index.js` for exactly this case. It:

1. checks for Node 22.18+;
2. clones Showdown if the upload skipped the submodule;
3. installs Showdown and the server without npm lifecycle scripts, then fetches
   esbuild's platform binary explicitly (npm 12 blocks that postinstall);
4. builds Showdown once;
5. starts the TypeScript server in the foreground.

Set the panel's **`MAIN_FILE` startup variable to `index.js`** and choose a
**Node 22.18+** image. Then start the server. The first boot spends a few
minutes building Showdown; later boots detect the build and start immediately.

If `MAIN_FILE` cannot be changed at all, ask the host to set it to `index.js`.
A plain `npm start` in the repository root also works for hosts that allow a
custom command.

Check `https://HOST:PORT/health`; set that URL as `API_BASE_URL` and rebuild
the APK.

## Render (easiest)

A `render.yaml` blueprint is in the repo root.

1. Push the repo to GitHub (the `vendor/pokemon-showdown` submodule must be
   committed — Render clones submodules automatically).
2. Render dashboard → **New → Blueprint** → select the repo → **Apply**.
   It reads `render.yaml`, builds the root `Dockerfile`, and exposes `/health`.
3. Wait for the first build. It installs Showdown and runs `node build`, so it
   takes a few minutes; later deploys reuse the Docker layer cache.
4. Copy the service URL, e.g. `https://pokeventure-server.onrender.com`, and
   check it:

   ```bash
   curl https://pokeventure-server.onrender.com/health
   ```

5. Point the app at it. For a one-off build:

   ```bash
   cd app
   flutter build apk --release \
     --dart-define=API_BASE_URL=https://pokeventure-server.onrender.com
   ```

   For the GitHub Actions build, set a repository variable instead:
   **Settings → Secrets and variables → Actions → Variables → New variable**
   `API_BASE_URL` = the service URL, then re-run the APK workflow.

Free plan caveats: 512 MB RAM, 750 instance hours per month, sleeps after 15
minutes without traffic. The simulator plus a handful of sessions fits in
512 MB, but it is not a capacity guarantee.

## Koyeb

Free instance: one web service, 512 MB RAM, 0.1 vCPU, Frankfurt or Washington.
That CPU is weak — fine for a couple of testers, slow for a crowd.

1. Push the repo to GitHub.
2. Koyeb → **Create Service → GitHub**, pick the repo, builder **Dockerfile**,
   Dockerfile path `Dockerfile`.
3. Set the port to `8787` (or leave `PORT` unset and expose 8787) and the
   health check path to `/health`.
4. Scale the instance type to **Free**, deploy, and copy the `*.koyeb.app` URL
   into `API_BASE_URL` as above.

## Northflank Sandbox

Free, no card: two services, two jobs, one database. Same Dockerfile flow —
create a service from the repo, choose **Dockerfile** build, port 8787, HTTP
health check `/health`, and use the generated HTTPS domain.

## Oracle Cloud Always Free (always-on)

The best free option if the server should stay up: an Ampere A1 VM with
2 OCPU / 12 GB RAM (Oracle halved the old 4/24 allowance in 2026) plus 200 GB
of block storage. It needs a card for identity verification, but Always Free
resources are not billed.

1. Create an **Always Free** Ampere A1 instance with Ubuntu 24.04. Add your SSH
   key and open ports 80/443 in the subnet's security list.
2. Install the toolchain:

   ```bash
   sudo apt update
   sudo apt install -y git curl
   curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

3. Clone with the engine and bootstrap:

   ```bash
   git clone --recurse-submodules https://github.com/iwannabeyourshere/PokeNext.git
   cd PokeNext
   ./scripts/bootstrap.sh
   ```

4. Run it under systemd, `/etc/systemd/system/pokeventure.service`:

   ```ini
   [Unit]
   Description=Pokeventure game server
   After=network.target

   [Service]
   WorkingDirectory=/home/ubuntu/PokeNext/server
   ExecStart=/usr/bin/npm start
   Environment=PORT=8787
   Restart=always
   User=ubuntu

   [Install]
   WantedBy=multi-user.target
   ```

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now pokeventure
   curl localhost:8787/health
   ```

5. Put HTTPS in front with Caddy (free certificates):

   ```bash
   sudo apt install -y caddy
   ```

   `/etc/caddy/Caddyfile`:

   ```
   pokeventure.example.com {
       reverse_proxy 127.0.0.1:8787
   }
   ```

   Point a DNS A record at the VM's public IP, then
   `sudo systemctl reload caddy`. Use `https://pokeventure.example.com` as
   `API_BASE_URL`.

## Home machine + Cloudflare Tunnel

If you already have a PC or Raspberry Pi that stays on, Cloudflare Tunnel gives
you a public HTTPS URL without opening router ports:

```bash
cloudflared tunnel --url http://localhost:8787
```

Run the server and `cloudflared` as services so they survive reboots. The URL is
temporary with the quick tunnel; use a named tunnel and a domain you own for a
stable address.

## Notes for any host

- **Node 22.18+** is required by current `pokemon-showdown`. Node 18/20 will
  fail or crash; check the image/version in your host's panel.
- The server reads `PORT` first, then `SERVER_PORT` (Pterodactyl-style panels),
  and falls back to `8787`.
- The Docker image is built from the repo root so the submodule is inside the
  build context; `vendor/pokemon-showdown` must be present when building.
- Battles live in memory. A restart or a free-tier nap drops them; the app
  reports the expired session and you can queue again. A database-backed
  session store is on the roadmap, not in this build.
- The app talks to the server over plain HTTP for local development and allows
  cleartext traffic. Use HTTPS in public deployments.
- `GET /health` is the readiness check; it returns the engine version, supported
  formats and the number of live battles.
