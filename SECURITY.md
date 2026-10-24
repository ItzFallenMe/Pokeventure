# Security policy

## Supported versions

Pokéventure is a single-branch project. The `main` branch is the only supported
version; there are no maintained release branches. Security fixes land on `main`
and in the next APK build.

## Reporting a vulnerability

Please do **not** open a public issue for a security problem.

- Use GitHub's private report form: **Security → Report a vulnerability** in the
  repository, or
- email **vedantyadav196@gmail.com** with a short description, the affected
  file or endpoint, and steps to reproduce.

You can expect an acknowledgement within a few days. This is a hobby project
maintained by volunteers, so please allow reasonable time for a fix before
disclosing anything publicly.

## What is in scope

| Area | Examples |
|---|---|
| Game server (`server/`) | Forged friend-battle tokens, acting in another player's battle, crashes or memory exhaustion from crafted requests |
| Supabase schema (`supabase/`) | Row-level-security gaps that let a player read another player's data, answer someone else's friend request or write to a profile that is not theirs |
| Flutter app (`app/`) | XSS-like injection through trainer names, unsafe deep links, leaked credentials in a release APK |
| CI (`.github/workflows/`) | Workflow injection through branch names, pull-request titles or `workflow_dispatch` inputs |

## Out of scope

- Missing HTTPS on your own deployment. The app allows cleartext HTTP so a
  panel-hosted server without a certificate works; put a TLS proxy (Caddy,
  Cloudflare) in front for public use.
- The **anon / publishable** Supabase key. It is designed to be shipped inside
  clients; row-level security is what protects the data.
- Battles lost when the server restarts. Sessions are in memory by design.
- Anything that requires the `service_role` key or direct database access.
- Rate limiting and abuse protection on a free host. Add a proxy if you run a
  public server.
- Trademark or licensing questions about Pokémon. See [LICENSE](LICENSE).

## Secrets policy

- Only the Supabase anon key may ever reach the app. Never ship or commit the
  `service_role` key, database passwords, SMTP credentials or personal access
  tokens.
- Build-time values (`API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`) belong
  in GitHub Actions **variables**, not in source files.
- Release APKs are currently signed with the debug key, which is fine for
  testing but means anyone can rebuild an APK with the same signature. Configure
  a private keystore before distributing builds widely.
- If you believe a secret was committed, rotate it first, then rewrite history.
  Removing a commit is not enough once it has been pushed to a public
  repository.

## Hardening a public deployment

1. Serve the game server over HTTPS (Caddy, nginx with certificates, or a tunnel).
2. Keep `vendor/pokemon-showdown` and the server dependencies updated; the
   engine is the largest attack surface.
3. Leave Supabase row-level security enabled and review the policies in
   [`supabase/migrations/0001_social.sql`](supabase/migrations/0001_social.sql)
   before changing the schema.
4. Do not reuse one Supabase project for a private and a public deployment.
5. Watch the server logs for repeated `/api/friend-battles` creations; a public
   free host is easy to exhaust.
