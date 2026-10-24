import assert from 'node:assert/strict';
import test from 'node:test';

import { BattleSession } from '../src/battle/session.js';

test('a random battle starts with a full team and a legal request', async () => {
  const session = await BattleSession.create('gen9randombattle');
  const snapshot = session.snapshot();

  assert.equal(snapshot.player.team.length, 6);
  assert.ok(snapshot.player.active);
  assert.equal(snapshot.canAct, true);
  assert.equal(snapshot.ended, false);
  assert.ok(snapshot.turn <= 1, 'turn counter starts at the first turn');
  assert.ok(snapshot.opponent, 'opponent should be revealed on switch-in');
});

test(
  'a battle can be played to a winner',
  { timeout: 30_000 },
  async () => {
    const session = await BattleSession.create('gen9randombattle');
    let snapshot = session.snapshot();

    for (let step = 0; step < 400 && !snapshot.ended; step += 1) {
      assert.ok(snapshot.canAct, 'battle should request a choice');

      let choice: string;
      if (snapshot.forceSwitch) {
        const member = snapshot.player.team.find(
          (candidate) => !candidate.active && !candidate.fainted,
        );
        assert.ok(member, 'a bench Pokémon should be available to switch');
        choice = `switch ${member.slot}`;
      } else {
        const active = snapshot.player.active;
        assert.ok(active);
        const index = active.moves.findIndex(
          (move) => !move.disabled && move.pp > 0,
        );
        assert.ok(index >= 0, 'active Pokémon should have a usable move');
        choice = `move ${index + 1}`;
      }

      snapshot = await session.choose(choice);
    }

    assert.equal(snapshot.ended, true, 'battle should finish');
    assert.ok(
      snapshot.winner === 'player' || snapshot.winner === 'opponent',
      'a decisive winner is recorded',
    );
    assert.ok(snapshot.log.some((line) => line.startsWith('|win|')));
    assert.ok(snapshot.log.length > 0);
  },
);

test('an unsupported format is rejected', async () => {
  const { isSupportedFormat } = await import('../src/battle/engine.js');
  assert.equal(isSupportedFormat('gen9ou'), false);
  assert.equal(isSupportedFormat('gen9randombattle'), true);
});
