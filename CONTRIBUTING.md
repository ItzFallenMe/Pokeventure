# Contributing

Thanks for looking. Pokéventure is a small fan project, and focused pull
requests are very welcome.

## Before you start

- Read the [setup guide](docs/SETUP.md) so you can run the app and the server.
- For anything larger than a bug fix, open an issue first. It avoids building
  something that does not match the direction in
  [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md).
- By contributing you agree that your work is licensed under the
  [MIT license](LICENSE).

## Development loop

```bash
git clone --recurse-submodules https://github.com/iwannabeyourshere/PokeNext.git
cd PokeNext
./scripts/bootstrap.sh

# terminal 1 – game server
cd server && npm start

# terminal 2 – app
cd app && flutter run
```

The Showdown engine lives in `vendor/pokemon-showdown` as a submodule. Do not
edit it; all integration goes through `server/src/battle/engine.ts`.

## Checks before a pull request

```bash
cd app    && flutter analyze && flutter test
cd server && npm run typecheck && npm test
```

Both suites must pass. The same commands run in CI
([APK workflow](.github/workflows/apk.yml),
[Server workflow](.github/workflows/server.yml)).

## What a good change looks like

- **Small and focused.** One fix or feature per pull request; no drive-by
  reformatting of unrelated files.
- **Tested.** Add a test for a new rule, endpoint or widget behaviour. The
  existing tests are the specification for party limits, battle snapshots and
  social flows.
- **Consistent.** Match the existing Dart and TypeScript style, spacing tokens
  (`AppSpacing`, `AppRadius`), theme colours and file layout. Run
  `dart format` on the files you touched.
- **Honest in the UI.** Do not add placeholder screens or fake numbers. If a
  feature is not implemented, leave it out rather than showing invented data.
- **Documented.** Update the README or the relevant file in `docs/` when you
  change setup, configuration, endpoints or behaviour.

## Areas where help is most useful

- Real accounts (email/OAuth) and syncing the collection across devices.
- Party-based battle formats and server-side teams.
- Crafting, berry farming, trading and a market.
- Offline sprite caching.
- Accessibility: screen-reader labels, touch targets, larger text.
- Tests for the battle arena and the social screens.

## Reporting bugs

Use the [bug report form](.github/ISSUE_TEMPLATE/bug_report.yml). Include the
app version or commit, the Android version and the exact steps. For a battle
problem, add the turn log from the arena screen. Security issues go through
[SECURITY.md](SECURITY.md), not the public issue tracker.

## Code of conduct

Participation is covered by the [Code of Conduct](CODE_OF_CONDUCT.md). Be
decent; maintainers may remove comments or contributions that are not.
