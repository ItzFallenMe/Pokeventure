import { randomUUID } from 'node:crypto';

import cors from 'cors';
import express, { type Request, type Response } from 'express';

import {
  SUPPORTED_FORMATS,
  formatName,
  isSupportedFormat,
} from './battle/engine.js';
import {
  BattleSession,
  type BattleSide,
} from './battle/session.js';

const app = express();
app.use(cors());
app.use(express.json({ limit: '64kb' }));

const sessions = new Map<string, BattleSession>();
const CHOICE_PATTERN = /^(move [1-4]|switch [1-6]|team [1-6,]+|pass)$/;
const SESSION_TTL_MS = 30 * 60 * 1000;

interface FriendLobby {
  id: string;
  code: string;
  format: string;
  hostName: string;
  hostToken: string;
  guestName?: string;
  guestToken?: string;
  session?: BattleSession;
  createdAt: number;
}

const lobbies = new Map<string, FriendLobby>();
const lobbyCodes = new Map<string, string>();
const INVITE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function newInviteCode(): string {
  for (;;) {
    let code = '';
    for (let i = 0; i < 6; i += 1) {
      code +=
        INVITE_ALPHABET[
          Math.floor(Math.random() * INVITE_ALPHABET.length)
        ] ?? 'A';
    }
    if (!lobbyCodes.has(code)) return code;
  }
}

function tokenFrom(req: Request): string {
  const header = req.get('x-battle-token');
  if (header && header.trim().length > 0) return header.trim();
  return String(req.query.token ?? '').trim();
}

function sideFor(lobby: FriendLobby, token: string): BattleSide | null {
  if (token && token === lobby.hostToken) return 'p1';
  if (token && token === lobby.guestToken) return 'p2';
  return null;
}

function friendError(
  res: Response,
  status: number,
  error: string,
  message: string,
) {
  res.status(status).json({ error, message });
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    engine: 'pokemon-showdown',
    formats: SUPPORTED_FORMATS,
    activeBattles: sessions.size,
  });
});

app.get('/api/formats', (_req, res) => {
  res.json({
    formats: SUPPORTED_FORMATS.map((id) => ({ id, name: formatName(id) })),
  });
});

app.post('/api/battles', async (req, res) => {
  const format = String(req.body?.format ?? 'gen9randombattle');
  if (!isSupportedFormat(format)) {
    res.status(400).json({
      error: 'unsupported_format',
      supported: SUPPORTED_FORMATS,
    });
    return;
  }

  try {
    const session = await BattleSession.create(format);
    sessions.set(session.id, session);
    res.status(201).json(session.snapshot());
  } catch (error) {
    console.error('failed to start battle', error);
    res.status(500).json({ error: 'battle_start_failed' });
  }
});

app.post('/api/friend-battles', (req, res) => {
  const format = String(req.body?.format ?? 'gen9randombattle');
  if (!isSupportedFormat(format)) {
    friendError(res, 400, 'unsupported_format', 'That format is not supported.');
    return;
  }

  const hostName = String(req.body?.name ?? 'Trainer');
  const id = randomUUID();
  const code = newInviteCode();
  const lobby: FriendLobby = {
    id,
    code,
    format,
    hostName,
    hostToken: randomUUID(),
    createdAt: Date.now(),
  };
  lobbies.set(id, lobby);
  lobbyCodes.set(code, id);

  res.status(201).json({
    id,
    code,
    side: 'p1',
    token: lobby.hostToken,
    status: 'waiting',
  });
});

app.post('/api/friend-battles/join', async (req, res) => {
  const code = String(req.body?.code ?? '').trim().toUpperCase();
  const lobbyId = lobbyCodes.get(code);
  const lobby = lobbyId ? lobbies.get(lobbyId) : undefined;
  if (!lobby) {
    friendError(res, 404, 'invite_not_found', 'No battle with that code.');
    return;
  }
  if (lobby.session) {
    friendError(res, 409, 'battle_full', 'That battle already has two players.');
    return;
  }

  const guestName = String(req.body?.name ?? 'Challenger');
  try {
    const session = await BattleSession.create(lobby.format, {
      mode: 'friend',
      p1Name: lobby.hostName,
      p2Name: guestName,
    });
    lobby.guestName = guestName;
    lobby.guestToken = randomUUID();
    lobby.session = session;
    sessions.set(session.id, session);

    // The guest has to wait for their own first request; the host is already
    // polling and will see the session on its next tick.
    await session.ready.p2;

    res.json({
      id: lobby.id,
      side: 'p2',
      token: lobby.guestToken,
      status: 'active',
      snapshot: session.snapshot('p2'),
    });
  } catch (error) {
    console.error('failed to start friend battle', error);
    friendError(res, 500, 'battle_start_failed', 'Could not start the battle.');
  }
});

app.get('/api/friend-battles/:id', (req, res) => {
  const lobby = lobbies.get(req.params.id);
  if (!lobby) {
    friendError(res, 404, 'battle_not_found', 'That battle expired.');
    return;
  }

  const side = sideFor(lobby, tokenFrom(req));
  if (!side) {
    friendError(res, 401, 'invalid_token', 'This device is not in that battle.');
    return;
  }

  if (!lobby.session) {
    res.json({ id: lobby.id, side, status: 'waiting', code: lobby.code });
    return;
  }

  res.json({
    id: lobby.id,
    side,
    status: 'active',
    snapshot: lobby.session.snapshot(side),
  });
});

app.post('/api/friend-battles/:id/choice', async (req, res) => {
  const lobby = lobbies.get(req.params.id);
  const session = lobby?.session;
  if (!lobby || !session) {
    friendError(res, 404, 'battle_not_found', 'That battle expired.');
    return;
  }

  const side = sideFor(lobby, tokenFrom(req));
  if (!side) {
    friendError(res, 401, 'invalid_token', 'This device is not in that battle.');
    return;
  }

  if (session.isOver) {
    res.status(409).json({
      error: 'battle_over',
      snapshot: session.snapshot(side),
    });
    return;
  }

  const choice = String(req.body?.choice ?? '');
  if (!CHOICE_PATTERN.test(choice)) {
    friendError(res, 400, 'invalid_choice', 'That choice is not legal.');
    return;
  }

  const before = session.snapshot(side);
  if (before.forceSwitch && !choice.startsWith('switch')) {
    friendError(res, 400, 'switch_required', 'Choose a replacement.');
    return;
  }
  if (!before.forceSwitch && choice.startsWith('switch') && !before.canAct) {
    friendError(res, 409, 'cannot_act', 'Wait for your turn.');
    return;
  }

  try {
    const snapshot = await session.choose(choice, side);
    res.json({ id: lobby.id, side, status: 'active', snapshot });
  } catch (error) {
    console.error('friend choice failed', error);
    friendError(res, 409, 'choice_failed', 'The battle rejected that choice.');
  }
});

app.get('/api/battles/:id', (req, res) => {
  const session = sessions.get(req.params.id);
  if (!session) {
    res.status(404).json({ error: 'battle_not_found' });
    return;
  }
  res.json(session.snapshot());
});

app.post('/api/battles/:id/choice', async (req, res) => {
  const session = sessions.get(req.params.id);
  if (!session) {
    res.status(404).json({ error: 'battle_not_found' });
    return;
  }
  if (session.isOver) {
    res.status(409).json({ error: 'battle_over', snapshot: session.snapshot() });
    return;
  }

  const choice = String(req.body?.choice ?? '');
  if (!CHOICE_PATTERN.test(choice)) {
    res.status(400).json({ error: 'invalid_choice' });
    return;
  }

  const before = session.snapshot();
  if (before.forceSwitch && !choice.startsWith('switch')) {
    res.status(400).json({ error: 'switch_required' });
    return;
  }
  if (!before.forceSwitch && choice.startsWith('switch') && !before.canAct) {
    res.status(400).json({ error: 'cannot_act' });
    return;
  }

  try {
    const snapshot = await session.choose(choice);
    res.json(snapshot);
  } catch (error) {
    console.error('choice failed', error);
    res.status(409).json({ error: 'choice_failed' });
  }
});

app.use((_req, res) => {
  res.status(404).json({ error: 'not_found' });
});

const cleanup = setInterval(() => {
  const cutoff = Date.now() - SESSION_TTL_MS;
  for (const [id, session] of sessions) {
    if (session.createdAt < cutoff) sessions.delete(id);
  }
  for (const [id, lobby] of lobbies) {
    if (lobby.createdAt < cutoff) {
      lobbies.delete(id);
      lobbyCodes.delete(lobby.code);
    }
  }
}, 5 * 60 * 1000);
cleanup.unref();

// Pterodactyl-based hosts (Wispbyte, etc.) expose the allocated port as
// SERVER_PORT; Render/Fly/others use PORT.
const port = Number(process.env.PORT ?? process.env.SERVER_PORT ?? 8787);
app.listen(port, '0.0.0.0', () => {
  console.log(
    `Pokéventure server on http://0.0.0.0:${port} · ` +
      `formats: ${SUPPORTED_FORMATS.join(', ')}`,
  );
});
