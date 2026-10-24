# Pokéventure — Game & App Design Document

> Working title. A mobile collection RPG in the spirit of **Pokétwo**, with **Pokémon Showdown** as the real battle engine, plus trading, guilds, raids, seasons and a live PvP ladder.
>
> Status: **design approved; app and battle server built and shipping APKs via CI**.
> Stack assumed: **Flutter** (client) + **Node.js/TypeScript** (game server), matching the repo's devcontainer.
>
> **Built so far:** starter onboarding, six generated exploration zones with
> live spawns, a data-driven catch minigame (species catch rate, five balls,
> berries, timing, flee, 1/2048 shiny), real IVs/natures/EVs/stats,
> XP/level-up/move learning/evolution, party of six with PC storage, daily
> quests, streaks, a 1,025-species Pokédex with flavour text and learnsets,
> bag/shop with usable items, and a Node/TS server running **real Showdown
> battles vs an AI** through the vendored `pokemon-showdown` submodule.
> Type-coloured battle moves with live effectiveness, Supabase-backed trainer
> cards, QR friend codes and **human-vs-human friend battles**. Motion system,
> confetti/shiny/level-up celebrations, original music and SFX, Pokémon cries,
> six accent palettes, avatars/titles, dynamic colour, and 55 Flutter tests.
> Still missing: full accounts (saves are device-local), server-side collection
> sync, campaign gyms, ranked ladder, market/trading, guilds and raids.

---

## 1. One-liner

> Catch Pokémon in a living world, raise them with real IVs/EVs/natures, and battle other players on the actual Showdown simulator — on your phone, in 3-minute sessions.

**Why it can work:** Pokétwo proved the *collection + scarcity + PvP-lite* loop is addictive in text. Showdown proves the *battle depth* is there. Nobody has shipped the two together as a polished mobile game. The missing piece Pokétwo never had is **real battles**; the missing piece Showdown never had is **ownership, progression and a reason to care about your team**.

---

## 2. Design pillars

| Pillar | What it means in practice |
|---|---|
| **Own it** | Every Pokémon is a unique, server-authoritative instance (IVs, nature, ability, shiny, ball, catch date, origin). Trading is first-class. |
| **Real battles** | Showdown's engine, not a simplified clone. Items, abilities, weather, hazards, tera, doubles — all of it. |
| **Small sessions** | 30s catch loop, 3–5 min battle, daily quests. No 40-minute commitments unless you want ranked. |
| **Fair, not pay-to-win** | Money buys cosmetics, convenience and season passes — never stats, IVs or catch rate. |
| **Legible depth** | A beginner can catch and auto-battle; a competitive player can open the full team builder with EV sliders and Showdown import/export. |
| **Feel good** | Material 3 foundation, custom brand skin, 60/120fps, haptics, skippable celebrations. Polish is a feature, not a phase. |

---

## 3. Core loop

```
Explore a zone (energy)  ──▶  Pokémon spawns
        │                        │
        │                        ▼
        │                 Catch minigame (ball + timing + berries)
        │                        │
        │                        ▼
        │                 Collection / Dex progress ──▶ Quests, rewards, level
        │                        │
        ▼                        ▼
   Gather resources      Build a team (EVs, moves, items)
        │                        │
        └──────────▶  Battle: PvP ladder · NPC gyms · raids · tournaments
                                 │
                                 ▼
                     Rating, season rewards, currency, cosmetics
```

Secondary loops: **trading / market**, **guild raids**, **breeding & shiny hunting**, **daily/weekly quests**, **season ladder**.

---

## 4. Feature set

### 4.1 Party & PC — the 6-Pokémon rule

This is the spine of the collection game, borrowed from the mainline games because it is what creates the tension Pokétwo lacks.

- **Party = 6 slots, hard cap.** The party is the *only* squad that can battle. It is a game rule, never a monetised limit — there is no "buy a 7th slot".
- **Everything else lives in the PC.** Boxes of 30, 300 slots free (more via play or gems, never required). Fully searchable and sortable.
- **Catching with a full party never blocks you:** the new Pokémon is auto-deposited to the PC with a toast and a "view" shortcut.
- **Party screen:** six cards (sprite, level, HP/status, held item, shiny star), drag to reorder (lead slot matters in some formats), two-tap swap with the PC, "heal all", and an **auto-fill** suggestion that scores type coverage + IVs + synergy. A party-wide legality badge warns before you queue.
- **PC screen:** grid/list toggle, filters (species, type, shiny, IV floor, nature, level, ribbon, favourite, locked), sorts (recent, level, IV total, Dex no., name), multi-select → release / move to party / list on market / add to trade, "deposit all duplicates", named boxes, and a side-by-side **compare** view.
- **Battles use the party and only the party.** Showdown's team preview, switching, fainting and 6v6 rules map 1:1. The PC is unreachable mid-battle. Bag items are not usable in ranked — held items only.
- **Format sizes come out of the 6:** 6v6 singles (ranked OU), 6-pick-4 doubles (VGC-style), 3v3 gym battles, 1v1 duels, 2v2 multi. The validator refuses a queue if the party can't fill the format or breaks a clause (species clause, item clause, banlist).
- **Set Library (the Showdown on-ramp):** saved competitive sets (species + item + ability + nature + EVs + moves) apply to any owned Pokémon of that species in one tap, with legality checking and a diff preview. Paste a Showdown export → get a set; "apply to party" fills all six. Nobody should ever enter 510 EVs by hand twice.
- **Builds belong to the Pokémon instance**, so changing a member's moves/EVs updates it everywhere, including saved teams — no silent drift between team and box.
- **Competitive level scaling:** ranked and random formats auto-scale to level 50/100 with EVs applied, so a fresh catch can compete without a four-hour grind. Campaign and gyms keep real levels. This single decision decides whether PvP has a population.
- **Healing model (configurable):** HP/PP persist between campaign, tower and gym battles; restored by Potions, a free Pokémon Center, or a paid full-heal. PvP, raids and tournaments always start at full HP/PP, so competitive is never a pay-to-heal loop. If playtests call it friction, flip one flag to auto-heal everywhere.
- **Storage pressure is the point:** full boxes push you to release duplicates for candy, trade, or chase Dex completion — the pressure Pokétwo gets from its catch feed, without the spam.

### 4.2 Catching & spawns (the Pokétwo heart)

Pokétwo spawns appear in Discord chat and you type the name. A mobile app has no chat feed, so the spawn surface is **exploration**:

- **Zones** (region + biome + weather + time-of-day), each with its own spawn table and rarity tiers.
- Spawns appear on the zone screen every 20–90s while the app is open (an "incense"/lure item can force spawns; idle/offline accumulation is capped so it can't be farmed).
- **Catch minigame:** tap the spawn → pick a ball → a shrinking timing ring (perfect / great / nice) modifies catch odds → server rolls the result. Berries, ball tier, species catch rate, level and status all feed the formula.
- **Shiny** Pokémon have a distinct spawn animation and are announced in the zone feed. Base rate 1/2048 (Shiny Charm 1/1024; community-day events much higher).
- **Rarity tiers:** Common / Uncommon / Rare / Epic / Legendary / Mythical, plus **event-only** and **regional**.
- **Fleeing:** failed catches can make the Pokémon flee (per-species flee rate). No "spam ball until caught".
- **First-catch bonus:** new species in your Dex pay coins + XP.
- **Legendaries** don't spawn randomly; they come from raids, quest chains and season rewards.

Anti-abuse: every spawn is generated server-side with a server seed, has a TTL, and is bound to the user + zone; the catch roll happens server-side.

### 4.3 Collection & progression

Every instance tracks:

| Field | Notes |
|---|---|
| Species / form | All gens 1–9, alternate forms, regional forms, megas/primals as battle-only forms |
| Level / XP | Level 1–100, XP curve configurable; candy from releasing duplicates |
| IVs | 0–31 per stat, hidden by default; "IV scanner" item or NPC reveals |
| EVs | 0–510, editable with vitamins/feathers, reset item |
| Nature | 25 natures, mint items to change |
| Ability | normal + hidden ability, Ability Patch item |
| Moves | 4 slots, learned by level, TMs, tutors, egg moves |
| Shininess | server-rolled, immutable |
| Ball / caught zone / date / OT | provenance for trading and "collection value" |
| Nickname, favorite flag, lock flag | |
| Held item | from inventory, removed on trade |

- **Pokédex** with per-region completion %, form dex, shiny dex, and rewards at 25/50/75/100%.
- **Storage:** box system with filters (species, shiny, IV floor, level, nature), search, sort, mass-release.
- **Evolution:** level, stone, trade, friendship, time-of-day, location; evolution animation + Dex registration.
- **Breeding:** daycare, egg groups, egg moves, nature/ability inheritance, Masuda-style shiny boost, egg hatching tied to walking distance or a step counter (HealthKit / Google Fit optional).
- **Candy & mastery:** each species has a mastery level that unlocks a cosmetic badge and a small non-combat perk (e.g. +1% catch rate for that species).

### 4.4 Training & optimisation

- **EVs:** vitamins (10 per stat), feathers (+1), EV-reducing berries, Reset Bag; EV training via horde battles and a small training minigame, not just item buying.
- **Natures:** mints. **Ability:** Ability Capsule (normal↔normal), Ability Patch (→ hidden).
- **IVs:** hidden by default; **IV Judge** unlocked at gym 3, or a consumable scanner. **Hyper Training** at level 100 with Bottle Caps sets a stat to 31 (nature/EVs still matter).
- **Moves:** level-up, TM/TR items, egg-move tutor, move reminder/deleter (free, unlimited — never charge for correcting a mistake).
- **PP Ups / PP Max**, Rare Candy, EXP Candy S/M/L, Lucky Egg, party-wide EXP Share.
- **"Battle-ready" button:** shows the exact item + candy cost to turn a random catch into a standard competitive set, then does it in one tap. This is the single biggest QoL feature for converting casual players into ranked players.
- **Legality checker explains itself:** every rejection says which rule failed (illegal move combo, banned item, clause, level cap) and offers the fix.

### 4.5 Battle system (Showdown engine)

**Formats at launch**

| Format | Notes |
|---|---|
| Random Battle (singles) | Zero team-building barrier; the onboarding competitive mode; Showdown-generated teams |
| Custom Game (singles) | Your own team, full control, casual |
| OU-style ranked singles | Level 100, standard clauses, season ladder |
| Doubles (VGC-ish) | For the competitive crowd; second ranked queue |
| Gym / NPC battles | Fixed teams, AI opponent, level caps per gym |
| Raids | Co-op vs a boss (4 players or async) |
| Tournaments | Scheduled brackets, 8/16/32 players, auto-reporting |

**How it works technically**

- Battles run **only on the server** inside a battle worker using **`smogon/pokemon-showdown`**, vendored as a pinned submodule (see §6.3).
- Each battle is a `BattleStream`; `BattleStreams.getPlayerStreams()` gives an `omniscient` stream plus **per-side streams that already redact hidden information**. That is the whole anti-cheat story: the client only ever sees what Showdown says it may see (`|split|` handling included).
- Clients receive Showdown protocol lines (`|move|`, `|switch|`, `|-damage|`, `|request|`…) over WebSocket, translated into animations by a protocol interpreter in the Flutter client.
- Turn timer: 60s normal / 15s reserve bank, auto-forfeit on timeout, reconnect window with full state replay.
- **Replays:** store `seed + format + both packed teams + choice log + simVersion` → deterministic rewatch and shareable replay links.
- **PvE AI:** `RandomPlayerAI` for wild/gym grunts at first; a heuristic AI (type effectiveness + hazard/status awareness) for gym leaders; difficulty tiers per gym.
- **Ladder:** Glicko-2 or Elo per format per season, placement matches, decay, soft reset each season.
- **Matchmaking:** Redis-backed queue, expanding rating window every 5s, format + party-size constraints, region ping preference.

**Team builder (full Showdown parity)**

- Species picker with search/filter, sprite grid.
- EV/IV sliders, nature, ability, item, 4 moves with legality checking via the **team validator** (banned moves, illegal combos, format bans).
- Auto-suggest "standard set" presets, damage-calc preview (`@smogon/calc`) for common threats.
- **Import/Export** in Showdown packed-team format — this is a killer feature for migrating competitive players in.
- Saved teams, folders, "quick team" from your box, rent-a-team for new players.

### 4.6 Game modes

Beyond the ranked queue, these are the modes that give the game a daily shape:

| Mode | What it is | Notes |
|---|---|---|
| **Campaign** | One region at launch: routes, towns, rival, 8 gyms, Elite Four, Champion | Gates features by badge (trade at 2, market at 3, ranked at 4); level caps per gym |
| **Gym rematches** | Daily/weekly NPC rematches with scaling teams | Coins + items, no story block |
| **Battle Tower** | Endless floors, 3v3, weekly reset, rental teams allowed | The solo grind that doesn't need a story |
| **Raids** | Co-op boss (4 players) or async contribution | Boss has HP multiplier, shields and phases; catch chance on clear |
| **Tournaments** | Scheduled brackets (8/16/32), single elim, Bo3 finals | Coin entry, prize pool, automatic reporting, spectate |
| **Weekly playlist** | Rotating format: Monotype, Little Cup, 1v1, Doubles, Draft, Random | Its own mini-ladder and cosmetic reward |
| **Async battles** | Correspondence PvP, up to 24h per move, vs friends/guild | Perfect for mobile; notifications when it's your turn |
| **Custom lobbies** | Invite code, any format, rule toggles (level, clauses, timer), spectate on/off | The "play with friends" escape hatch |
| **Spectating** | Live battle viewer, quick emotes, "replay of the day" | Shareable replay card image |
| **Safari Zone** | Timed session, special balls, rare flee-heavy spawns, entry ticket | Coin/gem sink, high shiny odds |
| **Fishing** | Timing minigame for water spawns, rods as key items | Cheap content, good variety |
| **Outbreaks / hordes** | 3–5 simultaneous spawns, boosted shiny rate | Server-scheduled world events |
| **Global goals** | Server-wide counters ("catch 1M Pidgey") with tiered rewards | Community feel, no extra content cost |
| **Player gyms** | Top ladder players hold a gym title for a season, set a team, defend it | Prestige + badge for challengers |
| **Champion defence** | Beat the E4 → your team becomes the server's Champion team to dethrone | Seasonal reset, huge bragging rights |
| **Contests** (P2) | Cool/Beauty/Cute/Clever/Tough, poffins, 3-round move combos, ribbons | Non-battle differentiator; only if the core is healthy |
| **Sandbox** | Damage calculator + test battle, no rewards | Teaches the meta, zero risk |

### 4.7 Items, bag, crafting & farming

- **Bag** with categories (Balls, Medicine, Berries, Battle items, TMs, Evolution items, Materials, Key items), stack limits, sorting, search, quick-use, and "use on Pokémon" flows. Capacity 200 stacks free, expandable.
- **Held items are a real economy:** Showdown cares about Leftovers/Choice items/Focus Sash, so items must be obtainable through shop, quests, raid drops, and the market — and tradable.
- **Crafting:** apricorns → balls, berries → potions/poffins, shards → TMs. Recipes are server-driven data, so new recipes ship without an update.
- **Berry farming:** plant in your hideout or guild garden, real-time growth (e.g. 8h), harvest yields; guild gardens are shared and give members a reason to log in.
- **Rotating vendors:** daily bargain bin, event vendor, guild merchant, coin→item exchange with daily caps.
- **Key items:** incubator, IV scanner, shiny charm, EXP charm, fishing rod, safari ticket, radar (targets one species in a zone), bike-equivalent (faster zone traversal).
- **Sinks that feel good:** Poké Balls, lures, incubators, revives/potions, TMs, vitamins, mints, ability items, bottle caps, storage, cosmetics.

### 4.8 Pokémon care, identity & expression

- **Buddy Pokémon** follows you on the home screen and gains friendship/candy from time and (opt-in) step tracking via Apple Health / Google Fit. One buddy at a time, swappable.
- **Friendship & affection** from feeding, a small pet/play minigame, and battles — gates friendship evolutions, small PvE bonuses only. Ranked stays purely mechanical so it can't become a paid stat.
- **Ribbons & marks:** first shiny, tournament top 8, 100 ranked wins, contest winner, event participation, "caught on Community Day". They show on the detail card, trade screen and profile, and they *are* the long-term collector value.
- **Photo mode:** pose your party in a biome backdrop with stickers, frames and filters; export a share card. Cosmetic packs, near-zero gameplay impact.
- **Hideout / secret base:** decorate a room, display six Pokémon in dioramas, visit friends, leave a "like". The best cosmetic sink in the game and a social hook that isn't chat.
- **Cosmetic accessories** (hats, scarves, ball seals) render as overlays on battle sprites; sold as packs, never as stats.
- **Dex research tasks** (Legends-style): catch 3, use a specific move 5 times, evolve, land 5 excellent throws. Gives the Dex a reason to exist beyond a checklist.
- **Shiny chain:** consecutive catches of the same species raise shiny odds; breaks on a different species catch or a timeout. Turns shiny hunting into a strategy, not pure dice.
- **Daily Pokémon** with a coin/XP bonus, and **Pokémon of the day** featured on the home screen (also a nice lore/announcement surface).

### 4.9 Economy

Two currencies:

- **Coins** (soft, earned): catches, first-catch bonuses, battles, quests, selling duplicates, gym clears.
- **Gems** (hard, bought/earned sparingly): cosmetics, season pass tier skips, storage expansions, convenience items.

Sinks: Poké Balls, berries, incense, incubators, TMs, vitamins/mints/ability patches, storage, cosmetics, market fees (5%), trade tax.

Rules: no stat-bearing purchases; daily purchase caps on progression items; everything gameplay-relevant is also earnable; published drop rates for any paid random cosmetic item (and no paid loot boxes where local law forbids them).

### 4.10 Trading, market & auctions

- **Direct trade:** both sides lock up to 6 Pokémon + items, two-step confirmation, server-escrow, cancel-safe, 5-min expiry. Chat is optional and moderated.
- **Marketplace:** list a Pokémon for coins/gems, buyout or timed auction, 1–48h duration, anti-snipe (auto-extend 60s), price history, "watchlist".
- **Value signals:** species rarity, IV total, shiny, level, nature, event origin — surfaced as a "collector score" so new players understand price.
- **Anti-RMT / anti-dupe:** single-writer transactions, idempotency keys, per-account trade velocity limits, device + IP heuristics, and a review queue for high-value trades.
- **Wonder Trade:** send any Pokémon, receive a random one from the pool (rarity-matched so it can't be a pure scam), instant, one free per hour. The best early-game item faucet.
- **GTS:** deposit a Pokémon with a wanted species + filters (shiny, IV floor, level range), filled by other players asynchronously. Solves timezone mismatch.
- **Guild trade board:** members post wants/offers inside the guild, no fee.
- **Trade evolutions:** Haunter/Kadabra/Machoke/Graveler-style evolutions complete on trade, which makes trading mechanically necessary rather than optional.
- **Item trading** alongside Pokémon, with stack-level escrow.
- **Price intelligence:** median sold price, 7-day trend, "good deal" badge, and a scam warning when a listing is far below market (protects new players from off-platform RMT bait).

### 4.11 Social

- **Friends** (presence, gift a daily item, battle invite).
- **Guilds:** 20–50 members, guild level, guild quests, guild raid bosses, guild chat, weekly leaderboard.
- **Global chat** channels (zone, global, trade, guild) with profanity filter, rate limits, report/mute/mod tools. Default off for under-13 accounts.
- **Leaderboards:** season rating, Dex completion, shiny count, catches, guild power, tournament wins.
- **Profile:** avatar, title, badges, showcase team (6 Pokémon rendered on your card), battle record, joined season, ribbons.
- **Guild wars:** weekly guild-vs-guild ladder using member ranked results; the guild raids a rival guild's boss for bonus points.
- **Mentorship:** pair a new player with a veteran; both get rewards for the mentee's first 10 ranked games, and the mentor can lend a legal rental team.
- **Rental teams:** share a team code; the borrower can queue casual (not ranked) with it. Huge for teaching the meta.
- **Spectator emotes & reactions** on live battles, plus "rematch" and "add friend" straight from the result screen.
- **LFG board** for raids and tournaments, with role tags and ping.

### 4.12 Quests, events & live-ops

- Daily (3) / weekly (5) / seasonal quest chains. Examples: "Catch 10 Water-types", "Win 3 ranked battles", "Land 5 excellent throws".
- **Achievements** with tiers and cosmetic rewards.
- **Season pass** (free + premium track, cosmetic-only premium rewards).
- **Events:** Community Day (one species, 3h, boosted shiny + bonuses), type-themed weeks, legendary raids, holiday cosmetics. All event config is **server-driven JSON** so content ships without an app-store update.
- **Announcements / inbox** with server-driven messages and rewards.

### 4.13 QoL & platform

- Team builder, box, market and Dex work offline (cached); battles queue when online.
- Push notifications: spawn lures, raid start, trade offer, guild boss, season end — all opt-in categories.
- **Account:** guest → email/Apple/Google link, restore code, 2FA for linked accounts, device list with remote sign-out, full data export/delete.
- **Referral / invite codes** with cosmetic rewards on both sides; QR-code friend add.
- **Battery & data saver:** animation toggle, lower sprite quality, spawn polling paused in background.
- **PvE auto-battle & battle speed** (1×/2×/4×) for tower and already-cleared content — mobile players should never grind by tapping.
- **Deep links:** guild invite, trade offer, battle invite, replay, friend add.
- **Parental controls:** purchase gate, chat off, playtime reminder.
- Accessibility: colour-blind-safe type badges, reduced motion, text scaling, screen-reader labels on the battle log.
- Localisation-ready (no hardcoded strings, sprite names via data files).

### 4.14 Admin, telemetry & moderation

Not player-facing, but the difference between a prototype and a live game:

- **Admin web panel / CMS:** edit spawn tables, gym lineups, shop rotations, event schedules, drop rates, quests, bans and feature flags — no deploy needed.
- **Economy audit:** every coin/gem/item delta is a ledger row; search by user, reason, ref; grant/refund tool for support.
- **Replay inspector:** open any battle by ID, step through protocol, see both teams and the seed.
- **Moderation queue:** reports, chat logs, trade scam flags, ban/mute with expiry and appeal note.
- **Feature flags + remote config + A/B tests** (catch formula, spawn rates, shop prices, onboarding variants) with a per-feature kill switch.
- **Analytics:** funnel (install → tutorial → first catch → first battle → ranked), D1/D7/D30, catch success rate, battle completion, economy inflation, crash-free sessions.
- **Support tickets** with in-app transcript and battle/replay attachment.

### 4.15 Feature priority matrix

P0 = must exist for v1 to be a game. P1 = first content update. P2 = later / opportunistic.

| Area | Feature | Pri | Ship |
|---|---|---|---|
| Core | Party of 6 + PC boxes + swap/heal | P0 | M2 |
| Core | Catch loop, zones, spawns, catch minigame | P0 | M2 |
| Core | Box filters/multi-select, Dex, detail, EV editor | P0 | M2 |
| Core | Team builder, validator, Showdown import/export | P0 | M3 |
| Battle | Random battle vs AI, ranked singles, battle screen | P0 | M3 |
| Battle | Replays, rating, reconnect, timer | P0 | M3 |
| Economy | Coins/shop/bag, daily quests, login streak | P0 | M4 |
| Core | Onboarding + starter + tutorial battle | P0 | M2 |
| Ops | Admin config, telemetry, feature flags | P0 | M1 |
| Social | Profile, friends, leaderboard, chat (filtered) | P1 | M4 |
| Trade | Direct trade + marketplace + GTS + Wonder Trade | P1 | M4 |
| Battle | Campaign (8 gyms + E4), level caps | P1 | M4 |
| Battle | Doubles ranked, weekly playlist, custom lobbies | P1 | M4 |
| Meta | Seasons, ladder rewards, season pass | P1 | M5 |
| Battle | Raids (co-op + async), Battle Tower | P1 | M5 |
| Social | Guilds, guild quests, guild raids | P1 | M5 |
| Battle | Tournaments + spectating | P1 | M5 |
| Meta | Events, Community Day, outbreaks, global goals | P1 | M5 |
| Meta | Set Library + Battle-ready button | P1 | M3 |
| Care | Buddy, friendship, ribbons, photo mode | P1 | M5 |
| Social | Hideout decor + visits, rental teams, mentor | P2 | M6 |
| Battle | Async battles, player gyms, Champion defence | P2 | M6 |
| Content | Safari, fishing, hordes | P2 | M5 |
| Care | Contests, poffins, contest ribbons | P2 | M6 |
| Content | Breeding, egg moves, Masuda | P2 | M6 |
| Social | Guild wars, world bosses | P2 | M6 |

### 4.16 Deliberately out of scope (for v1)

Chat-based spawn guessing, breeding RNG chains beyond Masuda, mega evolution quests, player-run gyms, voice chat, 3D battle models, real-money marketplace, AI teammates.

---

## 5. How the app feels (screens)

### 5.1 Screen map

```
Launch
 ├── Splash / server status
 ├── Auth (guest, email, Apple, Google)
 ├── Onboarding: pick starter (3 options) + tutorial catch + tutorial battle
 └── Home (hub: buddy, daily Pokémon, event banner, inbox)
      ├── Explore (zone map, weather/time, radar, incense)
      │     └── Zone screen: spawns, rarity feed, catch minigame overlay
      ├── Party (6 slots: drag reorder, heal, swap with PC, auto-fill, legality badge, set library)
      ├── PC Boxes (grid/list, filters, multi-select, compare, mass release, market/trade shortcuts)
      ├── Collection
      │     ├── Pokémon detail (stats, IVs, moves, EV editor, ribbons, evolve, nickname, favorite)
      │     └── Pokédex (grid, completion %, form/shiny dex, research tasks)
      ├── Battle
      │     ├── Quick match (random battle)
      │     ├── Ranked (format select, queue, seasonal rank, divisions)
      │     ├── Campaign (8 gyms + Elite Four + Champion)
      │     ├── Raids (boss list, lobby, co-op, async)
      │     ├── Battle Tower · Tournaments (bracket) · Weekly playlist
      │     ├── Async battles · Custom lobby (invite code) · Spectate
      │     └── Battle screen (health bars, move buttons, switch sheet, log, timer, forfeit)
      ├── Teams (team builder, set library, rental codes, import/export)
      ├── Bag (categories, quick use) · Crafting · Berry garden
      ├── Shop (daily rotation, items, cosmetics, gems, season pass)
      ├── Market (browse, filters, sell, auctions, GTS, Wonder Trade, watchlist)
      ├── Social (friends, guild, guild wars, chat, trade, mentor, LFG)
      ├── Hideout (decor, showcase, photo mode, visits)
      ├── Profile (stats, badges, ribbons, replays, settings)
      └── Quests / Achievements / Inbox / Notifications
```

**Battle screen layout**

- Top: opponent sprite (animated later), name, level, HP bar, status, boosts, hazards, weather, remaining party dots.
- Middle: your active Pokémon, HP/status, tera indicator, item/ability hints.
- Bottom: 4 move buttons (type-coloured, PP, disabled when not requested), Switch, Run/Forfeit, and a collapsible battle log.
- Overlay: `|request|`-driven state machine. Never let the client simulate — it renders what the server says.
- "Why?" inspector: long-press a move to see calculated damage range, type matchup, and accuracy (from cached data).

**Visual direction:** 2D sprite-based — Showdown/PokeAPI sprites plus bold type-coloured cards, per-biome gradients, and Rive for catch/reveal effects. Fast to build, instantly readable, tiny download. 3D models are a v2+ option and a huge art cost.

### 5.2 Visual language — Material 3, but owned

**Decision: Material 3 is the foundation, not the look.** We use M3 components, tokens and accessibility behaviour, then seed a custom brand scheme, custom type and custom shapes so it never reads as "default Flutter app".

- **Colour:** `ColorScheme.fromSeed(brandSeed)` with hand-tuned overrides for `primary`, `secondary`, `tertiary` and surface roles. The 18 type colours live in a separate semantic palette (`typeFire`, `typeWater`…) with `on` colours and dark-mode variants — never the only signal for anything.
- **Dynamic colour (Material You):** available as a setting, **off by default**. If enabled, only surfaces/containers adapt; type colours, rarity and battle semantics stay fixed so the game stays recognisable.
- **Typography:** one display face for headings and big numbers, Inter/Roboto Flex for body, tabular figures for stats; 5-step scale (display 32/28, title 24/20, body 16/14, label 12) with the whole `TextTheme` replaced, not just colours.
- **Shape:** radius scale 4 / 8 / 12 / 16 / 28dp — cards 16, sheets 28 on top, buttons pill/full, HP bars capsule.
- **Elevation:** tonal surfaces plus soft shadows, three levels only. No heavy drop shadows, no blur > 4dp.
- **Backgrounds:** per-biome gradients (forest, cave, water, desert, night) at 6–10% behind content; Pokémon cards stay neutral so sprites pop.
- **Icons:** rounded 24dp grid, custom type/ball/badge/ribbon sets; Material icons only where a game icon doesn't exist.
- **Dark mode:** full parity plus an OLED-black option; gradients and type colours re-tuned instead of reused.
- **Brand moments:** type-coloured glow on a catch, gold sparkle on shiny, stamped badge, rank-up ribbon.

**Navigation:** M3 `NavigationBar` with five destinations — **Home, Party, Battle, Social, More** — plus contextual `FloatingActionButton` (catch/queue). Sheets for filters and item pickers; `SearchBar` for the PC and Dex; `SegmentedButton` for box/list toggles.

### 5.3 Motion & animation

Rules: UI transitions under 250ms, celebrations skippable above 600ms, 60/120fps on mid-range Android, respect `MediaQuery.disableAnimations`, never block input, never animate every tap.

| Moment | Animation | Timing |
|---|---|---|
| Screen push | M3 shared-axis transition via custom `PageRouteBuilder` | 300ms emphasized |
| Tab switch | Fade-through + shared element for the party sprite | 220ms |
| List entrance | Staggered slide+fade, max 8 items | 40ms stagger, 250ms |
| Catch throw | Rive state machine: arc, 3 wobbles, burst | 1.8s, tap to skip |
| HP change | Tweened bar + ticking number + shake on crit | 300ms |
| Level up | Scale pop + confetti + stat roll-up + haptic | 900ms |
| Shiny reveal | Gold radial sweep + haptic pattern + sound | 1.2s |
| Badge earned | Stamp press with spring overshoot | 700ms |
| Battle move | Sprite lunge, impact flash, type-coloured particles | 400ms |
| Skeleton load | Shimmer sweep | 1.2s loop |

**Implementation:** `AnimatedContainer`, `AnimatedSwitcher` and `TweenAnimationBuilder` for 90% of it; `flutter_animate` for sequences and stagger; **Rive** for catch, shiny reveal, badge stamp and level-up (state machines, ~20–60KB each, preloaded before use); `Hero` + custom page transitions for shared elements; `CustomPainter` for the catch ring and damage arcs; `flutter_haptic_feedback` patterns; `audioplayers` for short SFX with per-event mute. Lottie only if an artist supplies a file — Rive is cheaper at runtime.

### 5.4 Component inventory (build once, reuse)

- `PokemonCard` (compact / list / detail, shiny + favourite + locked states, type-gradient border)
- `PartySlot`, `PcGrid`, `StatBar` (animated, EV/IV overlay), `ComparePanel`
- `TypeChip`, `RarityBadge`, `ShinyStar`, `RibbonChip`, `BadgeCase`
- `HpBar` (segmented, status tint, low-HP pulse), `BattleField` (platforms, weather, party dots)
- `MoveButton` (type colour, PP, disabled state, press scale), `SwitchSheet`, `CatchOverlay`
- `CurrencyChip`, `QuestCard`, `RewardSheet`, `MarketListingCard`, `TradeSlot`
- `EmptyState` (illustrated sprite + one CTA), `Skeleton`, `ErrorState` with retry, `OfflineBanner`
- `CelebrationOverlay` (level-up, shiny, badge, rank-up), `BottomSheet` variants (filters, item picker)

Everything lives in `lib/ui/` with tokens first: `color.dart`, `type_colors.dart`, `spacing.dart`, `motion.dart`, `text.dart`.

### 5.5 Accessibility & performance

- Contrast ≥ 4.5:1, touch targets ≥ 48dp, text scale to 200% without clipping, semantic labels on HP/moves/battle log, reduce-motion honoured, colour never the only signal (type icon + label).
- `const` constructors, `RepaintBoundary` around sprites and particles, sprite atlases preloaded per zone, virtualised lists, 60fps target on mid-range Android, base download under ~16MB before sprite packs.
- Sound and haptics are per-event toggles; game audio never ducks the user's music.

---

## 6. Architecture

### 6.1 High level

```
┌───────────────────────────── Flutter app ─────────────────────────────┐
│  Riverpod state · go_router · dio (REST) · socket_io_client (WS)      │
│  drift/SQLite cache (dex, box, teams, settings) · assets: sprites, dex │
└───────────────┬───────────────────────────────────┬───────────────────┘
                │ HTTPS (REST)                      │ WSS (JSON + Showdown protocol)
                ▼                                   ▼
      ┌───────────────────┐               ┌────────────────────────┐
      │  API service      │               │  Realtime gateway      │
      │  Fastify + Zod    │               │  Socket.IO / ws        │
      │  auth, box, teams │               │  presence, queue, hub  │
      │  shop, market,    │               └───────┬────────────────┘
      │  quests, social   │                       │ Redis pub/sub
      └───────┬───────────┘                       ▼
              │                          ┌────────────────────────┐
              │                          │  Battle workers (N)    │              │                          │  pokemon-showdown      │                    │                          │  timer, AI, replay log │
              │                          └───────┬────────────────┘
              ▼                                  ▼
      ┌─────────────────────────────────────────────────────────────┐
      │ Postgres (source of truth) · Redis (queues, presence, cache) │
      │ Object storage (replays, assets) · BullMQ (jobs, cron)       │
      └─────────────────────────────────────────────────────────────┘
```

**Rules of the architecture**

1. **Server-authoritative for anything with value:** spawns, IVs, shininess, catch rolls, rewards, trades, market, rating. The client is a view.
2. **REST for request/response** (box, team save, market browse), **WebSocket for stateful realtime** (battle, queue, chat, presence).
3. **Battle workers are separate processes** so a CPU-heavy sim can't starve the API, and can scale/host independently.
4. **All balancing numbers live in config, not code** (JSON/DB tables, admin-editable, versioned): spawn rates, catch formula constants, XP curves, prices, drop tables.
5. **Content is data:** species spawn tables, gym lineups, event schedules and shop rotations are DB rows you can edit live.

### 6.2 Suggested stack

| Layer | Choice | Why |
|---|---|---|
| Client | Flutter 3.x, Dart 3 | Repo devcontainer; single codebase for iOS/Android; excellent animation control |
| Client state | `flutter_riverpod`, `go_router` | Testable, no BuildContext coupling |
| Client HTTP | `dio` + `retrofit`/hand-written client | Interceptors for auth/retry |
| Client realtime | `socket_io_client` | Rooms, reconnect, fallbacks |
| Client local DB | `drift` (SQLite) | Box/Dex/team caching, offline reads |
| Client models | `freezed` + `json_serializable` | Immutable models, unions for protocol events |
| UI system | Material 3 (`useMaterial3: true`) + custom seeded scheme, custom `TextTheme`, optional `dynamic_color` | Modern, accessible, familiar; brand identity preserved |
| Animation | Implicit animations, `flutter_animate`, Rive for catch/badge/shiny, `Hero` + custom page transitions | 60/120fps, skippable, small assets |
| Feel | `flutter_haptic_feedback`, `audioplayers` | Haptics and short SFX with per-event toggles |
| Game server | Node 22 + TypeScript, Fastify | Same language as Showdown; fast to iterate |
| ORM | Drizzle ORM + `pg` | Typed SQL, real migrations |
| Realtime | Socket.IO (or `ws` + own envelope) | Battle/queue/chat rooms, acks |
| Jobs | BullMQ + Redis | Spawn expiry, auction close, season roll, push sends |
| Cache/presence | Redis | Queues, rate limits, online counts, pub/sub between gateway and workers |
| DB | Postgres (Neon/Supabase/Tiger Cloud free tiers are fine to start) | Relational integrity for trades/economy |
| Storage | S3-compatible (R2/Supabase Storage) | Replays, event banners, future user content |
| Auth | Own JWT (access+refresh) or Supabase/Firebase Auth | Device linking, guest upgrade |
| Push | Firebase Cloud Messaging (`firebase_messaging`) | Free, cross-platform |
| IAP | `in_app_purchase` + server-side receipt validation | Gems, season pass |
| Sim | **`smogon/pokemon-showdown`** vendored as a pinned git submodule, plus `@smogon/calc` (previews) and `@pkmn/sets` (packing) | Decided: full control of `config/formats.ts`, battle scripts, clauses and random team generation; MIT |
| Ops | Docker Compose locally, Fly.io/Railway/Render for API+workers, managed PG/Redis | Cheap to start |
| Observability | pino logs, Sentry, basic metrics endpoint | Debug battle bugs from replays |

### 6.3 Showdown integration — decided: vendor `smogon/pokemon-showdown`

**Decision: we run the upstream repository, not a re-implementation.** `github.com/smogon/pokemon-showdown` is vendored as a git submodule at `vendor/pokemon-showdown`, pinned to a commit, built in our Docker image, and imported by the battle worker through a thin `BattleEngine` adapter. We do **not** run its HTTP/WebSocket server, rooms, ladder or client — only `sim/`, `data/` and `config/formats.ts`. Our gateway, auth, persistence, matchmaking and ladder wrap around it.

Why the upstream repo rather than `@pkmn/sim`:

- **`config/formats.ts` is the game design.** Gym rules, level caps, 3v3, raid rules, custom banlists and clauses all live there. This is most of what makes our game ours.
- Random team generation (`Teams.generate`, random-battle data) ships in the repo.
- Battle scripts can be patched when a mode needs it (raid boss shields, "no bag items" gyms).
- One source of truth for legality, so our team validator and the sim can never disagree.

Cost we accept: its build step in the image, a TypeScript boundary that is not a clean typed package, and manual upgrade work (submodule bump + rerun the golden tests).

**Integration shape**

```
server/
├── config/showdown/formats.ts   # our patch applied over the submodule at build time
├── src/battle/
│   ├── engine/showdown.ts       # adapter: createBattle, submitChoice, snapshot, dispose
│   ├── engine/protocol.ts       # line parsing + redaction assertions
│   ├── engine/formats.ts        # our format ids ↔ Showdown ids, rule injection
│   ├── worker.ts                # owns N battles, timers, AI, persistence hooks
│   ├── ai/                      # random, gym heuristic, raid boss controller
│   └── replay.ts                # seed + teams + choices → protocol
└── vendor/pokemon-showdown/     # git submodule, read-only
```

- **Build:** the submodule is compiled in the Docker build stage (`node build`) and its output copied beside the worker. `SIM_VERSION` = submodule commit, stored on every `battles` row so old replays stay explainable.
- **Formats:** `server/config/showdown/formats.ts` is applied over the submodule by a small build script (copy, not merge) so a submodule bump never produces a conflict. It defines: ranked OU singles, VGC-style doubles, Gym 1–8 (level caps, 3v3), Elite Four, Battle Tower, raid, weekly playlists and custom-lobby templates.
- **Hidden information:** each battle is a `BattleStream`; `BattleStreams.getPlayerStreams()` gives `p1`/`p2` streams that are already redacted. The worker keeps the `omniscient` stream for logging and replays and never forwards it.
- **Teams:** packed Showdown team strings (`@pkmn/sets` or the repo's own `Teams.pack`), which also gives us free import/export and rental-team codes.
- **Client:** Flutter never bundles Showdown. It renders protocol lines; the dex is a generated JSON snapshot (§6.5).
- **Upgrades:** bump the submodule monthly, run golden tests, deploy server-side (no app update). Never bump mid-season.

**M0 spike must answer (against the vendored repo):**
1. Build and import the vendored `sim/` from our Node 22/TS worker without patching its globals (or with one documented patch).
2. A custom format in `config/formats.ts`: level cap 35, 3v3, custom banlist, no bag items — and confirm the team validator enforces the same rules.
3. Prove with an automated test that a player stream never contains the opponent's unrevealed team, moves or items.
4. Determinism: `seed + teams + choices` replays identically after a process restart; confirm what `SIM_VERSION` pinning is needed.
5. Four-player multi battle for raids, and doubles.
6. Memory/CPU per concurrent battle and battles-per-worker on 512MB/1vCPU.
7. Raid mechanics: boss HP/shield injection — custom rule in the sim vs a wrapper around it. Pick one and write it down.

**Fallback if M0 fails:** pin `@pkmn/sim` to the same upstream commit and keep the exact same `BattleEngine` interface, so the worker and everything above it stays unchanged. The adapter boundary is what makes that cheap.

### 6.4 Battle flow (end to end)

```
Client                    Gateway                Battle worker            DB
  │ queue(format)  ──────▶ │ enqueue (Redis)          │                    │
  │                        │ match found ─────────────▶ create BattleStream │
  │ ◀── battle_start ──────│ ◀───────────────────────  │                  │
  │                        │ ◀── protocol chunks ───── │                    │
  │ ◀── |switch| ... ──────│                          │                   │
  │ ◀── |request| ─────────│                          │                   │
  │ choice(move 1, rqid) ─▶│ ──> submitChoice ────────▶│                   │
  │ ◀── turn protocol ─────│ ◀───────────────────────  │                   │
  │        ...             │                          │                    │
  │ ◀── |win| ─────────────│ ◀───────────────────────  │ rating tx ───────▶│
  │                        │                          │ log + seed ───────▶│
```

Key details:

- **Choice envelope:** `{battleId, rqid, choice}`; worker rejects stale `rqid` (double-submit protection) and illegal choices via try/catch on the sim.
- **Timer:** worker-side interval; on expiry submit `>p1 default` (Showdown's own default choice) or forfeit per format config.
- **Reconnect:** client sends `resume(battleId)`; worker replays the full protocol buffer (or the redacted per-side log) + latest `|request|`. Battle survives 2 minutes of disconnection, then auto-loss.
- **Disputes:** every battle has a replay record → customer support can inspect exact turns.
- **Rating writes:** single transaction on battle end (idempotent by `battleId`), so a crash can't double-count.
- **No client-side sim in v1.** Even NPC battles run server-side. Offline "training dummy" mode (later) can bundle `@pkmn/sim` in a webview/JS engine, but that is opt-in and rewardless.

### 6.5 Flutter ↔ sim data

The client needs dex data (stats, types, moves, learnsets, sprites) without a JS engine:

1. At build time, a Node script reads the vendored Showdown `Dex` (or `@pkmn/dex`, which mirrors it) and emits `assets/data/dex.json` (+ move data, learnsets, type chart, sprites manifest).
2. App ships that JSON compressed; `drift` seeds it into SQLite on first launch for fast search.
3. Sprites from Showdown/PokeAPI are downloaded at build time into an asset bundle, split by generation, optionally served from CDN with `cached_network_image` for animated forms.
4. Server and client data versions are compared on login; mismatch → download new dex bundle (server-driven), no app-store update needed.

### 6.6 Data model (first cut)

```sql
users(id, email, password_hash, created_at, banned_until, flags)
profiles(user_id PK, display_name, avatar_id, title, level, xp, coins, gems,
         region, season_id, tutorial_state, notification_prefs jsonb)
pokemon(id, owner_id, species_id, form_id, nickname, level, xp,
        iv_hp..iv_spe, ev_hp..ev_spe, nature, ability_id, is_hidden_ability,
        move_1..move_4, held_item_id, shiny, ball_id, met_zone_id, met_at,
        ot_user_id, is_locked, is_favorite, deleted_at)
party(user_id, slot, pokemon_id, unique(user_id, slot))   -- slot 1..6, the battle squad
boxes(id, user_id, name, sort_index)
teams(id, owner_id, name, format_id, packed_text, updated_at)   -- saved builds, reusable
team_slots(team_id, slot, pokemon_id)              -- optional, if not stored packed
pokemon_ribbons(pokemon_id, ribbon_id, awarded_at, source, season_id)
pokemon_research(pokemon_id, task_id, progress, completed_at)
trainer_badges(user_id, badge_id, earned_at)
campaign_progress(user_id, node_id, status, updated_at)
battles(id, format_id, p1_id, p2_id, seed, sim_version, winner_id, mode,
        tournament_id, rating_delta_p1, rating_delta_p2, started_at, ended_at, replay_key)
battle_events(battle_id, seq, side, line)          -- redacted protocol log
ratings(user_id, format_id, season_id, rating, peak, games, wins, losses)
market_listings(id, seller_id, pokemon_id, currency, start_price, buyout,
                ends_at, status, buyer_id, sold_at)
trades(id, a_id, b_id, status, created_at, expires_at)
trade_items(trade_id, side, pokemon_id, item_id, quantity)
transactions(id, user_id, currency, delta, reason, ref_id, created_at, idempotency_key)
quests(id, kind, requirements jsonb, rewards jsonb, active_from, active_to)
user_quests(user_id, quest_id, progress jsonb, claimed_at)
guilds(id, name, tag, level, xp, owner_id, created_at)
guild_members(guild_id, user_id, role, joined_at)
items(id, slug, category, stack_limit, tradable)
inventory(user_id, item_id, quantity)
gts_listings(id, seller_id, pokemon_id, want_species, want_shiny, want_min_iv,
             min_level, expires_at, status)
wonder_trades(id, sender_id, pokemon_id, status, matched_pokemon_id)
async_battles(id, format_id, p1_id, p2_id, state jsonb, turn_user_id,
              turn_deadline, status)
tournaments(id, format_id, starts_at, size, entry_fee, status, bracket jsonb)
tournament_entries(tournament_id, user_id, seed, placement)
guild_raids(id, guild_id, boss_id, hp_remaining, starts_at, ends_at)
hideouts(user_id PK, layout jsonb, updated_at)
hideout_visits(hideout_id, visitor_id, liked, visited_at)
research_tasks(id, species_id, task_type, target, rewards jsonb)
season(id, name, starts_at, ends_at, config jsonb)
```

Notes: `pokemon` rows are soft-deleted on release/trade so provenance/audits survive. Trades and market moves run inside a single SQL transaction with `SELECT … FOR UPDATE` on both sides + an idempotency key. `party` is a hard invariant: a Pokémon may occupy at most one party slot, a slot holds at most one Pokémon, and membership only changes outside battle.

### 6.7 Anti-cheat & fairness

- Server-side RNG everywhere that matters (spawn, IV, shiny, catch, rewards). Client never computes outcomes.
- Per-side protocol streams → opponent team/moves/items are never sent until revealed by Showdown's `|split|`.
- Rate limiting per user + device + IP on catch, spawn, trade, market, chat.
- Idempotency keys on all economy endpoints; no client-supplied prices or quantities.
- Client integrity: Play Integrity / App Attest on ranked queues (soft check), plus behavioural flags (catch timing bots, impossible session lengths).
- Moderation: report queue, chat filter, trade scam patterns, appeal flow.
- No client-side timer authority, no client-side rating.

---

## 7. Game balance numbers (starting point, all configurable)

| Knob | Start value | Notes |
|---|---|---|
| Spawn interval in-zone | 45s ± 30s | 15s with lure |
| Spawn TTL | 90s | Prevents "leave app open for hours" farming |
| Zone energy | 30, 1 per 2 min, +10 daily gift | Caps grind, not purchases |
| Shiny rate | 1/2048 (Charm 1/1024) | Community Day 1/128 |
| IV distribution | uniform 0–31 per stat | Legendaries/raids: 3 guaranteed 31s |
| Catch formula | `p = clamp(base_catch / 3 * ball * berry * status * (1 - hp_frac) * level_factor)` | Tune per species; published table not required |
| Perfect-throw bonus | ×1.15 | Excellent ×1.3, Nice ×1.05 |
| Level XP to 100 | ~1.06M total | ~4h of normal play per mon to 50 |
| Move learning | by level + TMs | TM items are consumable, shop + quests |
| Ranked rating | Glicko-2, placement 5 games | Soft reset 25% toward 1500 each season |
| Season length | 8 weeks | Ladder + pass + event calendar |
| Market fee | 5% of sale | Coin sink |
| Trade tax | 50 coins flat | Anti-spam |
| Daily quests | 3, 30–80 coins each | Plus 1 rare item per day |
| Free gems | ~150/week from quests/achievements | Premium pass ~$5/season |
| Box size | 300 free, +100 per expansion | Storage is a fair monetisation sink |
| Party size | 6, hard cap | Never sold, never expanded |
| PC layout | Boxes of 30 | Rename/reorder; filters cached locally |
| Bag | 200 stacks free | Expandable, not required |
| Healing | PvE persists, PvP full heal | 10s free Pokémon Center; auto-heal flag exists |
| Ranked scaling | auto-level 50/100 | IVs/EVs/nature/items still apply — no level grind gate |
| Wonder Trade | 1 free per hour | Rarity-matched pool, no bots |
| Shiny chain | floor 1/512 after 30 same-species catches | Resets on a different species or 30 min idle |
| Login streak | 7-day cycle | Day 7 rare item; resets after 48h+ |

These are hypotheses, not truths. Ship them behind a config table + remote flags, then tune with telemetry (catch success rate, session length, D1/D7 retention, battle completion rate).

---

## 8. Monetisation

| Item | Type | Notes |
|---|---|---|
| Season pass | Subscription-ish | Free track + premium track; cosmetics, incubators, gems |
| Cosmetics | Direct | Avatars, outfits, ball skins, catch effects, profile banners, titles |
| Storage | Convenience | PC expansions, bag slots, hideout rooms — **never** party size |
| Expression | Cosmetic | Hideout decor, photo frames/stickers, ball skins, name colours, titles, showcase themes |
| Incubators / lures | Convenience | Time savers, not power |
| Gems | Currency | Used for the above |
| Ads | **No** | Kills the vibe and retention in a collection game |

Guardrails: no selling Pokémon, IVs, shininess, rating or battle power; disclose odds for any paid random item; regional pricing; parent-gate purchases; no dark-pattern timers on purchase screens.

---

## 9. Legal & content risk (must be decided before launch)

- Pokémon, names, sprites and cries are **The Pokémon Company / Nintendo IP**. Showdown's code is MIT, but the bundled Pokémon data and sprites are not yours to publish commercially.
- Safe-ish paths: (a) non-commercial fan project distributed as a sideloaded/APK build with clear attribution and no ads/IAP; (b) **original monsters + original art** with Showdown mechanics (mechanics are not copyrightable) — the only truly store-safe route; (c) private/personal build for you and friends.
- App Store / Play Store will reject "Pokémon" branding and ripped assets. Do not build the IAP/ads pipeline assuming store approval with Pokémon assets.
- Showdown/Winhee/PokeAPI attribution and license notices should ship in an "About → Licenses" screen; keep the MIT notices.
- Privacy: COPPA/GDPR-K considerations if under-13 accounts are allowed (chat off by default, no location, parental gate for purchases). Data deletion + export endpoints from day one.

> Recommendation: build **data-driven** from the start — monsters are rows (`species`, `sprites`), never hardcoded — so the same game can ship with original monsters later if you go commercial. That decision costs almost nothing now and is very expensive to retrofit.

---

## 10. Repository plan

```
/
├── ReadMe.md
├── docs/
│   ├── GAME_DESIGN.md            ← this file
│   ├── API.md                    (endpoint contracts)
│   ├── PROTOCOL.md               (battle WS envelope + Showdown line mapping)
│   └── DECISIONS.md              (ADR log)
├── app/                          Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/                  router, theme, bootstrap
│   │   ├── core/                 api client, ws client, storage, config, analytics
│   │   ├── data/                 models (freezed), repositories, local db (drift)
│   │   ├── features/
│   │   │   ├── auth/  onboarding/  explore/  party/  pc/  collection/  dex/
│   │   │   ├── teams/  battle/  bag/  market/  social/  shop/  profile/
│   │   │   ├── quests/  hideout/  campaign/  tourney/  spectate/
│   │   └── ui/                   M3 theme, tokens (colour/type/space/motion), shared widgets
│   ├── assets/data/              generated dex.json, learnsets.json, sprites/
│   ├── assets/rive/              catch, shiny reveal, badge stamp, level-up
│   └── test/
├── server/                       Node/TS
│   ├── src/
│   │   ├── api/                  routes by domain
│   │   ├── realtime/             gateway, rooms, queue, presence
│   │   ├── battle/               engine adapter, worker, timers, AI, replay
│   │   ├── game/                 catch, spawn, xp, evolution, economy, quests
│   │   ├── db/                   schema, migrations, repositories
│   │   ├── jobs/                 bullmq workers + cron
│   │   └── shared/               types, config, validation, errors
│   └── test/                     unit + battle protocol golden tests
├── vendor/
│   └── pokemon-showdown/         git submodule, pinned commit, read-only
├── tools/
│   ├── gen-dex.ts                vendored Dex → app/assets/data
│   ├── apply-formats.ts          config/showdown/formats.ts → submodule
│   └── sync-sprites.ts
├── docker-compose.yml            postgres, redis, minio, api, workers
└── .devcontainer/
```

**Testing strategy that actually matters here**

- **Battle golden tests (server):** seed + choices → exact protocol snapshot. This is the highest-value test suite; it catches sim upgrades breaking replays.
- **Economy invariant tests:** no negative balances, no double-spend under concurrent trade requests, idempotency replay.
- **Protocol fuzz tests:** malformed client choices must never crash a worker or leak opponent data.
- **Widget tests** for box filters, team builder legality, catch overlay states.
- **A load test** of 50–100 concurrent bots playing random battles before any public launch.

---

## 11. Roadmap

| Milestone | Deliverable | Est. (solo, part-time) |
|---|---|---|
| **M0 — Spike** | Prove Showdown in a Node worker: hidden info, custom format, replay determinism, 50-bot load test, perf/memory numbers. Write `docs/DECISIONS.md`. | 1 week |
| **M1 — Skeleton** | Monorepo, docker-compose, auth, Flutter shell with router + design tokens, CI, API client, WS client. | 1–2 weeks |
| **M2 — Collection** | Party of 6 + PC boxes + swap/heal, catch loop (zone, spawn, catch minigame), Dex, Pokémon detail, bag, XP/level, evolution. Server-authoritative spawns. | 4–5 weeks |
| **M3 — Battle** | Team builder + validator, Set Library + Battle-ready button, random battle vs AI, PvP queue, battle screen protocol interpreter, rating, replay. | 4–5 weeks |
| **M4 — Economy & social** | Shop, coins/gems, quests, market + direct trade + GTS + Wonder Trade, campaign (8 gyms/E4), profile, friends, leaderboard, spectate. | 5–6 weeks |
| **M5 — Live-ops** | Seasons, pass, events config, push, guilds + guild raids, raids, tournaments, hideout, buddy/ribbons/photo mode, admin tooling. | 6–8 weeks |
| **M6 — Launch** | Store assets, privacy policy, moderation, load test, crash-free target, soft launch in one region. | 2–3 weeks |

Realistic total for everything in this document: **7–9 months solo**, faster with an artist + a second engineer. The MVP cut line below is roughly **4 months** and is a shippable game on its own.

**MVP cut line (ship first):** onboarding + party of 6 + PC + 2 zones + catch + Dex + bag/heal + random battle vs AI + ranked singles + team builder/validator + coins/shop + daily quests + profile. No market, no guilds, no raids, no campaign, no breeding. Those are M4–M5.

---

## 12. Biggest risks

| Risk | Mitigation |
|---|---|
| Legal IP issue blocks store release | Data-driven monsters; decide original-art path before monetisation work |
| Vendored Showdown build/upgrade friction | Pin the submodule, build it in Docker, isolate it behind `BattleEngine`, run battle golden tests on every bump, never upgrade mid-season |
| Feature creep (this doc is now large) | The priority matrix in §4.15 is the contract; anything new needs a decision-log entry and a milestone slot |
| Battle worker cost/scaling | Measure early; 1 worker handles many concurrent battles (they're event-driven, not CPU-bound except AI); horizontal scale |
| Hidden-info leak through protocol | Per-side streams + golden tests asserting absence of opponent data |
| Economy exploits (dupe, RMT) | Single-writer transactions, idempotency, audit log, trade review |
| Mobile app size (sprites + dex) | Split asset packs by generation, CDN for animated, ~15–25MB base target |
| Content treadmill (players finish the Dex) | Seasons, events, shinies, PvP depth, guild goals; content is server-driven |
| Retention after week 1 | Random battles as zero-barrier PvP; daily loop under 10 min; push notifications |
| Scope creep | This document is the scope; anything new needs a decision log entry and a milestone slot |

---

## 13. Decisions to confirm before building

**Already decided:** battle engine = upstream `smogon/pokemon-showdown` as a pinned submodule; party = 6 with the rest in PC storage; no pay-to-win; server-authoritative for everything with value.

1. **Spawn surface:** exploration zones (recommended) vs. a live "world feed" timeline vs. map-based walking.
2. **Art:** Showdown/PokeAPI sprites for a fan build (recommended for speed) vs. original monsters from day one (store-safe).
3. **Distribution:** personal/APK fan build vs. store release (drives legal + IAP work).
4. **v1 battle scope:** random battles + ranked singles only, or include doubles at launch?
5. **Backend hosting:** single VPS with Docker Compose vs. managed API host + managed Postgres/Redis.
6. **Auth:** own JWT vs. Supabase/Firebase Auth (faster, vendor lock).
7. **Accounts:** is under-13 allowed (chat off, no location, parental gate) or 13+ only at launch?
8. **Healing model:** persistent PvE HP (recommended, gives Potions a purpose) vs auto-heal everywhere (less friction).
9. **Async battles in v1?** They are the best mobile-only feature but need a separate turn engine path — P1 or P2?
10. **Campaign at launch** (8 gyms is a lot of content) or ranked-first with gyms as a later update?
11. **Theme:** M3 baseline + custom brand scheme (recommended) vs full Material You dynamic colour by default?

---

## 14. Definition of "done" for v1

A new player can install the app, catch their starter and 20 more Pokémon in two zones, manage a party of 6 with everything else in the PC, build a legal team, win a random battle against an AI gym leader, queue and play a ranked battle against a human on the real Showdown engine, watch the replay, complete daily quests, spend coins in the shop, and come back tomorrow to a season ladder and a push notification — without the client ever deciding an outcome.
