# API reference

Base URL: `http://HOST:PORT` (default port 8787).
Everything is JSON. Errors look like `{"error":"code","message":"human text"}`.
There are no accounts on this server; friend battles use per-lobby tokens.

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET` | `/health` | none | Engine, formats, live battle count |
| `GET` | `/api/formats` | none | Formats with display names |
| `POST` | `/api/battles` | none | Start an AI battle |
| `GET` | `/api/battles/:id` | none | Snapshot for the player |
| `POST` | `/api/battles/:id/choice` | none | Submit a move/switch |
| `POST` | `/api/friend-battles` | none | Create an invite (host) |
| `POST` | `/api/friend-battles/join` | none | Join with an invite code |
| `GET` | `/api/friend-battles/:id` | `x-battle-token` | Poll a friend battle |
| `POST` | `/api/friend-battles/:id/choice` | `x-battle-token` | Act in a friend battle |

`/api/battles/*` are single-player battles against the AI. There is no token
because the battle id is the capability; do not treat the id as a secret.

## Health

```bash
curl http://localhost:8787/health
```

```json
{
  "ok": true,
  "engine": "pokemon-showdown",
  "formats": ["gen9randombattle", "gen8randombattle"],
  "activeBattles": 0
}
```

## Formats

```bash
curl http://localhost:8787/api/formats
```

```json
{
  "formats": [
    {"id": "gen9randombattle", "name": "[Gen 9] Random Battle"},
    {"id": "gen8randombattle", "name": "[Gen 8] Random Battle"}
  ]
}
```

## Snapshots

Both battle kinds return the same snapshot shape, from the requesting player's
point of view.

```json
{
  "id": "battle-uuid",
  "side": "p1",
  "format": "gen9randombattle",
  "turn": 3,
  "ended": false,
  "winner": null,
  "canAct": true,
  "waiting": false,
  "forceSwitch": false,
  "player": {
    "name": "Aria",
    "active": {
      "slot": 1,
      "species": "Garchomp",
      "level": 78,
      "condition": "120/180",
      "hp": 0.66,
      "status": null,
      "active": true,
      "fainted": false,
      "reviving": false,
      "moves": [
        {"name": "Earthquake", "pp": 10, "maxPp": 10, "disabled": false}
      ]
    },
    "team": [
      {
        "slot": 1,
        "species": "Garchomp",
        "level": 78,
        "condition": "120/180",
        "hp": 0.66,
        "status": null,
        "active": true,
        "fainted": false,
        "reviving": false,
        "moves": [
          {"name": "Earthquake", "pp": 10, "maxPp": 10, "disabled": false}
        ]
      }
    ]
  },
  "opponent": {
    "species": "Corviknight",
    "level": 80,
    "hp": 0.5,
    "condition": "90/180",
    "status": "par",
    "fainted": false
  },
  "log": ["|turn|3", "|move|p1a: Garchomp|Earthquake|p2a: Corviknight"]
}
```

Notes:

- `hp` is 0–1 for bars; `condition` is the raw Showdown condition string.
- `player.moves` is only populated for the active Pokémon.
- Only your own team is returned, plus the revealed opponent.
- `canAct` is true for a normal move request and for a forced switch.
- `waiting` is true when the opponent still has to act.
- `forceSwitch` asks for a switch; if `active.reviving` is true (Revival
  Blessing), the target must be a **fainted** ally.
- `winner` is `player`, `opponent` or `null` (draw).
- `log` is prettified client-side; it is raw Showdown protocol on the wire.

## AI battle

### Start

```bash
curl -X POST http://localhost:8787/api/battles \
  -H 'content-type: application/json' \
  -d '{"format":"gen9randombattle"}'
```

`201` with a snapshot. Save `id`.

### Act

```bash
curl -X POST http://localhost:8787/api/battles/ID/choice \
  -H 'content-type: application/json' \
  -d '{"choice":"move 1"}'
```

Allowed choices: `move 1`–`move 4`, `switch 1`–`switch 6`, `pass`.
`200` with the next snapshot.

### Poll

```bash
curl http://localhost:8787/api/battles/ID
```

## Friend battle

Two players, one battle, no websocket. The host creates a lobby, the guest
joins with a six-character code, then both poll and submit choices.

### 1. Host creates the lobby

```bash
curl -X POST http://localhost:8787/api/friend-battles \
  -H 'content-type: application/json' \
  -d '{"name":"Aria","format":"gen9randombattle"}'
```

```json
{
  "id": "lobby-uuid",
  "code": "ABC123",
  "side": "p1",
  "token": "host-token",
  "status": "waiting"
}
```

Keep `token` on the host device. Show `code` as text and as a QR code.

### 2. Host polls while waiting

```bash
curl http://localhost:8787/api/friend-battles/LOBBY_ID \
  -H 'x-battle-token: host-token'
```

```json
{"id":"lobby-uuid","side":"p1","status":"waiting","code":"ABC123"}
```

### 3. Guest joins

```bash
curl -X POST http://localhost:8787/api/friend-battles/join \
  -H 'content-type: application/json' \
  -d '{"code":"ABC123","name":"Kai"}'
```

```json
{
  "id": "lobby-uuid",
  "side": "p2",
  "token": "guest-token",
  "status": "active",
  "snapshot": { "...": "guest snapshot" }
}
```

### 4. Both poll and choose

```bash
curl http://localhost:8787/api/friend-battles/LOBBY_ID \
  -H 'x-battle-token: host-token'
```

Once active, the reply gains `"status":"active"` and `"snapshot"`, matching the
snapshot schema above.

```bash
curl -X POST http://localhost:8787/api/friend-battles/LOBBY_ID/choice \
  -H 'x-battle-token: host-token' \
  -H 'content-type: application/json' \
  -d '{"choice":"move 2"}'
```

The reply is the caller's snapshot. Immediately after acting, `waiting` may be
`true`; poll every 1–2 seconds until `canAct` or `ended`.

### Tokens and expiry

- `host-token` and `guest-token` are random UUIDs stored per lobby. A missing or
  wrong token returns `401`.
- A third device that knows the code can **join** only if the battle has not
  started; after that the lobby is full.
- Invites and battles expire 30 minutes after creation. A restart clears them.

## Error codes

| Status | `error` | Meaning |
|---|---|---|
| 400 | `unsupported_format` | Format not in `/api/formats` |
| 400 | `invalid_choice` | Choice string is not `move N`, `switch N` or `pass` |
| 400 | `switch_required` | A forced switch must be submitted |
| 401 | `invalid_token` | Missing/wrong friend-battle token |
| 404 | `battle_not_found` | Wrong id, expired or server restarted |
| 404 | `invite_not_found` | No lobby with that code |
| 409 | `battle_full` | Both friend slots are taken |
| 409 | `cannot_act` | A switch was sent while a move request is active |
| 409 | `battle_over` | The battle already has a result |
| 409 | `choice_failed` | The simulator rejected the choice |
| 500 | `battle_start_failed` | Engine failed to start a battle |

## Limits

- In-memory sessions only; no persistence.
- One battle session per request; there is no matchmaking queue.
- Snapshots include at most 60 log lines.
- Poll politely: 1–2 seconds is enough for friend battles.
