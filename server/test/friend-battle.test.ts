import assert from 'node:assert/strict';
import test from 'node:test';

import {
  BattleSession,
  type BattleSnapshot,
} from '../src/battle/session.js';

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

async function clearForcedSwitch(
  session: BattleSession,
  side: 'p1' | 'p2',
): Promise<void> {
  // A pivot move (Flip Turn, U-turn) asks the same player for a replacement
  // before the turn resolves; submit it so the other side can continue.
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const snapshot = session.snapshot(side);
    if (!snapshot.forceSwitch) return;
    await session.choose(pick(snapshot), side);
  }
}

async function waitForAct(
  session: BattleSession,
  side: 'p1' | 'p2',
): Promise<BattleSnapshot> {
  for (let attempt = 0; attempt < 500; attempt += 1) {
    const snapshot = session.snapshot(side);
    if (snapshot.canAct || snapshot.ended) return snapshot;
    await delay(20);
  }
  throw new Error(`side ${side} never got an actionable request`);
}

function pick(snapshot: BattleSnapshot): string {
  if (snapshot.forceSwitch) {
    const reviving = snapshot.player.active?.reviving ?? false;
    const member = snapshot.player.team.find(
      (candidate) =>
        !candidate.active && (reviving ? candidate.fainted : !candidate.fainted),
    );
    return member ? `switch ${member.slot}` : 'pass';
  }

  const active = snapshot.player.active;
  assert.ok(active, 'active Pokémon should be requested');
  const index = active.moves.findIndex(
    (move) => !move.disabled && move.pp > 0,
  );
  return `move ${index >= 0 ? index + 1 : 1}`;
}

test(
  'two humans play the same battle from opposite sides',
  { timeout: 45_000 },
  async () => {
    const session = await BattleSession.create('gen9randombattle', {
      mode: 'friend',
      p1Name: 'Aria',
      p2Name: 'Kai',
    });
    await session.ready.p2;

    let host = session.snapshot('p1');
    let guest = session.snapshot('p2');

    assert.equal(host.player.name, 'Aria');
    assert.equal(guest.player.name, 'Kai');
    assert.equal(host.player.team.length, 6);
    assert.equal(guest.player.team.length, 6);
    assert.notEqual(
      host.player.team[0]?.species,
      undefined,
      'both sides have a lead',
    );

    for (let step = 0; step < 800 && !host.ended; step += 1) {
      host = session.snapshot('p1');
      guest = session.snapshot('p2');
      if (host.ended) break;

      let acted = false;
      if (host.canAct) {
        await session.choose(pick(host), 'p1');
        acted = true;
      }
      if (guest.canAct) {
        await session.choose(pick(guest), 'p2');
        acted = true;
      }
      if (!acted) await delay(20);
    }

    host = session.snapshot('p1');
    guest = session.snapshot('p2');

    assert.equal(host.ended, true, 'battle should finish');
    assert.equal(guest.ended, true, 'both sides see the end');
    assert.ok(
      (host.winner === 'player' && guest.winner === 'opponent') ||
        (host.winner === 'opponent' && guest.winner === 'player'),
      'the winner is mirrored for the two players',
    );
    assert.ok(host.log.some((line) => line.startsWith('|win|')));
  },
);

test('player names are cleaned and kept distinct', async () => {
  const session = await BattleSession.create('gen9randombattle', {
    mode: 'friend',
    p1Name: '  Aria | ',
    p2Name: 'Aria',
  });
  await session.ready.p2;

  assert.equal(session.snapshot('p1').player.name, 'Aria');
  assert.notEqual(
    session.snapshot('p2').player.name,
    session.snapshot('p1').player.name,
  );
});

test('a waiting snapshot is reported before it is your turn', async () => {
  const session = await BattleSession.create('gen9randombattle', {
    mode: 'friend',
    p1Name: 'Aria',
    p2Name: 'Kai',
  });
  await session.ready.p2;

  // Switching is the one action that can never hand the host a second
  // request before the guest moves (unlike a pivot move such as U-turn).
  const host = session.snapshot('p1');
  const bench = host.player.team.find(
    (candidate) => !candidate.active && !candidate.fainted,
  );
  assert.ok(bench, 'the host has a bench Pokémon');
  await session.choose(`switch ${bench.slot}`, 'p1');

  const waiting = session.snapshot('p1');
  assert.equal(waiting.waiting, true);
  assert.equal(waiting.canAct, false);

  const guest = session.snapshot('p2');
  await session.choose(pick(guest), 'p2');
  await clearForcedSwitch(session, 'p2');
  const resumed = await waitForAct(session, 'p1');
  assert.equal(resumed.waiting, false);
  assert.ok(
    resumed.canAct || resumed.ended,
    'the host is actionable again or the battle is over',
  );
});
